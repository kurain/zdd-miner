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

def dumpq(states)
  puts "--------"
  states.each do |state|
    puts "q-#{state.name}"
    p state.set
  end
end

start = nodes[0]
start.nodes_by_epsilon_rules
start.nodes_by_epsilon_rules.each do |state|
  state.set = state.set + start.set.dup
end
dumpq nodes

databases.each do |mfi| #maximal frequent itemset
  d = mfi.map{|e| all_combination(e)}.flatten.to_set
  nodes.reverse.each do |state|
    current = state.set.dup
    state.set = Set.new
    state.rules.each do |rule|
      case rule.accept
        when 'H'
        rule.next.set = rule.next.set + (current & d)
#        puts "#{rule.next.name} = #{rule.next.name} & {#{d.to_a.join ', ' }}"
        when 'L'
        rule.next.set = rule.next.set + (current - d)
#        puts "#{rule.next.name} = #{rule.next.name} \\ {#{d.to_a.join ', '}}"
      end
    end
  end
  dumpq nodes
  nodes.reverse.each do |state|
    state.nodes_by_epsilon_rules.each do |next_state|
      next_state.set = next_state.set + state.set
    end
  end
  dumpq nodes
  puts '>' while gets !~ /\n/
end
dumpq nodes
