require 'set'
require 'pp'

q0 = {:name => 'q0', :set => Set.new}
q1 = {:name => 'q1', :set => Set.new}
q2 = {:name => 'q2',:set => Set.new}

q0[:H] = q1
q0[:L] = q0

q1[:H] = q2

q2[:L] = q2

q = [q0, q1, q2]

q0[:set] +=
  ['1','2','3','4','5', '12', '13', '14', '23', '24', '34', '134', '234'].to_set

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

def dumpq(states)
  puts "--------"
  states.each_index do |i|
    puts "q#{i}"
    p states[i][:set]
  end
end


databases.each do |mfi| #maximal frequent itemset
  d = mfi.map{|e| all_combination(e)}.flatten.to_set
  q.reverse.each do |state|
    current = state[:set].dup
    state[:set] = Set.new
    if state[:H]
      state[:H][:set] += current & d
      puts "#{state[:H][:name]} = #{state[:H][:name]} & {#{d.to_a.join ', ' }}"
    end
    if state[:L]
      state[:L][:set] += current - d
      puts "#{state[:L][:name]} = #{state[:L][:name]} \\ {#{d.to_a.join ', '}}"
    end
  end
end
dumpq q
