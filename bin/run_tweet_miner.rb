require 'tweet_analyzer'
require 'date'
require 'tempfile'


# PASS1 create lookup
def create_lookup(start_dt, end_dt, tagger)
  db = TweetAnalyzer::Tweets.new("dbi:Mysql:tweets:192.168.11.52")
  counter = {}
  tweets = db.get_tweets(start_dt, end_dt)
  tweets.each do |text|
    t = text.force_encoding(Encoding::UTF_8)
    tagger.hatena_keyword(t).each do |word|
      counter[word] ||= 0
      counter[word] += 1
    end
  end
  lookup = {}
  id = 1
  counter.to_a.sort{|a,b|
    b[1] <=> a[1]
  }[0...50_000].each{|pair|
    lookup[pair[0]] = id
    id += 1
  }
#  warn "words: " + counter.size
  return lookup
end

#PASS 2 create fimi file
def create_fimi(start_dt, end_dt, tagger, lookup, interval=Rational(1,24))
  current_start = start_dt
  db = TweetAnalyzer::Tweets.new("dbi:Mysql:tweets:192.168.11.52")

  files = []
  while current_start < end_dt
    file = Tempfile.new(current_start.iso8601)

    tweets = db.get_tweets(current_start, end_dt)
    warn "read " + current_start.iso8601

    tweets.each do |text|
      t = text.force_encoding(Encoding::UTF_8)
      ids = tagger.hatena_keyword(t).map{|keyword|
        lookup[keyword]
      }.select{|e| e}
      file.puts(ids.sort.join(' '))
    end
    file.close

    files.push(file)
    current_start += interval
  end
  return files
end

now = DateTime.now
end_dt    = DateTime.new(now.year,now.month,now.day,now.hour,0)
start_dt  = end_dt - Rational(3 , 24)

dic = File.dirname(__FILE__) + '/../data/hatena-keyword.dic'
tagger = TweetAnalyzer::Tagger.new(dic)


lookup      = create_lookup(start_dt, end_dt, tagger)
lookup_file = Tempfile.new('lookup')
lookup.each do |key,val|
  lookup_file.puts([key,val].join(' '))
end
lookup_file.close

order_file = Tempfile.new('order')
order_file.puts ('0'..lookup.size.to_s).map{|e| e}.join(' ')
order_file.close

fimi_files  = create_fimi(start_dt, end_dt, tagger, lookup)

p fimi_files.map{|f| f.path}

pm = PatternMiner.new('L*HL*', :debug => false)
pm.read_lookup_file(lookup_file.path)

hourly_data = []
ratio = 0.002
fimi_files.each do |file|
  hourly_data <<  pm.frequent_itemsets(file.path, ratio, order_file.path)
end

while true
  puts
  print '? '
  pattern = gets.chop!
  pm.set_pattern(pattern)

  hourly_data.each do |zdd|
    pm.accept_itemsets(zdd)
  end
  pm.found_sets.show
  puts pm.symbol_to_name(pm.found_sets.to_s)
  warn 'final count: ' + pm.found_sets.count
end
