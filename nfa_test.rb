require 'regexp_nfa.tab.rb'
require 'nfa.rb'
require 'set'

parser = RegexpSimple.new

ast = parser.parse('L*HHL*')
nfa = ast.to_nfa

nodes = nfa.to_a
nodes.each do |node|
  node.set = Set.new
end

nodes[0].set =  ['1','2','3','4','5', '12', '13', '14', '23', '24', '34', '134', '234'].to_set

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

def vsop_dump(states)
  puts "? \"------------------------\""
  states.each do |state|
    puts "? \"#{state.name}\""
    puts "? #{state.name}"
  end
end

def dumpq(states)
  warn "--------"
  states.each do |state|
    warn "q-#{state.name}"
    warn state.set.inspect
  end
end

def to_vsop(family)
  family.to_a.map{|set|
    set.split('').map{|i| "v#{i}" }.join(' ')
  }.join(' + ')
end


start = nodes[0]
start.nodes_by_epsilon_rules
start.nodes_by_epsilon_rules.each do |state|
  state.set = state.set + start.set.dup
end

puts "symbol v1 v2 v3 v4 v5"
nodes.each do |node|
  puts "#{node.name} = #{node.set.empty? ? 0 : to_vsop(node.set) }"
end

databases.each_index do |i| #maximal frequent itemset
  mfi = databases[i]
  d = mfi.map{|e| all_combination(e)}.flatten.to_set

  puts "D#{i} = #{to_vsop(d)}"
  nodes.reverse.each do |state|
    current = state.set.dup
    state.rules.each do |rule|
      case rule.accept
        when 'H'
        rule.next.set = rule.next.set + (current & d)
        puts "#{rule.next.name} = #{rule.next.name} + (#{state.name} == D#{i})"
        puts "#{rule.next.name} = (#{rule.next.name} > 0)"
        when 'L'
        rule.next.set = rule.next.set + (current - d)
        puts "#{rule.next.name} = #{rule.next.name} + ((#{state.name} - D#{i}) > 0)"
        puts "#{rule.next.name} = (#{rule.next.name} > 0)"
      end
    end
    puts "#{state.name} = 0"
    state.set = Set.new
  end
  nodes.reverse.each do |state|
    state.nodes_by_epsilon_rules.each do |next_state|
      next_state.set = next_state.set + state.set
      puts "#{next_state.name} = #{next_state.name} + #{state.name}"
      puts "#{next_state.name} = (#{next_state.name} > 0)"
    end
  end
end

final = nodes.find{|node| node.final == true}
puts "? #{final.name}"

