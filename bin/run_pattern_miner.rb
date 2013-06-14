require 'pattern_miner.rb'
require 'vsop_utils.rb'

include VSOPUtils

databases =
  [
   ['134'],
   ['12'],
   ['12', '234'],
   ['234'],
   ['1','23','34','5'],
  ]

puts "symbol v1 v2 v3 v4 v5"

pm = PatternMiner.new('L*HHL*')

databases.each_index do |i|
  mfi = databases[i]
  d = mfi.map{|e| all_combination(e)}.flatten.to_set

  puts "D#{i} = #{to_vsop(d)}"
  pm.accept_itemsets("D#{i}")
end
pm.found_sets
