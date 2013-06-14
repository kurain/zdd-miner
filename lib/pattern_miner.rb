require 'regexp_nfa.tab.rb'
require 'nfa.rb'
require 'tempfile'

class PatternMiner
  def initialize(pattern)
    @regex_parser = RegexpSimple.new
    @nfa    = @regex_parser.parse(pattern).to_nfa
    @nfa.nodes_by_epsilon_rules.each do |node|
      node.start = true
    end

    @states = @nfa.to_a
    @itemsets_num = 0
    @first_accept = true

    @debug = false

    @states.each do |node|
      puts "#{node.name} = 0"
    end
  end

private
  def do_epsilon(state)
    state.nodes_by_epsilon_rules.each do |next_state|
      puts "#{next_state.name} = #{next_state.name} + #{state.name}"
      puts "#{next_state.name} = (#{next_state.name} > 0) - (#{next_state.name} < 0)"
    end
  end

public
  def frequent_itemsets(filename, order_file, minimum_support_ratio)
    line_count = 0
    File.open(filename).each_line{|line| line_count+=1}
    minimum_support = (line_count * minimum_support_ratio).floor

    vsop_value = "D#{@itemsets_num}"
    puts %Q!#{vsop_value} = Lcm("F" "#{filename}" "#{minimum_support}", "#{order_file}")!
    @itemsets_num+=1
    return vsop_value
  end

  def accept_itemsets(vsop_value)
    puts "? \"------ #{vsop_value} Cycle\"" if @debug
    @states.reverse.each do |state|
      puts "?\"Current State #{state.name}\"" if @debug
      if state.rules.empty?
        puts "#{state.name} = 0"

      elsif state.start
        state.rules.each do |rule|
          case rule.accept
          when 'H'
            puts "#{rule.next.name} = #{rule.next.name} + ((#{state.name} + #{vsop_value}) > 0)"
            puts "#{rule.next.name} = (#{rule.next.name} > 0) - (#{rule.next.name} < 0)"

            puts "#{state.name} = 0"
            do_epsilon(rule.next)

          when 'L'
            puts "#{rule.next.name} = #{rule.next.name} - ((#{state.name} - #{vsop_value}) < 0)"
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
            puts "#{rule.next.name} = #{rule.next.name} + (#{state.name} == #{vsop_value})"
            puts "#{rule.next.name} = (#{rule.next.name} > 0) - (#{rule.next.name} < 0)"

            puts "#{state.name} = 0"
            do_epsilon(rule.next)

          when 'L'
            puts "#{rule.next.name} = #{rule.next.name} + ((#{state.name} - #{vsop_value}) > 0)"
            puts "#{rule.next.name} = (#{rule.next.name} > 0) - (#{rule.next.name} < 0)"
            puts "#{state.name} = 0"
            do_epsilon(rule.next)

          when :e
            puts "#{state.name} = 0"
          end
        end
      end
      vsop_dump @states if @debug
    end
  end

  def found_sets
    final = @states.find{|node| node.final == true}
    puts "? #{final.name}"
  end
end
