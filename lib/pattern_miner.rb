require 'regexp_nfa.tab.rb'
require 'nfa.rb'
require 'tempfile'

class PatternMiner
  def initialize(pattern, opt)
    @regex_parser = RegexpSimple.new
    @nfa    = @regex_parser.parse(pattern).to_nfa
    @nfa.nodes_by_epsilon_rules.each do |node|
      node.start = true
      node.minus_node = true
      node.nodes_by_lower_rules.each do |lnode|
        lnode.minus_node = true
        lnode.nodes_by_epsilon_rules.each do |enode|
          enode.minus_node = true
        end
      end
    end

    @states = @nfa.to_a
    @itemsets_num = 0

    @debug = opt[:debug] ? true : false

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

  def read_fimi_file(filename)
    line_count = 0
    lookup = {}
    File.open(filename).each_line do |line|
      line.chomp.split(/\s+/).each do |symbol|
        lookup[symbol] ||= true
      end
      line_count+=1
    end
    order = lookup.keys.sort
    return line_count, order
  end
public
  def frequent_itemsets(filename, minimum_support_ratio, order_file_path = nil)
    line_count, order = read_fimi_file(filename)
    @itemsets_num+=1
    vsop_value = "D#{@itemsets_num}"
    order_file = order_file_path ? File.open(order_file_path, 'r') : nil
    unless order_file
      order_file = File.open('_order_' + vsop_value, 'w')
      order_file.puts order.join(" ")
      order_file.close
    end
    minimum_support = (line_count * minimum_support_ratio).floor

    puts %Q!#{vsop_value} = Lcm("F" "#{filename}" #{minimum_support} "#{order_file.path}")!
    puts %Q!? #{vsop_value}! if @debug

    return vsop_value
  end

  def accept_itemsets(vsop_value)
    puts "? \"------ #{vsop_value} Cycle\"" if @debug
    @states.reverse.each do |state|
      puts "?\"Current State #{state.name}\"" if @debug
      if state.rules.empty?
        puts "#{state.name} = 0"

      elsif state.minus_node
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
    puts "? #{final.name} > 0"
  end
end
