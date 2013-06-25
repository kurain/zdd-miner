require 'pattern_miner.rb'
require 'vsop_utils.rb'

include VSOPUtils

pattern = ARGV[0] || 'HL*'

pm = PatternMiner.new(pattern, :debug => false, :lcm => "M")

files = []
(2008..2011).each do |year|
  files.push "nico_data/#{year}.txt_fimi.txt"
end

warn files.inspect
pm.read_lookup_file('nico_data/2007.txt_lookup.txt')

ratio = 0.0002
files.each do |file|
  zdd = pm.frequent_itemsets(file, ratio, 'nico_data/2007.txt_order.txt')
  pm.accept_itemsets(zdd)
end
puts pm.symbol_to_name(pm.found_sets.to_s)
warn 'final count: ' + pm.found_sets.count
