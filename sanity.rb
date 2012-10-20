require 'set'

station_ids = Set.new

File.open 'output/stations.csv' do |f|
  f.each do |line|
    id, *rest = line.split ','
    station_ids << id
  end
end

genders = ['Female', 'Male', '']

File.open 'output/trips_sorted.csv' do |f|
  f.each_with_index do |line, i|
    problems = []
    id,status,duration,start_date,start_station_id,end_date,end_station_id,bike_nr,subscription_type,zip_code,birth_date,gender = line.strip.split ','
    problems << 'start_station_id' unless station_ids.include? start_station_id[1...-1]
    problems << 'end_station_id' unless station_ids.include? end_station_id[1...-1]
    problems << 'bike_nr' if bike_nr.index '?'
    if problems.length > 0
      puts "#{problems.join ' '},#{line}"
    end
  end
end
