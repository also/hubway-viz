window.hwdv = {}

class PackedTripRecords
  constructor: (array_buffer, @date_ranges) ->
    @data = new Int32Array array_buffer
    @length = @data.length / 2

  get: (index) ->
    a = @data[index * 2]
    b = @data[index * 2 + 1]
    user_index = a & 0x7ff
    a >>>= 11
    bike_index = a & 0x3ff
    a >>>= 10
    end_station = a & 0x7f
    a >>>= 7
    start_station = (a | (b << 4)) & 0x7f
    b >>>= 3
    duration = b & 0x1fff
    b >>>= 13
    start_date_error = b

    if index >= @date_ranges[1].i
      coeffs = @date_ranges[1].coeffs
    else
      coeffs = @date_ranges[0].coeffs
    estimated_start_date = ~~ (coeffs[2] * index*index + coeffs[1] * index + coeffs[0])
    start_date = estimated_start_date - start_date_error
    {start_date, duration, start_station, end_station, bike_index, user_index}

hwdv.PackedTripRecords = PackedTripRecords
