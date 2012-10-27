require 'json'
require_relative 'data'

previous_ts = 0
MAX_TS_GAP = 60 * 24 * 3
range_start_ts = nil
range_start_index = nil
range = 0
date_offset_file = nil
ranges = []

File.open 'output/trips_sorted.csv' do |f|
  f.each_with_index do |line, i|
    id,status,duration,start_date,start_station_id,end_date,end_station_id,bike_nr,subscription_type,zip_code,birth_date,gender = line.strip.split ','
    ts = parse_ts start_date
    if ts - previous_ts > MAX_TS_GAP
      date_offset_file.close unless date_offset_file.nil?
      date_offset_file = File.open "output/range_date_offsets_#{range}", 'w'
      range += 1
      ranges << i
      range_start_index = i
      range_start_ts = ts
    end
      date_offset_file.puts "#{i}\t#{ts}"
    previous_ts = ts
  end
end

date_offset_file.close

range_json = ranges.each_with_index.map do |start_index, i|
  coeffs = `Rscript compute_date_coeffs.R output/range_date_offsets_#{i}`.strip.split("\n").map {|s| s.to_f}
  {
    :coeffs => coeffs,
    :i => start_index
  }
end

puts range_json.to_json
