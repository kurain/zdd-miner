require 'nfa_class.rb'
class ASTNode
end

class DisjunctionNode < ASTNode
  attr_accessor :lnode, :rnode
  def initialize(lnode, rnode)
    (@lnode, @rnode) = lnode, rnode
  end

  def to_nfa(nfa)
    s  = nfa.create_state()
    nfa.set_start(s)

    r1 = @lnode.to_nfa(nfa)
    nfa.unset_start(r1)

    r2 = @rnode.to_nfa(nfa)
    nfa.unset_start(r2)

    e  = nfa.create_state()
    nfa.set_final(e)

    nfa.add_rule(s, :e, r1)
    r1_final = nfa.search_final(r1)
    nfa.add_rule(r1_final, :e, e)
    nfa.unset_final(r1_final)


    nfa.add_rule(s, :e, r2)
    r2_final = nfa.search_final(r2)
    nfa.add_rule(r2_final, :e, e)
    nfa.unset_final(r2_final)

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

  def to_nfa(nfa)
    s  = nfa.create_state()
    nfa.set_start(s)

    r1 = @lnode.to_nfa(nfa)
    nfa.unset_start(r1)

    r2 = @rnode.to_nfa(nfa)
    nfa.unset_start(r2)

    e  = nfa.create_state()
    nfa.set_final(e)

    nfa.add_rule(s, :e , r1)

    r1_final = nfa.search_final(r1)
    nfa.add_rule(r1_final, :e , r2)
    nfa.unset_final(r1_final)

    r2_final = nfa.search_final(r2)
    nfa.add_rule(r2_final, :e , e)
    nfa.unset_final(r2_final)
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

  def to_nfa(nfa)
    s  = nfa.create_state()
    nfa.set_start(s)
    nfa.set_final(s)

    r  = @node.to_nfa(nfa)
    nfa.unset_start(r)

    nfa.add_rule(s, :e, r)

    r_final = nfa.search_final(r)
    nfa.add_rule(r_final, :e, s)
    nfa.unset_final(r_final)
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

  def to_nfa(nfa)
    s = nfa.create_state()
    nfa.set_start(s)

    r = nfa.create_state()
    nfa.set_final(r)
    nfa.add_rule(s, self.val, r)
    return s
  end

  def inspect
    "#{@val}"
  end
end
