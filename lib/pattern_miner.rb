require 'regexp_nfa.tab.rb'
require 'nfa.rb'
require 'tempfile'
require 'zdd'

class PatternMiner
  attr_reader :states

  def set_minus_node(node,checked={})
    return if checked[node]
    checked[node] = true
    node.nodes_by_epsilon_rules.each do |node|
      node.minus_node = true
      node.nodes_by_lower_rules.each do |lnode|
        lnode.minus_node = true
        set_minus_node(lnode,checked)
      end
    end
  end

  def initialize(pattern, opt)
    @regex_parser = RegexpSimple.new
    @nfa    = @regex_parser.parse(pattern).to_nfa

    @nfa.nodes_by_epsilon_rules.each do |node|
      node.start = true
    end
    set_minus_node(@nfa)

    @states = @nfa.to_a
    @itemsets_num = 0

    @debug = opt[:debug] ? true : false
    @lcm_opt = opt[:lcm] ? opt[:lcm]  : "F"

    @states.each do |node|
      node.set = ZDD.constant(0)
    end
  end

private
  def do_epsilon(state)
    state.nodes_by_epsilon_rules.each do |next_state|
      next_state.set = next_state.set + state.set
      next_state.set = (next_state.set > 0) - (next_state.set < 0)
    end
  end

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

  def frequent_itemsets(filename, minimum_support_ratio, order_file_path = nil)
    line_count, order = read_fimi_file(filename)
    @itemsets_num+=1

    order_file = order_file_path ? File.open(order_file_path, 'r') : nil
    unless order_file
      order_file = File.open('_order_' + vsop_value, 'w')
      order_file.puts order.join(" ")
      order_file.close
    end
    minimum_support = (line_count * minimum_support_ratio).floor
    zdd = ZDD.lcm(@lcm_opt, filename,  minimum_support, order_file.path)
    warn "read #{filename} #{zdd.count.to_s}"
    warn "#{symbol_to_name(zdd.to_s)}" if @debug
    return zdd
  end

  def accept_itemsets(zdd)
    @states.reverse.each do |state|
      if state.rules.empty?
        state.set = ZDD.constant(0)

      elsif state.minus_node
        state.rules.each do |rule|
          case rule.accept
          when 'H'
            rule.next.set = rule.next.set + ((state.set + zdd) > 0)
            rule.next.set = (rule.next.set > 0) - (rule.next.set < 0)
            state.set = ZDD.constant(0)

            do_epsilon(rule.next)
          when 'L'
            rule.next.set = rule.next.set - ((state.set - zdd) < 0)
            rule.next.set = (rule.next.set > 0) - (rule.next.set < 0)
            state.set = ZDD.constant(0)

            do_epsilon(rule.next)

          when :e
            state.set = ZDD.constant(0)

          end
        end

      else
        state.rules.each do |rule|
          case rule.accept
          when 'H'
            rule.next.set = rule.next.set + (state.set == zdd)
            rule.next.set = (rule.next.set > 0) - (rule.next.set < 0)

            state.set = ZDD.constant(0)
            do_epsilon(rule.next)

          when 'L'
            rule.next.set = rule.next.set + ((state.set -  zdd) > 0)
            rule.next.set = (rule.next.set > 0) - (rule.next.set < 0)

            state.set = ZDD.constant(0)
            do_epsilon(rule.next)

          when :e
            state.set = ZDD.constant(0)

          end
        end
      end
      if @debug
        puts "current state #{state.name}"
        self.dump()
      end
    end
  end

  def found_sets
    final = @states.find{|node| node.final == true}
    final.set
  end

  def symbol_to_name(str)
    str.gsub(/(x\d+)/) { @lookup[$1] }.gsub(' + ', "\n")
  end

  def dump
    @states.each_index do |i|
#      puts "  q#{i}: " + symbol_to_name(@states[i].set.to_s)
      puts "  q#{i}: " + @states[i].set.to_s
#      puts "  q#{i}: " + @states[i].set.count.to_s
    end
  end
end
