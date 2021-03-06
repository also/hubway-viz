require 'date'
require 'json'

def get_date_ranges
  File.open 'output/date_ranges.json' do |f|
    JSON.load f
  end
end

def parse_ts(s)
  DateTime.parse(s).to_time.to_i / 60
end

def estimate_t(i)
  if i >= RANGES[1]['i']
    coeffs = RANGES[1]['coeffs']
  else
    coeffs = RANGES[0]['coeffs']
  end
  (coeffs[2] * i**2 + coeffs[1] * i + coeffs[0]).to_i
end

def build_index(filename)
  index = {}
  File.open filename do |f|
    f.each_with_index do |l, i|
      index[l.strip] = i
    end
  end
  index
end

def pack(error, d, start_station_id, end_station_id, bike_index, user_index)
  value = error
  value <<= 13
  value |= d
  value <<= 7
  value |= start_station_id.to_i
  value <<= 7
  value |= end_station_id.to_i
  value <<= 10
  value |= bike_index
  value <<= 12
  value |= user_index
  value
end

def unpack(d)
  user_index = d & 2**12 - 1
  d >>= 12
  bike_index = d & 2**10 - 1
  d >>= 10
  end_station = d & 2**7 - 1
  d >>= 7
  start_station = d & 2**7 - 1
  d >>= 7
  duration = d & 2**13 - 1
  d >>= 13
  error = d
  [error, duration, start_station, end_station, bike_index, user_index]
end

BIKE_INDEX = build_index 'output/bikes.txt'
USER_INDEX = build_index 'output/users.txt'

