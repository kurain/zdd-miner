require 'pattern_miner.rb'
require 'vsop_utils.rb'

include VSOPUtils

pm = PatternMiner.new('HH*', :debug => false)

files = []
5.times do |i|
  files.push "00#{i+1}_tags.txt_fimi.txt"
end

warn files.inspect

ratio = 0.001
files.each do |file|
  pm.accept_itemsets(pm.frequent_itemsets(file,ratio, '001_tags.txt_order.txt'))
end
pm.found_sets
