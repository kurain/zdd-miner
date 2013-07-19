require 'tempfile'
require 'zdd'
require 'inline'

class BurstMiner
  attr_reader :lookup, :total_itemset_count

  def initialize(opt={})
    @total_itemset_count = 0
    @itemsets_num = 0
    @debug = opt[:debug] ? true : false
  end

private
  def read_fimi_file(filename)
    line_count = 0
    lookup = {}
    File.open(filename).each_line do |line|
      line.chomp.split(/\s+/).each do |symbol|
        lookup[symbol] ||= true
      end
      line_count+=1
    end
    order = lookup.keys.sort
    return line_count, order
  end

public
  def read_lookup_file(filename)
    @lookup = {}
    File.open(filename) do |io|
      io.each_line do |line|
        word, number, count = line.chomp.split(' ')
        @lookup['x' + number] = word
      end
    end
  end

  def family_to_zdd(family)
    zdds = []
    family.each do |hash|
      itemset = hash[:itemsets]
      zdd = ZDD.constant(1)
      itemsets.each do |items|
        zdd = zdd + ZDD.itemset(items.join(' '))
      end
      zdds << {:zdd => zdd, :count => hash[:count]}
    end
    return zdds
  end

  def frequent_itemsets(filename, ratio, order_file_path = nil, opt={})
    line_count, order = read_fimi_file(filename)
    @itemsets_num+=1
    order_file = order_file_path ? File.open(order_file_path, 'r') : nil

    minimum_support = ratio == 0 ? opt[:minimum_support] : (line_count * ratio).floor
    warn 'minimum support: ' + minimum_support.to_s
    zdd = ZDD.lcm('FQ', filename,  minimum_support, order_file.path)

    warn "read #{filename} #{zdd.count.to_s} (#{zdd.size} / #{zdd.totalsize})"
    @total_itemset_count += zdd.count.to_i
    warn "#{symbol_to_name(zdd.to_s)}" if @debug
    return {:zdd => zdd, :count => line_count}
  end

  def symbol_to_name(str)
    str.gsub(/(x\d+)/) { @lookup[$1] }.gsub(' + ', "\n")
  end

  inline do |builder|
    builder.include('<math.h>')
    builder.c <<-EOF
      double
      burst_score_c(int d, int r, int s, int rt, int dt)
      {
        double p = (double) r / d;
        return rt * log((double)s) + (dt - rt) * log((double)(1 - p * s)) - (dt - rt) * log (1 - p);
      }
    EOF
  end

  def burst_score(d, r, s, rt, dt)
    p_0 = r.to_f / d
    #  score = Math.log((s**rt) * ((1 - p_0 * s)) ** (dt - rt)) - Math.log((1 - p_0) ** (dt - rt))
    score = rt * Math.log(s) + (dt - rt) * Math.log(1 - p_0 * s) - (dt - rt) * Math.log(1 - p_0)
    return score.nan? ? 0 : score
  end

  def all_period_count(data_set, itemset)
    zdd = ZDD.itemset(itemset)
    count = 0
    data_set.each do |data|
      periodzdd = data[:zdd]
      count += zdd.iif(periodzdd,0).maxval.to_i
    end
    count
  end

  def find_burst(data_set, doc_index, s, d_all, zdd_all=nil)
    scored = []
    doc_count = data_set[doc_index][:count]

    warn 'challenge: ' + data_set[doc_index][:zdd].count
    item_pos = 0
    itemsets = data_set[doc_index][:zdd].to_s.split('+').map do |item|
      col =  item.strip.split(/\s+/)
      count = 1
      if col[0][0] != 'x'
        count = col.shift.to_i
      end
      next if col.empty?
      itemset = col.join(" ")
      if zdd_all
        r = ZDD.itemset(itemset.clone).iif(zdd_all,0).maxval.to_i
      else
        r = all_period_count(data_set, itemset.clone)
      end
      scored << {:itemset => itemset, :score => burst_score_c(d_all, r, s, count, doc_count)}
      $stderr.print( sprintf("% 7d", item_pos) + "\r")
      item_pos += 1
    end

    printf "===Document Index #{doc_index}===\n"
    scored.sort{|a, b| b[:score] <=> a[:score]}[0..10].each do |e|
      itemset  = e[:itemset]
      score    = e[:score]
      printf " %s: %s(%s)\n", score, self.symbol_to_name(itemset), itemset
    end
  end
end
