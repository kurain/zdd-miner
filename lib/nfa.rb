class ENFANode
  @@node_count = 0
  @@ALL_ALPHABTES = ['L', 'H']
  def self.count_refresh
    @@node_count = 0
  end

  class Rule
    attr_reader :accept, :next
    def initialize(accept, next_node)
      (@accept, @next) = accept, next_node
    end
  end

  attr_reader :rules, :name
  attr_accessor :set, :start, :final, :minus_node

  def initialize()
    @name = 'Q' + @@node_count.to_s
    @@node_count+=1
    @rules  = []
  end

  def set_rule(accept, next_node)
    @rules.push Rule.new(accept, next_node)
  end

  def delete_rule(accept)
    @rules = @rules.delete_if{|rule| rule.accept == accept}
  end

  def accept(char)
    reutrn @rules.find{|rule| rule.accept == char}
  end

  def search_final(checked = [])
    return self if self.final

    checked.push(self.name)
    @rules.each do |rule|
      find = nil
      find = rule.next.search_final(checked) unless checked.include?(rule.next.name)
      return find if find
    end
    return false
  end

  def epsilon_rules
    return @rules.select{|rule| rule.accept == :e}
  end

  def nodes_by_epsilon_rules(checked = {}, find = [])
    rules = self.epsilon_rules
    return find if rules.empty?

    checked[self.object_id] = true
    rules.each do |rule|
      unless checked[rule.next.object_id]
        find.push(rule.next)
        rule.next.nodes_by_epsilon_rules(checked,find)
      end
    end
    return find
  end

  def lower_rules
    return @rules.select{|rule| rule.accept == "L"}
  end

  def nodes_by_lower_rules(checked = {}, find = [])
    rules = self.lower_rules
    return find if rules.empty?

    checked[self.object_id] = true
    rules.each do |rule|
      unless checked[rule.next.object_id]
        find.push(rule.next)
        rule.next.nodes_by_lower_rules(checked,find)
      end
    end
    return find
  end

  def dump(checked = {})
    res = ""
    nexts = []
    checked[self.object_id] = true
    res << "#{self.name} [peripheries = 2]\n" if self.final
    res << "#{self.name} [peripheries = 3]\n" if self.minus_node

    self.rules.each do |rule|
      res += sprintf "%s -> %s[label=%s]\n", self.name, rule.next.name, rule.accept
      nexts.push rule.next unless checked[rule.next.object_id]
    end

    nexts.each do |node|
      res += node.dump(checked)
    end

    return res
  end

  def to_a(res = [])
    res.push(self)
    @rules.each do |rule|
      rule.next.to_a(res) unless res.include? rule.next
    end
    return res
  end
end

class NFANode < ENFANode
  def self.reduction(enfa)
    nodes = enfa.nodes_by_epsilon_rules
    p nodes
    @@ALL_ALPHABTES.each do |alphabet|
      nodes.each do |node|
        enfa.set_rule(alphabet,node)
        enfa.delete_rule(:e)
      end
    end

    reductted_node = {}
    enfa.rules.each do |rule|
      unless reductted_node[rule.next.object_id]
        reductted_node[rule.next.object_id] = true
        self.reduction(rule.next)
      end
    end
    return enfa
  end
end
