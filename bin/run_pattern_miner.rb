require 'pattern_miner.rb'
require 'vsop_utils.rb'

include VSOPUtils

pm = PatternMiner.new('LH', :debug => true)

files = %w!fimi_1.txt fimi_2.txt!
ratio = 0.3

files.each do |file|
  pm.accept_itemsets(pm.frequent_itemsets(file,ratio))
end
pm.found_sets
