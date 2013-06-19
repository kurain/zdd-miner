lookup = {}
File.open(ARGV[0],'r').each_line do |line|
  word, number, count = line.chomp.split(' ')
  lookup[number] = [word, count]
end

while text = STDIN.gets do
  res = text.gsub(/x(\d+)/){ lookup[$1][0] }
  puts res
end
