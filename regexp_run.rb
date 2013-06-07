require 'regexp_nfa.tab.rb'
require 'nfa.rb'
require 'pp'
require 'tempfile'

parser = RegexpSimple.new
puts
puts 'type "Q" to quit.'
puts
while true
  puts
  print '? '
  str = gets.chop!
  break if /q/i =~ str
  begin
    ast = parser.parse(str)
    p ast
    p ast.class
    enfa = ast.to_nfa
    graph = "digraph g {\n"
    graph << "graph [rankdir = LR];\n"
    graph <<  enfa.dump
    graph << "}\n"

    puts graph

    file = Tempfile.new('foo')
    file.puts(graph)
    file.close

    puts "dot -Tpng -o test.png #{file.path} && open test.png"
    `dot -Tpng -o test.png #{file.path} && open test.png`


    graph = "digraph g {\n"
    graph << "graph [rankdir = LR];\n"
    graph << NFANode.reduction(enfa).dump
    graph << "}\n"

    file2 = Tempfile.new('foo')
    file2.puts(graph)
    file2.close

    puts "dot -Tpng -o test2.png #{file2.path} && open test.png"
    `dot -Tpng -o test2.png #{file2.path} && open test2.png`

  rescue ParseError
    puts $!
  end
  NFANode.count_refresh
end
