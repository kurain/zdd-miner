# -*- encoding: utf-8 -*-
require 'news_analyzer'
require 'burst_miner'
require 'date'
require 'tempfile'

@data_dir = ARGV[0]

unless @data_dir || !Dir.new(@data_dir).exist?
  warn "usage: #{File.basename(__FILE__)} <data_dir>"
  exit(1)
end

@host = 'localhost' #'192.168.11.52'
# PASS1 create lookup
def create_lookup(start_dt, end_dt, tagger)
  db = NewsAnalyzer::News.new("dbi:Mysql:newsplus:#{@host}")
  counter = {}
  tweets = db.get_tweets(start_dt, end_dt)
  tweets.each do |row|
    t = row["title"].force_encoding(Encoding::UTF_8)
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
  printf $stdout, "words: %d\n", counter.size
  return lookup
end

#PASS 2 create fimi file
def create_fimi(start_dt, end_dt, tagger, lookup, interval=1)
  current_start = start_dt
  db = NewsAnalyzer::News.new("dbi:Mysql:newsplus:#{@host}")

  files = []
  while current_start < end_dt
    file = File.new(@data_dir + '/' + current_start.iso8601, 'w')
    warn file.path

    tweets = db.get_tweets(current_start, current_start + interval)
    printf($stderr, "read %s to %s (%d)\n", current_start.iso8601, end_dt.iso8601, tweets.size)

    words = docs = 0
    tweets.each do |row|
      t = row["title"].force_encoding(Encoding::UTF_8)
      ids = tagger.hatena_keyword(t).map{|keyword|
        lookup[keyword]
      }.select{|e| e}
      next if ids.empty?
      file.puts(ids.sort.join(' '))
      words += ids.size
      docs  += 1
    end
    file.close

    printf $stderr, "total_words: %d total_docs: %d average_words %f\n", words, docs, words.to_f / docs
    files.push(file)
    current_start += interval
  end
  return files
end


start_dt  = DateTime.new(2012,1,1)
end_dt    = DateTime.new(2013,1,1)

dic = File.dirname(__FILE__) + '/../data/hatena-keyword.dic'
tagger = NewsAnalyzer::Tagger.new(dic)


lookup_file_path = @data_dir + '/' + 'lookup'
order_file_path  = @data_dir + '/' + 'order'
lookup_file = File.exist?(lookup_file_path) ? File.new(lookup_file_path) : nil
order_file  = File.exist?(order_file_path)  ? File.new(order_file_path)  : nil

lookup = {}
if !lookup_file || !order_file
  lookup_file = File.new(lookup_file_path, 'w')
  order_file  = File.new(order_file_path, 'w')

  lookup      = create_lookup(start_dt, end_dt, tagger)
  lookup.each do |key,val|
    lookup_file.puts([key,val].join(' '))
  end
  lookup_file.close

  order_file.puts(('0'..lookup.size.to_s).map{|e| e}.join(' '))
  order_file.close
else
  lookup_file.each_line do |line|
    key, val = line.split(' ')
    lookup[key] = val
  end
end

fimi_files = Dir.glob(@data_dir + '/' + '2*' ).sort.map{|path| File.new(path)}
if fimi_files.empty?
  fimi_files  = create_fimi(start_dt, end_dt, tagger, lookup)
end
p fimi_files.map{|f| f.path}

bm = BurstMiner.new(:debug => false)
bm.read_lookup_file(lookup_file.path)

ratio = 0
daily_data = []
fimi_files.each do |file|
  daily_data <<  bm.frequent_itemsets(file.path, ratio, order_file.path, :minimum_support => 1)
end

d_all = daily_data.inject(0){|sum,e| sum + e[:count]}

s = 2
(0...daily_data.length).each do |i|
  bm.find_burst(daily_data, i, s, d_all)
end
