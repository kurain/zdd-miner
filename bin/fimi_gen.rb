total  = ARGV.shift.to_i
ratios = ARGV.map{|s| s.to_f}

total.times do
  res = []
  ratios.each_index do |i|
    res.push(i+1) if rand() <= ratios[i]
  end
  puts res.join(' ') unless res.empty?
end
