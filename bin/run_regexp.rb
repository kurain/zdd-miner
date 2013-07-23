require 'regexp_nfa.tab.rb'
require 'nfa.rb'
require 'pp'
require 'tempfile'

str            =  ARGV[0]
delete_epsilon = !ARGV[1].nil?
reduction      = !ARGV[2].nil?
reduction_advanced = !ARGV[3].nil?
parser = RegexpSimple.new

puts str
ast = parser.parse(str)

enfa = ast.to_nfa

ENFANode.delete_epsilon(enfa) if delete_epsilon
ENFANode.reduction(enfa) if reduction
ENFANode.reduction_advanced(enfa) if reduction_advanced



graph = "digraph g {\n"
graph << "graph [rankdir = LR];\n"
graph <<  enfa.dump
graph << "}\n"

puts graph

file = Tempfile.new('foo')
file.puts(graph)
file.close

warn "dot -Tpng -o test.png #{file.path} && open test.png"
`dot -Tpng -o test.png #{file.path} && open test.png`


