class NFA
  attr_reader :rules

  def initialize
    @node_count = 0
    @states = {}
    @rules  = {}
    @starts = {}
    @finals = {}
    @data   = {}
  end

  def count_refresh
    @node_count = 0
  end

  def create_state()
    @node_count+=1
    name = 'Q' + @node_count.to_s
    @states[name] = true
    return name
  end

  def set_final(state)
    @finals[state] = true
  end

  def unset_final(state)
    @finals.delete(state)
  end

  def set_start(state)
    @starts[state] = true
  end

  def unset_start(state)
    @starts.delete(state)
  end

  def add_rule(src, alphabet, dest)
    if !@states[src] || !@states[dest]
      p caller
      abort('no such state')
    end
    @rules[src] ||= {}
    @rules[src][alphabet] ||= {}
    @rules[src][alphabet][dest] = true
  end

  def delete_rule(src, accept)
    p caller; abort('no such state') if !@states[src]
    @rules[src].delete(accept)
  end

  def accept(src, char)
    return @rules[src][char]
  end

  def epsilon_dests(src)
    return (@rules[src] && @rules[src][:e]) ? @rules[src][:e].keys : []
  end

  def eclose(src, checked={})
    return if checked[src]

    checked[src] = true
    ec = epsilon_dests(src)
    find = ec.clone

    ec.each do |state|
      find += eclose(state, checked)
    end
    return find
  end

  def search_final(state, checked = {})
    return if checked[state]
    return state if @finals[state]

    checked[state] = true
    @rules[state].each do |alphabet, dests|
      dests.each_key do |dest|
        find = self.search_final(dest, checked)
        return find if find
      end
    end
    return false
  end

  def dump
    res = ""
    @finals.each_key do |state|
      res << "#{state} [peripheries = 2]\n"
    end

    @rules.each do |src, rule|
      rule.each do |alphabet, dests|
        dests.each_key do |dest|
          res << sprintf("%s -> %s[label=%s]\n", src, dest, alphabet)
        end
      end
    end
    return res
  end

  def _add_new_rule(state, reducted={})
    return if reducted[state]

    reducted[state] = true
    ec = eclose(state)

    if @starts[state]
      ec.each do |dest|
        if @finals[dest]
          set_final(state)
          break
        end
      end
    end

    new_rules = {}

    ec.each do |state|
      if @rules[state]
        @rules[state].each do |alphabet, dests|
          next if alphabet == :e
          new_rules[alphabet] = dests
        end
      end
    end

    new_rules.each do |alphabet, dests|
      dests.each_key do |dest|
        new_dests = eclose(dest)
        new_dests.each do |nd|
          p [state, alphabet, nd]
          add_rule(state, alphabet, nd)
        end
      end
    end

    if @rules[state]
      @rules[state].each do |alphabet, dests|
        dests.each_key do |dest|
          _add_new_rule(dest, reducted)
        end
      end
    end
  end

  def _delete_epsilon(state, deleted={})
    return if deleted[state]
    deleted[state] = true
    if @rules[state]
      @rules[state].each do |alphabet, dests|
        dests.each_key do |dest|
          _delete_epsilon(dest, deleted)
        end
      end
      @rules[state].delete(:e)
    end
  end

  def delete_epsilon
    @starts.each_key do |state|
      _add_new_rule(state)
      _delete_epsilon(state)
    end
  end

  def reduction(state, reducted={})
    return if reducted[state]
    reducted[state] = true

    @rules[state].each do |alphabet, dests|
      dsets.each_key do |dest|
        reduction(dest, reducted)
      end
    end

    to_delete = {}
    to_change = {}

    rules = @rules[state].to_a
    rules.each_index do |i|
      rule = rules[i]
      alphabet, dests = *rule

      dsets.each_key do |dest|
        next if @finals[dest]

        if @rules[dest].empty?
          to_delete[rule1] = true
          next
        end

        rules[i+1..-1].each do |alphabet2, dests2|
          dests2.each_key do |dest2|
            if dest == dest2
              to_change[alphbet2] ||= {}
              to_change[alphbet2][dest] = dest2
            end
          end
        end
      end
    end

    new_rule  = []
    nfa.rules.each do |rule|
      if to_delete.has_key?(rule)
        next
      elsif new_dest = to_change[rule]
        new_rule << Rule.new(rule.accept, new_dest)
      else
        new_rule << rule
      end
    end
    nfa.rules = new_rule
  end

  def same_state?(s1, s2)
    rules1 = self.rules
    rules2 = target.rules
    return false if rules1.length != rules2.length

    rules1.all? do |r1|
      rules2.find do |r2|
        r1.accept == r2.accept && r1.next == r2.next
      end
    end
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
