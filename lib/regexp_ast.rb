require 'nfa.rb'
class ASTNode
end

class DisjunctionNode < ASTNode
  attr_accessor :lnode, :rnode
  def initialize(lnode, rnode)
    (@lnode, @rnode) = lnode, rnode
  end

  def to_nfa
    s  = ENFANode.new
    s.start = true

    r1 = @lnode.to_nfa
    r1.start = false

    r2 = @rnode.to_nfa
    r2.start = false

    e  = ENFANode.new
    e.final = true

    s.set_rule(:e, r1)
    r1_final = r1.search_final
    r1_final.set_rule(:e, e)
    r1_final.final = false

    s.set_rule(:e, r2)
    r2_final = r2.search_final
    r2_final.set_rule(:e, e)
    r2_final.final = false

    return s
  end

  def inspect
    "(#{@lnode.inspect}+#{@rnode.inspect})"
  end
end

class ConcatNode < ASTNode
  attr_accessor :lnode, :rnode
  def initialize(lnode, rnode)
    (@lnode, @rnode) = lnode, rnode
  end

  def to_nfa
    s  = ENFANode.new
    s.start = true

    r1 = @lnode.to_nfa
    r1.start = false

    r2 = @rnode.to_nfa
    r2.start = false

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
    s.start = true
    s.final = true

    r  = @node.to_nfa
    r.start = false

    s.set_rule(:e, r)
    r_final = r.search_final
    r_final.set_rule(:e, s)
    r_final.final = false
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
    s.start = true

    r = ENFANode.new
    r.final = true
    s.set_rule(self.val, r)
    return s
  end

  def inspect
    "#{@val}"
  end
end
