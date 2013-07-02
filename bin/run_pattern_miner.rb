require 'pattern_miner.rb'
require 'vsop_utils.rb'

include VSOPUtils

pattern = ARGV[0] || 'L*HL{11}L*'

pm = PatternMiner.new(pattern, :debug => false)

files = []
dir = 'nico_month'
files = Dir.glob(dir + '/*fimi.txt')

warn "We will read #{files.length} files"

order_file_path  = Dir.glob(dir + '/*_order.txt')[0]
lookup_file_path = Dir.glob(dir + '/*lookup.txt')[0]

warn order_file_path
warn lookup_file_path

pm.read_lookup_file(lookup_file_path)

ratio = 0.0002
monthly_data = []
files.each do |file|
  monthly_data <<  pm.frequent_itemsets(file, ratio, order_file_path)
end
monthly_data.each do |zdd|
  pm.accept_itemsets(zdd)
end

puts pm.symbol_to_name(pm.found_sets.to_s)
warn 'final count: ' + pm.found_sets.count
