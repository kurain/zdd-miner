require 'set'
module VSOPUtils
  module_function
  def all_combination(str)
    arr = str.split('')
    res = []
    (1..arr.length).each do |i|
      res += arr.combination(i).map{|e| e.join }.to_a
    end
    return res
  end

  def to_vsop(family)
    family.to_a.map{|set|
      set.split('').map{|i| "x#{i}" }.join(' ')
    }.join(' + ')
  end

  def vsop_dump(states)
    puts "? \"------------------------\""
    states.each do |state|
      puts "? \"#{state.name}\""
      puts "? #{state.name}"
    end
  end

  def dumpq(states)
    warn "--------"
    states.each do |state|
      warn "q-#{state.name}"
      warn state.set.inspect
    end
  end
end
