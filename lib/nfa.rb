class ENFANode
  @@node_count = 0
  def self.count_refresh
    @@node_count = 0
  end

  class Rule
    attr_reader :accept, :next
    def initialize(accept, next_node)
      (@accept, @next) = accept, next_node
    end
  end

  attr_reader :name
  attr_accessor :rules, :set, :start, :final, :minus_node

  def initialize()
    @name = 'Q' + @@node_count.to_s
    @@node_count+=1
    @rules  = []
  end

  def set_rule(accept, next_node)
    @rules.push Rule.new(accept, next_node)
  end

  def find_rule(accept, next_node)
    @rules.find do |rule|
      rule.accept == accept && rule.next == next_node
    end
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

  def eclose(checked = {}, find = [])
    find.push(self)
    rules = self.epsilon_rules
    return find if rules.empty?

    checked[self.object_id] = true
    rules.each do |rule|
      unless checked[rule.next.object_id]
        rule.next.eclose(checked,find)
      end
    end
    return find
  end

  def same_node?(target)
    rules1 = self.rules
    rules2 = target.rules
    return false if rules1.length != rules2.length

    rules1.all? do |r1|
      rules2.find do |r2|
        r1.accept == r2.accept && r1.next == r2.next
      end
    end
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
    return '' if checked[self.object_id]
    checked[self.object_id] = true

    res = ""
    res << "#{self.name} [peripheries = 2]\n" if self.final
    res << "#{self.name} [peripheries = 3]\n" if self.minus_node

    self.rules.each do |rule|
      res += sprintf "%s -> %s[label=%s]\n", self.name, rule.next.name, rule.accept
      res += rule.next.dump(checked)
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

  def self._add_new_rule(enfa, reducted={})
    return if reducted[enfa.object_id]

    reducted[enfa.object_id] = true
    eclose = enfa.eclose()
    if enfa.start
      eclose.each do |node|
        if node.final
          enfa.final = true
          break
        end
      end
    end

    new_rules = eclose.map{|node|
      node.rules
    }.flatten.delete_if{|rule| rule.accept == :e}

    new_rules.each do |rule|
      dests = rule.next.eclose
      dests.each do |dest|
        unless enfa.find_rule(rule.accept, dest)
          enfa.set_rule(rule.accept, dest)
        end
      end
    end

    enfa.rules.each do |rule|
      self._add_new_rule(rule.next,reducted)
    end
    return enfa
  end

  def self._delete_epsilon(enfa,deleted={})
    return if deleted[enfa]
    deleted[enfa] = true
    enfa.rules.each do |rule|
      self._delete_epsilon(rule.next, deleted)
    end
    enfa.delete_rule(:e)
  end

  def self.delete_epsilon(enfa)
    self._add_new_rule(enfa)
    self._delete_epsilon(enfa)
  end

  def self.reduction(nfa, reducted={})
    return if reducted[nfa]
    reducted[nfa] = true

    nfa.rules.each do |rule|
      self.reduction(rule.next, reducted)
    end

    to_delete = {}
    to_change = {}

    nfa.rules.each_index do |i|
      rule1 = nfa.rules[i]
      next if rule1.next.final

      if rule1.next.rules.empty?
        to_delete[rule1] = true
        next
      end

      nfa.rules[i+1..-1].each do |rule2|
        next if rule1 == rule2

        node2 = rule2.next
        next if node2.final
        if rule1.next.same_node?(node2)
          if rule1.accept != rule2.accept
            to_change[rule2] = rule1.next
          else
            to_delete[rule2] = true
          end
        end
      end
    end

    new_rule  = []
    nfa.rules.each do |rule|
      if to_delete.has_key?(rule)
        next
      elsif new_dist = to_change[rule]
        new_rule << Rule.new(rule.accept, new_dist)
      else
        new_rule << rule
      end
    end
    nfa.rules = new_rule
  end

  def self.reduction_advanced(nfa, reducted={})
    return if reducted[nfa]
    reducted[nfa] = true

    nfa.rules.each do |rule|
      self.reduction_advanced(rule.next, reducted)
    end

    to_change = {}
    nfa.rules.each_index do |i|
      rule1 = nfa.rules[i]
      next if rule1.next.final

      nfa.rules[i+1..-1].each do |rule2|
        next if rule1 == rule2

        node2 = rule2.next
        next if node2.final
        if rule1.accept == rule2.accept
          to_change[rule1] = rule2
        end
      end
    end

    new_rule = []
    nfa.rules.each do |rule|
      if exist_rule = to_change[rule]
        new_next = exist_rule.next
        rule.next.rules.each do |next_rule|
          unless new_next.find_rule(next_rule.accept, next_rule.next)
            new_next.set_rule(next_rule.accept, next_rule.next)
          end
        end
      else
        new_rule << rule
      end
    end
    nfa.rules = new_rule
  end
end
