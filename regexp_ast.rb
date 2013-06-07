require 'nfa.rb'
class ASTNode
end

class ConcatNode < ASTNode
  attr_accessor :lnode, :rnode
  def initialize(lnode, rnode)
    (@lnode, @rnode) = lnode, rnode
  end

  def to_nfa
    s  = ENFANode.new
    r1 = @lnode.to_nfa
    r2 = @rnode.to_nfa
    e  = ENFANode.new
    e.final = true

    s.set_rule(:e, r1)
    r1_final = r1.search_final
    r1_final.set_rule(:e, r2)
    r1_final.final = false

    r2_final = r2.search_final
    r2_final.set_rule(:e, e)
    r2_final.final = false

    return s
  end

  def inspect
    "(#{@lnode.inspect}+#{@rnode.inspect})"
  end
end

class StarNode < ASTNode
  attr_accessor :node
  def initialize(node)
    @node = node
  end

  def to_nfa
    s  = ENFANode.new
    r  = @node.to_nfa
    e  = ENFANode.new
    e.final = true

    s.set_rule(:e, r)
    r_final = r.search_final
    r_final.set_rule(:e, e)
    r_final.final = false

    e.set_rule(:e, s)
    return s
  end

  def inspect
    "(#{@node.inspect}*)"
  end
end

class ValueNode < ASTNode
  attr_accessor :val
  def initialize(str)
    @val = str
  end

  def to_nfa
    s = ENFANode.new
    r = ENFANode.new
    r.final = true
    s.set_rule(self.val, r)
    return s
  end

  def inspect
    "#{@val}"
  end
end
