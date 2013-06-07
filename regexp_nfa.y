class RegexpSimple
rule
  target: exp
     | /* none */ { result = 0 }

  exp: exp '*' { result = StarNode.new(val[0]) }
     | exp exp { result = ConcatNode.new(val[0],val[1]) }
     | ALPHABET { result = ValueNode.new(val[0]) }
end

---- header
# Simple Regex
require 'regexp_ast.rb'


---- inner
  def parse(str)
    @q = []
    until str.empty?
      case str[0]
      when ' '
      when 'H'
        @q.push [:ALPHABET, 'H']
      when 'L'
        @q.push [:ALPHABET, 'L']
      when '*'
        @q.push ['*', '*']
      end
      str = str[1..-1]
    end
    @q.push [false, '$end']
    do_parse
  end

  def next_token
    @q.shift
  end

---- footer
