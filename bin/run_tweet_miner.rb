# -*- encoding: utf-8 -*-
require 'tweet_analyzer'
require 'burst_miner'
require 'date'
require 'tempfile'

# PASS1 create lookup
@host = '192.168.11.35'
def create_lookup(start_dt, end_dt, tagger)
  db = TweetAnalyzer::Tweets.new("dbi:Mysql:tweets:#{@host}")
  counter = {}
  tweets = db.get_tweets(start_dt, end_dt)
  tweets.each do |row|
    t = row["text"].force_encoding(Encoding::UTF_8)
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
  db = TweetAnalyzer::Tweets.new("dbi:Mysql:tweets:#{@host}")

  files = []
  while current_start < end_dt
    file = Tempfile.new(current_start.iso8601)

    tweets = db.get_tweets(current_start, current_start+interval)
    warn sprintf("read %s (%d)",current_start.iso8601,tweets.size)

    tweets.each do |row|
      t = row["text"].force_encoding(Encoding::UTF_8)
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
start_dt  = end_dt - Rational(12, 24)

dic = File.dirname(__FILE__) + '/../data/hatena-keyword.dic'
tagger = TweetAnalyzer::Tagger.new(dic)


lookup      = create_lookup(start_dt, end_dt, tagger)
lookup_file = Tempfile.new('lookup')
lookup.each do |key,val|
  lookup_file.puts([key,val].join(' '))
end
lookup_file.close

order_file = Tempfile.new('order')
order_file.puts(('0'..lookup.size.to_s).map{|e| e}.join(' '))
order_file.close

fimi_files  = create_fimi(start_dt, end_dt, tagger, lookup)
p fimi_files.map{|f| f.path}

bm = BurstMiner.new(:debug => false)
bm.read_lookup_file(lookup_file.path)

ratio = 0.002
hourly_data = []
fimi_files.each do |file|
  hourly_data <<  bm.frequent_itemsets(file.path, ratio, order_file.path, :minimum_support => 1)
end

d_all = hourly_data.inject(0){|sum,e| sum + e[:count]}
zdd_all = ZDD.constant(1)
hourly_data.each do |e|
  zdd_all = zdd_all + e[:zdd]
end

s = 2
(0...hourly_data.length).each do |i|
  bm.find_burst(hourly_data, i, s, d_all, zdd_all)
end
