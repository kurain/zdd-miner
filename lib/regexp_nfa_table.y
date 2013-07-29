class RegexpSimple
prechigh
  left STAR
  nonassoc CONCAT
  left '|'
preclow
rule
  target: exp
     | /* none */ { result = 0 }

  exp: exp '*' = STAR { result = StarNode.new(val[0]) }
     | exp '|' exp { p val ;result = DisjunctionNode.new(val[0], val[2]) }
     | exp exp = CONCAT { result = ConcatNode.new(val[0],val[1]) }
     | primary

  primary: '(' exp ')' { result = val[1] }
     | ALPHABET { result = ValueNode.new(val[0]) }
end

---- header
# Simple Regex
require 'regexp_ast_table.rb'


---- inner
  def parse(str)
    @q = []
    str = str.gsub(/(H|L){(\d+)}/) do
      $1 * $2.to_i
    end
    until str.empty?
      case str[0]
      when ' '
      when '|'
        @q.push ['|', '|']
      when /[A-Z]/
        @q.push [:ALPHABET, str[0]]
      when '*'
        @q.push ['*', '*']
      when '('
        @q.push ['(', '(']
      when ')'
        @q.push [')', ')']
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
