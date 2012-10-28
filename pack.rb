require './data'

RANGES = get_date_ranges
MAX_DURATION = 2**13 - 1


def parse
  ARGF.each_with_index do |line, i|
    id,status,duration,start_date,start_station_id,end_date,end_station_id,bike_nr,subscription_type,zip_code,birth_date,gender = line.strip.split ','
    d = [(duration.to_f / 60).ceil, MAX_DURATION].min
    # TODO wtf, this gives a crazy distribution where every fourth minute has very few trips
    t = parse_ts start_date
    end_t = parse_ts end_date
    if end_t - t < 0
      puts "negative duration: " + line
      next
    end
    d = [end_t - t, MAX_DURATION].min
    estimated_t = estimate_t i
    error = estimated_t - t
    bike_index = BIKE_INDEX[bike_nr]
    user_index = USER_INDEX[[zip_code,birth_date,gender].join(',')]
    yield error, d, start_station_id.to_i, end_station_id.to_i, bike_index, user_index
  end
end

def loop_over_everything
  parse do |error, d, start_station_id, end_station_id, bike_index, user_index|
    orig = [error, d, start_station_id, end_station_id, bike_index, user_index]
    puts orig.join ','
  end
end

def build_packed_file
  File.open 'output/trips_packed', 'wb' do |out|
    parse do |error, d, start_station_id, end_station_id, bike_index, user_index|
      value = pack error, d, start_station_id, end_station_id, bike_index, user_index
      orig = [error, d, start_station_id, end_station_id, bike_index, user_index]
      unpacked = unpack(value)
      if unpacked != orig
        puts orig.join ','
        puts unpacked.join ','
        raise 'round-trip pack failed'
      end
      packed = [value].pack('Q<')
      out.write packed
    end
  end
end

build_packed_file
#loop_over_everything
