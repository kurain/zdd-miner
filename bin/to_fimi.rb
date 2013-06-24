MAX_VAL = 10000
id = 0
id_lookup = {}

file_name = ARGV[0]
meta_file = File.basename(file_name)

ARGV.each do |file_name|
  File.open(file_name, 'r').each_line do |raw|
    raw.chomp.split("\t").each do |word|
      if id_lookup[word]
        id_lookup[word][1] +=1
      else
        id += 1
        id_lookup[word] = [id, 1]
      end
    end
  end
end

limited_lookup = {}
order_lookup   = {}
order = 1

id_lookup.to_a.sort{|a,b| b[1][1] <=> a[1][1]}[0...10000].each do |pair|
  limited_lookup[pair[0]] = [order, pair[1][1]]
  order_lookup[order]  = pair[0]
  order += 1
end

ARGV.each do |file_name|
  out_file  = File.basename(file_name)
  output = File.open(out_file + '_fimi.txt', 'w')

  File.open(file_name, 'r').each_line do |raw|
    line = raw.chomp
    res = line.split("\t").map{|word|
      number, count = limited_lookup[word]
      number
    }.delete_if{|e| e.nil?}
    output.puts res.join(' ') unless res.empty?
  end
  output.close
end

File.open(meta_file + '_order.txt', 'w') do |io|
  io.puts limited_lookup.to_a.sort{|a,b| b[1][1] <=> a[1][1] }.map{|e| e[1][0] }.join(' ')
end

File.open(meta_file + '_lookup.txt', 'w') do |io|
  order_lookup.keys.sort{|a,b| a <=> b }.each do |order|
    word = order_lookup[order]
    number, count = limited_lookup[word]
    printf(io, "%s %d %d %d\n", word, order, count, number)
  end
end
