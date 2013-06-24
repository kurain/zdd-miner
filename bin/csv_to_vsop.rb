require 'csv'

prefix =
  ['act', 'resource', 'id', 'rollup1', 'rollup2', 'dept', 'title', 'family_desc', 'family', 'code']

columns = prefix.map{ {} }
symbols = {}
first = true
CSV.open(ARGV[0]).each do |row|
  if first
    first = false
    next
  end
  row.each_index do |i|
    columns[i][row[i]] ||= 0
    columns[i][row[i]] += 1

    symbols[prefix[i] + '_' + row[i]] ||= 0
    symbols[prefix[i] + '_' + row[i]] += 1
  end
end
#columns.map{|e| e.keys.length}
#symbols.keys.length

sorted_symbols = symbols.to_a.sort{|a,b| b[1] <=> a[1]}.map{|e| e[0]}
puts "symbol " + sorted_symbols.join(' ')
puts 'Q = 0'
first = true
CSV.open(ARGV[0]).each do |row|
  if first
    first = false
    next
  end

  print 'Q = Q + '
  res = []
  row.each_index do |i|
    res.push(prefix[i] + '_' + row[i])
  end
  puts res.join(' ')
end
puts '? Q.MaxVal'
puts '? /count Q'
puts '? /size Q'
