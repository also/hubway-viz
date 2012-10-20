bike_positions = {}

File.open ARGV[0] do |f|
  f.each_with_index do |line, i|
    id,status,duration,start_date,start_station_id,end_date,end_station_id,bike_nr,subscription_type,zip_code,birth_date,gender = line.strip.split ','
    previous_position, previous_index, previous_end_date = bike_positions[bike_nr]
    unless previous_position.nil?
      if previous_position != start_station_id
        puts [i,previous_index,bike_nr,start_station_id,previous_position].join ','
      else
         # stayed
      end
      if start_date < previous_end_date
        #puts "not possible: #{id}"
      end
    else
      # first ride
    end
    bike_positions[bike_nr] = [end_station_id, i, end_date]
  end
end
