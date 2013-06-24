require 'json'
require 'date'

if ARGV[0]
  io = File.open(ARGV[0])
else
  io = STDIN
end

wio = nil
last_ym = ''
last_date = ''
io.each_line do |line|
  d    = JSON.parse(line.chomp)
  date = Date.parse(d[0])

  ym   = sprintf "%d_%02d", date.year.to_s,  date.month.to_s

  if last_ym != ym
    wio.close if !wio.nil?
    new_file = io.path + '_' + ym
    warn new_file
    warn last_date.inspect if last_date
    warn date.inspect     if date
    wio = File.open(new_file, 'w')
  end

  last_ym = ym
  last_date = date
  wio.puts(d[1].join("\t"))
end
wio.close
