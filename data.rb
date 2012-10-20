require 'date'
records = 552074
RECORDS_1 = 140521
records_2 = records - RECORDS_1


def parse_ts(s)
  DateTime.parse(s).to_time.to_i / 60
end

def estimate_t(i)
  if i > RECORDS_1 - 1
    first = RANGE_2.first
    coeff = 0.65
    intercept = 36220 - RECORDS_1 + 1
  else
    first = RANGE_1.first
    coeff = 1.29
    intercept = 0
  end
  ((i + intercept) * coeff).to_i + first
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

def unpack(d)
  user_index = d & 2**11 - 1
  d >>= 11
  bike_index = d & 2**10 - 1
  d >>= 10
  end_station = d & 2**7 - 1
  d >>= 7
  start_station = d & 2**7 - 1
  d >>= 7
  duration = d & 2**13 - 1
  d >>= 13
  date = d
  [date, duration, start_station, end_station, bike_index, user_index]
end

BIKE_INDEX = build_index 'output/bikes.txt'
USER_INDEX = build_index 'output/users.txt'

RANGE_1 = parse_ts('2011-07-28 07:12:00-07') .. parse_ts('2011-11-30 20:58:00-08')
RANGE_2 = parse_ts('2012-03-13 15:31:00-07') .. parse_ts('2012-10-01 17:32:00-07')

