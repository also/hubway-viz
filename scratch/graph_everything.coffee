hwdv.load_data (data) ->
  records = for i in [0...data.trips.length]
    data.trips.get i

  trips = crossfilter records
  all = trips.groupAll()
  # A nest operator, for grouping the trip list.
  nestByDate = d3.nest().key (d) -> d3.time.day(d.start_date)
  date = trips.dimension (d) -> d3.time.day(d.start_date)
  dates = date.group()
  start_hour = trips.dimension (d) -> d.start_date.getHours() + d.start_date.getMinutes() / 60
  start_hours = start_hour.group Math.floor
  start_day_of_week = trips.dimension (d) -> (d.start_date.getDay() + 1) % 7
  start_day_of_weeks = start_day_of_week.group()
  duration = trips.dimension (d) -> d.duration
  durations = duration.group()
  gender = trips.dimension (d) -> (data.users[d.user_index].gender ? "Unknown")[0]
  genders = gender.group()
  age = trips.dimension (d) -> 2012 - (data.users[d.user_index].year ? 2012)
  ages = age.group()
  registration = trips.dimension (d) -> data.users[d.user_index].registered
  registrations = registration.group()

  charts = [
    barChart()
        .dimension(start_hour)
        .group(start_hours)
      .x(d3.scale.linear()
        .domain([0, 24])
        .rangeRound([0, 10 * 24])),

    barChart()
        .dimension(start_day_of_week)
        .group(start_day_of_weeks)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([0, 7])
        .rangeRound([0, 17 * 7]))
        .barWidth(16),

    barChart()
        .dimension(duration)
        .group(durations)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([0, 60])
        .rangeRound([0, 7 * 60]))
      .barWidth(6),

    barChart()
        .dimension(age)
        .group(ages)
        .groupFilter((d) -> d.key != 0)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([10, 80])
        .rangeRound([0, 210]))
      .barWidth(2),

    barChart()
        .dimension(date)
        .group(dates)
        .round(d3.time.day.round)
      .x(d3.time.scale()
        .domain([new Date(2011, 6, 25), new Date(2012, 9, 5)])
        .rangeRound([0, 438*2]))
       .barWidth(1),

    barChart()
        .dimension(gender)
        .group(genders)
        .groupFilter((d) -> d.key != 'U')
        .round(Math.floor)
      .x(d3.scale.ordinal()
        .domain(['F', 'M'])
        .range([0, 20]))
      .barWidth(19)
      .width(40)

    barChart()
        .dimension(registration)
        .group(registrations)
        .round(Math.floor)
      .x(d3.scale.ordinal()
        .domain([false, true])
        .range([0, 20]))
      .barWidth(19)
      .width(40)
  ]
  
  # Given our array of charts, which we assume are in the same order as the
  # .chart elements in the DOM, bind the charts to the DOM and render them.
  # We also listen to the chart's brush events to update the display.

  # Renders the specified chart or list.
  render = (method) ->
    d3.select(this).call(method)

  # Whenever the brush moves, re-rendering everything.
  renderAll = ->
    chart.each(render)
    d3.select("#active").text(formatNumber(all.value()))

  window.filter = (filters) ->
    filters.forEach((d, i) -> charts[i].filter(d) )
    renderAll()

  window.reset = (i) ->
    charts[i].filter(null);
    renderAll();

  chart = d3.selectAll(".chart")
      .data(charts)
      .each((chart) -> chart.on("brush", renderAll).on("brushend", renderAll))

  renderAll()
