require 'regexp_nfa.tab.rb'
require 'nfa.rb'
require 'set'

parser = RegexpSimple.new

debug = false

ast = parser.parse('L*HHL*')
nfa = ast.to_nfa
nfa.nodes_by_epsilon_rules.each do |node|
  node.start = true
end

nodes = nfa.to_a
nodes.each do |node|
  node.set = Set.new
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

def vsop_dump(states)
  puts "? \"------------------------\""
  states.each do |state|
    puts "? \"#{state.name}\""
    puts "? #{state.name}"
  end
  puts "? \"------------------------\""
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

def do_epsilon(state)
  state.nodes_by_epsilon_rules.each do |next_state|
    puts "#{next_state.name} = #{next_state.name} + #{state.name}"
    puts "#{next_state.name} = (#{next_state.name} > 0) - (#{next_state.name} < 0)"
  end
end


start = nodes[0]
start.nodes_by_epsilon_rules
start.nodes_by_epsilon_rules.each do |state|
  state.set = state.set + start.set.dup
end

puts "symbol v1 v2 v3 v4 v5"
nodes.each do |node|
  puts "#{node.name} = 0"
end
# END initialize

databases.each_index do |i| #maximal frequent itemset
  mfi = databases[i]
  d = mfi.map{|e| all_combination(e)}.flatten.to_set
  puts "? \"------ D#{i} Cycle\"" if debug

  puts "D#{i} = #{to_vsop(d)}"
  nodes.reverse.each do |state|
    puts "?\"Current State #{state.name}\"" if debug
    if state.rules.empty?
      puts "#{state.name} = 0"

    elsif state.start
      state.rules.each do |rule|
        case rule.accept
        when 'H'
          puts "#{rule.next.name} = #{rule.next.name} + ((#{state.name} + D#{i}) > 0)"
          puts "#{rule.next.name} = (#{rule.next.name} > 0) - (#{rule.next.name} < 0)"

          puts "#{state.name} = 0"
          do_epsilon(rule.next)

        when 'L'
          puts "#{rule.next.name} = #{rule.next.name} - ((#{state.name} - D#{i}) < 0)"
          puts "#{rule.next.name} = (#{rule.next.name} > 0) - (#{rule.next.name} < 0)"

          puts "#{state.name} = 0"
          do_epsilon(rule.next)

        when :e
          puts "#{state.name} = 0"
        end
      end

    else
      state.rules.each do |rule|
        case rule.accept
        when 'H'
          puts "#{rule.next.name} = #{rule.next.name} + (#{state.name} == D#{i})"
          puts "#{rule.next.name} = (#{rule.next.name} > 0) - (#{rule.next.name} < 0)"

          puts "#{state.name} = 0"
          do_epsilon(rule.next)

        when 'L'
          puts "#{rule.next.name} = #{rule.next.name} + ((#{state.name} - D#{i}) > 0)"
          puts "#{rule.next.name} = (#{rule.next.name} > 0) - (#{rule.next.name} < 0)"

          puts "#{state.name} = 0"
          do_epsilon(rule.next)

        when :e
          puts "#{state.name} = 0"
        end
      end
    end
    vsop_dump nodes if debug
  end
end

final = nodes.find{|node| node.final == true}
puts "? #{final.name}"

