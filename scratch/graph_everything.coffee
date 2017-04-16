if Worker?
  worker = new Worker 'crossfilter_webworker.js'
  handleCrossfilterWorkerMessage = (e) ->
    [type, payload] = e.data
    if type == 'indexes'
      create_charts_and_filters payload
  worker.addEventListener 'message', handleCrossfilterWorkerMessage, false

data = null

hwdv.load_data '../output', (d) ->
  data = d
  if worker?
    worker.postMessage ['init', d]
  else
    create_charts_and_filters()

create_charts_and_filters = (indexes) ->
  filter = hwdv.create_filters data, indexes
  creat_charts data, filter
  $('#loading').hide()
  $('#charts').show()

creat_charts = (data, filter) ->
  charts = [
    start_hour = barChart()
        .dimension(filter.dimension.start_hour)
        .group(filter.group.start_hours)
      .x(d3.scale.linear()
        .domain([0, 24])
        .rangeRound([0, 10 * 24])),

    start_day_of_week = barChart()
        .dimension(filter.dimension.start_day_of_week)
        .group(filter.group.start_day_of_weeks)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([0, 7])
        .rangeRound([0, 17 * 7]))
        .labels((d, i) -> 'SSMTWTF'[i])
        .barWidth(16),

    duration = barChart()
        .dimension(filter.dimension.duration)
        .group(filter.group.durations)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([0, 60])
        .rangeRound([0, 7 * 60]))
      .barWidth(6),

    registration = barChart()
        .dimension(filter.dimension.registration)
        .group(filter.group.registrations)
        .round(Math.floor)
      .x(d3.scale.ordinal()
        .domain(['N', 'Y'])
        .rangeRoundBands([0, 40]))
      .barWidth(19)
      .width(40)

    gender = barChart()
        .dimension(filter.dimension.gender)
        .group(filter.group.genders)
        .groupFilter((d) -> d.key != 'U')
        .round(Math.floor)
      .x(d3.scale.ordinal()
        .domain(['F', 'M'])
        .rangeRoundBands([0, 40]))
      .barWidth(19)
      .width(40)

    age = barChart()
        .dimension(filter.dimension.age)
        .group(filter.group.ages)
        .groupFilter((d) -> d.key != 0)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([10, 80])
        .rangeRound([0, 210]))
      .barWidth(2),


    date = barChart()
        .dimension(filter.dimension.date)
        .group(filter.group.dates)
        .round(d3.time.day.round)
      .x(d3.time.scale()
        .domain([new Date(2011, 6, 25), new Date(2012, 9, 5)])
        .rangeRound([0, 438*2]))
       .barWidth(1),

  ]

  c = {date, start_hour, start_day_of_week, duration, gender, age, registration}
  
  # Given our array of charts, which we assume are in the same order as the
  # .chart elements in the DOM, bind the charts to the DOM and render them.
  # We also listen to the chart's brush events to update the display.

  # Renders the specified chart or list.
  render = (method) ->
    d3.select(this).call(method)

  # Whenever the brush moves, re-rendering everything.
  window.renderAll = ->
    chart.each(render)
    map.update()
    d3.select("#active").text(formatNumber(filter.all.value()))

  window.filter = (name, v) ->
    chart.filter(null) for chart in charts
    c[name].filter(v)
    renderAll()
    undefined

  window.reset = (i) ->
    charts[i].filter(null);
    renderAll();
    undefined

  chart = d3.selectAll(".chart")
      .data(charts)
      .each((chart) -> chart.on("brush", renderAll).on("brushend", renderAll))

  map = hwdv.makeMap(data.zips_geo)
    .dimension(filter.dimension.zip)
    .group(filter.group.zips)
    .center([-71.058543, 42.367021])
    .on('filter', renderAll)
  map d3.select("#map")

  renderAll()

window.d = (y,m,d=1) -> new Date y,m-1,d
