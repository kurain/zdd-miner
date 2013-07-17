# -*- encoding: utf-8 -*-
require 'tweet_analyzer'
require 'burst_miner'
require 'date'

STDOUT.sync = true


# PASS1 create lookup
def create_lookup(start_dt, end_dt, tagger)
  db = TweetAnalyzer::Tweets.new("dbi:Mysql:tweets:192.168.11.52")
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
    lookup[pair[0]] = 'x' + id.to_s
    id += 1
  }
  return lookup
end

#PASS 2 create fimi file
def create_family(start_dt, end_dt, tagger, lookup, n = 3, interval=Rational(1,24))
  current_start = start_dt
  db = TweetAnalyzer::Tweets.new("dbi:Mysql:tweets:192.168.11.52")

  family = []
  while current_start < end_dt
    itemsets = []
    tweets = db.get_tweets(current_start, end_dt)
    warn sprintf("read %s (%d)",current_start.iso8601,tweets.size)

    item_pos = 0
    tweets.each do |row|
      $stderr.print( sprintf("% 7d", item_pos+=1) + "\r")

      t = row["text"].force_encoding(Encoding::UTF_8)
      ids = tagger.hatena_keyword(t).map{|keyword|
        lookup[keyword]
      }.select{|e| e}
      next if ids.empty?
      itemsets += ids.sort.combination(n).to_a
    end
    family << {:itemsets => itemsets, :count => tweets.size}
    current_start += interval
  end
  return family
end

now = DateTime.now
end_dt    = DateTime.new(now.year,now.month,now.day,now.hour,0)
start_dt  = end_dt - Rational(1, 24)

dic = File.dirname(__FILE__) + '/../data/hatena-keyword.dic'
tagger = TweetAnalyzer::Tagger.new(dic)


lookup  = create_lookup(start_dt, end_dt, tagger)
family  = create_family(start_dt, end_dt, tagger, lookup)

bm = BurstMiner.new(:debug => false)
bm.lookup = lookup

hourly_data = bm.family_to_zdd(family)

d_all = hourly_data.inject(0){|sum,e| sum + e[:count]}
zdd_all = ZDD.constant(1)
hourly_data.each do |e|
  zdd_all = zdd_all + e[:zdd]
end

s = 2
(0...hourly_data.length).each do |i|
  bm.find_burst(hourly_data, i, s, d_all, zdd_all)
end
