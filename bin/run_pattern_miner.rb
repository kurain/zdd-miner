require 'pattern_miner.rb'
require 'vsop_utils.rb'

include VSOPUtils

pm = PatternMiner.new('LHL*', :debug => false)

files = []
(1..11).each do |i|
  month = sprintf "%02d", i
  files.push "date_tags_sorted.txt_2012_#{month}_fimi.txt"
end

warn files.inspect
pm.read_lookup_file('date_tags_sorted.txt_2012_01_lookup.txt')

ratio = 0.005
files.each do |file|
  pm.accept_itemsets(pm.frequent_itemsets(file, ratio, 'date_tags_sorted.txt_2012_01_order.txt'))
end
p pm.symbol_to_name(pm.found_sets.to_s)
