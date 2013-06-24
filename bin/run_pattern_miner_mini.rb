require 'set'
require 'pattern_miner.rb'

(1..5).each do |i|
  ZDD.symbol('x' + i.to_s)
end

databases =
  [
   ['134'],
   ['12'],
   ['12', '234'],
   ['234'],
   ['1','23','34','5'],
  ]

def all_combination(str)
  arr = str.split('')
  res = []
  (1..arr.length).each do |i|
    res += arr.combination(i).map{|e| e.join }.to_a
  end
  return res
end

def to_vsop(family)
  zdds = family.to_a.map do |set|
    ZDD.itemset(set.split('').map{|i| "x#{i}" }.join(" "))
  end
  zdds.inject{|result, itemset| result + itemset}
end

pm = PatternMiner.new('L*H*', :debug => false)
databases.each{|mfi|
  d = mfi.map{|e| all_combination(e)}.flatten.to_set
  zdd = to_vsop(d)
  puts "========= now: " + zdd.to_s
  pm.accept_itemsets(zdd)
}
puts pm.found_sets.to_s
