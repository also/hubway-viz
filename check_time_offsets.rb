require './data'

#puts mult_1
#exit

offsets = []
ARGF.each_with_index do |line, i|
  start_date = line[1..22]

  t = parse_ts start_date
  expected_t = estimate_t i
  offsets << (expected_t - t)
end

puts "min: #{offsets.min}"
puts "max: #{offsets.max}"
