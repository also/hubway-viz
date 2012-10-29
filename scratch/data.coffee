class PackedTripRecords
  constructor: (array_buffer, @date_ranges) ->
    @data = new Int32Array array_buffer
    @length = @data.length / 2

  get: (index) ->
    a = @data[index * 2]
    b = @data[index * 2 + 1]
    user_index = a & 0xfff
    a >>>= 12
    bike_index = a & 0x3ff
    a >>>= 10
    end_station = a & 0x7f
    a >>>= 7
    start_station = (a | (b << 3)) & 0x7f
    b >>>= 4
    duration = b & 0x1fff
    b >>>= 13
    start_date_error = b << 17 >> 17

    if index >= @date_ranges[1].i
      coeffs = @date_ranges[1].coeffs
    else
      coeffs = @date_ranges[0].coeffs
    estimated_start_date = ~~ (coeffs[2] * index*index + coeffs[1] * index + coeffs[0])
    start_ts = estimated_start_date - start_date_error
    start_date = new Date start_ts * 60000
    {index, start_date, duration, start_station, end_station, bike_index, user_index}

parse_users = (str) ->
  for line in str.split '\n'
    [zip_code, year, gender] = line.split ','
    zip_code = null if zip_code == ''
    year = if year == '' then null else parseInt(year, 10)
    gender = null if gender == ''
    registered = !!(gender or year or zip_code)
    {zip_code, year, gender, registered}

load_data = (callback) ->
  xhr = new XMLHttpRequest
  xhr.open 'GET', '/output/date_ranges.json', false
  xhr.send()
  date_ranges = JSON.parse xhr.response

  xhr = new XMLHttpRequest
  xhr.open 'GET', '/output/users.txt', false
  xhr.send()
  users = parse_users xhr.response

  xhr = new XMLHttpRequest
  xhr.open 'GET', '/output/zips_filtered.json', false
  xhr.send()
  zips_geo = JSON.parse xhr.response

  xhr = new XMLHttpRequest
  xhr.open 'GET', '/output/trips_packed', true
  xhr.responseType = 'arraybuffer'

  xhr.onload = (e) ->
    if @status == 200
      d = e.target.response
      trips = new hwdv.PackedTripRecords(d, date_ranges)
      callback {trips, users, zips_geo}

  xhr.send()

@hwdv = {
  PackedTripRecords,
  load_data,
  parse_users
}
