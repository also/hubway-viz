hwdv.makeMap = (zips) ->
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
