makeMap = (zips) ->
  # center on some random point near boston
  dimension = null
  group = null
  center = null
  projection = d3.geo.mercator().scale(899000)

  path = d3.geo.path().projection(projection)
  scale = d3.scale.sqrt().rangeRound([0, 8])

  paths = null
  map = (div) ->
    viz = div
      .append("svg:svg")
      .attr("width", 900)
      .attr("height", 500)

    paths = viz.append("svg:g")
      .attr("class", "tracts blues")
      .selectAll("path")
      .data(zips.features)
    paths.enter().append("svg:path")
      .attr('d', path)
      .attr('fill', colorbrewer.Blues[9][0])
      .attr('data-zip', (d) -> d.properties.ZCTA5CE10)
      .on('click', (d) ->
        path = d3.select(this)
        selected = path.classed 'selected'
        paths.classed 'selected', false
        if selected
          dimension.filterAll()
        else
          path.classed 'selected', true
          dimension.filterExact d.properties.ZCTA5CE10

        dispatch.filter()
      )

  dispatch = d3.dispatch('filter')

  map.dimension = (_) ->
    return dimension if !arguments.length
    dimension = _
    map

  map.group = (_) ->
    return group if !arguments.length
    group = _
    map

  map.center = (_) ->
    return center if !arguments.length
    center = _
    offset = projection center
    projection.translate [-offset[0] + 960, -offset[1] + 500]
    path.projection projection
    map

  map.update = ->
    groupFilter = (d) -> d.key != ''

    scale.domain([0, group.top(100).filter(groupFilter)[0].value])

    m = {}
    for g in group.all()
      m[g.key] = g.value

    paths.attr('fill', (d) -> colorbrewer.Blues[9][scale(m[d.properties.ZCTA5CE10])])

  d3.rebind map, dispatch, 'on'
  map

hwdv.load_data (data) ->
  user_indexes = {}
  records = for i in [0...data.trips.length]
    r = data.trips.get i
    user_indexes[''+ r.user_index] = true
    r

  for i in [0...data.users.length]
    if !user_indexes[''+i]
      console.log i

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
  zip = trips.dimension (d) -> data.users[d.user_index].zip_code ? ''
  zips = zip.group()

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
        .labels((d, i) -> 'SSMTWTF'[i])
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
    map.update()
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

  map = makeMap(data.zips_geo)
    .dimension(zip)
    .group(zips)
    .center([-71.058543, 42.367021])
    .on('filter', renderAll)
  map d3.select("#map")

  renderAll()
