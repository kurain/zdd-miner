require 'zdd'
#p ZDD.lcm('F', ARGV[0],  500).to_s
a = ZDD.itemset("a")
a_4 = a * 4
a_2 = a * 2
a_4.show
a_2.show
(a_4 / a_2).show
(a_4 / (a_2 > 0)).show
p (a_4 / (a_4 > 0)).to_i
