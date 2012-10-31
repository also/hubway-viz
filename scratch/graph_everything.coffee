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
      .attr('fill', colorbrewer.Greens[9][0])
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

    paths.attr('fill', (d) -> colorbrewer.Greens[9][scale(m[d.properties.ZCTA5CE10])])

  d3.rebind map, dispatch, 'on'
  map

hwdv.load_data '/output', (data) ->
  #user_indexes = {}
  #  user_indexes[''+ r.user_index] = true
  #  r

  #for i in [0...data.users.length]
  #  if !user_indexes[''+i]
  #    console.log i

  hwdv.load_crossfilter_indexes '/output', (index) ->
    filter = hwdv.create_filters data, index
    creat_charts data, filter

creat_charts = (data, filter) ->
  charts = [
    barChart()
        .dimension(filter.dimension.start_hour)
        .group(filter.group.start_hours)
      .x(d3.scale.linear()
        .domain([0, 24])
        .rangeRound([0, 10 * 24])),

    barChart()
        .dimension(filter.dimension.start_day_of_week)
        .group(filter.group.start_day_of_weeks)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([0, 7])
        .rangeRound([0, 17 * 7]))
        .labels((d, i) -> 'SSMTWTF'[i])
        .barWidth(16),

    barChart()
        .dimension(filter.dimension.duration)
        .group(filter.group.durations)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([0, 60])
        .rangeRound([0, 7 * 60]))
      .barWidth(6),

    barChart()
        .dimension(filter.dimension.age)
        .group(filter.group.ages)
        .groupFilter((d) -> d.key != 0)
        .round(Math.floor)
      .x(d3.scale.linear()
        .domain([10, 80])
        .rangeRound([0, 210]))
      .barWidth(2),

    barChart()
        .dimension(filter.dimension.date)
        .group(filter.group.dates)
        .round(d3.time.day.round)
      .x(d3.time.scale()
        .domain([new Date(2011, 6, 25), new Date(2012, 9, 5)])
        .rangeRound([0, 438*2]))
       .barWidth(1),

    barChart()
        .dimension(filter.dimension.gender)
        .group(filter.group.genders)
        .groupFilter((d) -> d.key != 'U')
        .round(Math.floor)
      .x(d3.scale.ordinal()
        .domain(['F', 'M'])
        .range([0, 20]))
      .barWidth(19)
      .width(40)

    barChart()
        .dimension(filter.dimension.registration)
        .group(filter.group.registrations)
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
    d3.select("#active").text(formatNumber(filter.all.value()))

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
    .dimension(filter.dimension.zip)
    .group(filter.group.zips)
    .center([-71.058543, 42.367021])
    .on('filter', renderAll)
  map d3.select("#map")

  renderAll()
