require 'csv'

current = 0
number_lookup = {}

file_name = ARGV[0]
meta_file = File.basename(file_name)

ARGV.each do |file_name|
  out_file  = File.basename(file_name)
  output = File.open(out_file + '_fimi.txt', 'w')

  File.open(file_name, 'r').each_line do |raw|
    line = raw.chomp[1..-2].gsub('\\"','');
    next if line.empty?
    res = line.split(',').map do |word|
      if number_lookup[word]
        number_lookup[word][1] +=1
        number_lookup[word][0]
      else
        current += 1
        number_lookup[word] = [current, 1]
        current
      end
    end
  output.puts res.join(' ')
  end
  output.close
end

File.open(meta_file + '_order.txt', 'w') do |io|
  io.puts(number_lookup.to_a.sort{|a,b| a[1][0] <=> b[1][0] }.map{|e| e[1][0]}.join(' '))
end

File.open(meta_file + '_lookup.txt', 'w') do |io|
  number_lookup.to_a.sort{|a,b| b[1][1] <=> a[1][1] }.each do |e|
    printf(io, "%s %d %d\n", e[0], e[1][0], e[1][1] )
  end
end
