prefix = ARGV[0]
count = 0
now = Time.now
now_str = now.strftime('%F %T')
$stdin.each do |line|
  a = line.split("\t")
  res = []
  res << prefix + (count+=1).to_s
  res << now_str
  res << Time.at(a[1].to_i).strftime('%F %T')
  res << a[2]
  puts res.join("\t")
end
