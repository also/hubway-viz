require './data'

RANGES = get_date_ranges
MAX_DURATION = 2**13 - 1

#File.open 'output/trips_packed', 'wb' do |out|
  ARGF.each_with_index do |line, i|
    id,status,duration,start_date,start_station_id,end_date,end_station_id,bike_nr,subscription_type,zip_code,birth_date,gender = line.strip.split ','
    d = [(duration.to_f / 60).ceil, MAX_DURATION].min
    # TODO wtf, this gives a crazy distribution where every fourth minute has very few trips
    t = parse_ts start_date
    end_t = parse_ts end_date
    #d = [end_t - t, MAX_DURATION].min
    estimated_t = estimate_t i
    error = estimated_t - t
    raise "oops (#{i}): #{error} #{line}" unless (-24521..23543) === error
    bike_index = BIKE_INDEX[bike_nr]
    user_index = USER_INDEX[[zip_code,birth_date,gender].join(',').gsub('"', '')]
    
    value = error
    value <<= 13
    value |= d
    value <<= 7
    value |= start_station_id[1...-1].to_i
    value <<= 7
    value |= end_station_id[1...-1].to_i
    value <<= 10
    value |= bike_index
    value <<= 11
    value |= user_index

    orig = [error, d, start_station_id[1...-1].to_i, end_station_id[1...-1].to_i, bike_index, user_index]
    #puts orig.join ','
    #puts unpack(value).join(', ')
    #puts d
    #puts "#{d} #{(end_t - t)}"
    packed = [value].pack('Q<')
    #out.write packed
    puts d
  end
#end
