require 'burst_miner.rb'
require 'vsop_utils.rb'
STDOUT.sync = true
include VSOPUtils

bm = BurstMiner.new(:debug => false)

files = []
dir = 'nico_month'
files = Dir.glob(dir + '/*fimi.txt').sort

warn "We will read #{files.length} files"

order_file_path  = Dir.glob(dir + '/*_order.txt')[0]
lookup_file_path = Dir.glob(dir + '/*lookup.txt')[0]

warn order_file_path
warn lookup_file_path

bm.read_lookup_file(lookup_file_path)

ratio = 0
monthly_data = []
files.each do |file|
  monthly_data <<  bm.frequent_itemsets(file, ratio, order_file_path,:minimum_support => 1)
end

d_all = monthly_data.inject(0){|sum,e| sum + e[:count]}
warn 'Document TOTAL: ' + d_all
zdd_all = ZDD.constant(1)
monthly_data.each do |e|
  zdd_all = zdd_all + e[:zdd]
  warn "ALL_ZDD: #{zdd_all.count} itemset (#{zdd_all.size} / #{zdd_all.totalsize})"
end

s = 2
(0...monthly_data.length).each do |i|
  bm.find_burst(monthly_data, i, s, d_all, zdd_all)
end
