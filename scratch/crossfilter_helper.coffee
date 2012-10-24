# Various formatters.
window.formatNumber = d3.format ",d"
window.formatChange = d3.format "+,d"
window.formatDate = d3.time.format "%B %d, %Y"
window.formatTime = d3.time.format "%I:%M %p"

window.barChart = ->
  if (!barChart.id) then barChart.id = 0

  margin = {top: 10, right: 10, bottom: 20, left: 10}
  barWidth = 9
  x_scale = null
  y_scale = d3.scale.linear().range([100, 0])
  id = barChart.id++
  axis = d3.svg.axis().orient("bottom")
  brush = d3.svg.brush()
  brushDirty = null
  dimension = null
  group = null
  round = null

  chart = (div) ->
    width = x_scale.range()[1]
    height = y_scale.range()[0]

    y_scale.domain([0, group.top(1)[0].value])

    barPath = (groups) ->
      path = []
      i = -1
      n = groups.length
      d
      while (++i < n)
        d = groups[i]
        path.push("M", x_scale(d.key), ",", height, "V", y_scale(d.value), "h" + barWidth + "V", height)
      path.join("")

    resizePath = (d) ->
      e = +(d == "e")
      x = if e then 1 else -1
      y = height / 3

      ("M" + (.5 * x) + "," + y \
      + "A6,6 0 0 " + e + " " + (6.5 * x) + "," + (y + 6) \
      + "V" + (2 * y - 6) \
      + "A6,6 0 0 " + e + " " + (.5 * x) + "," + (2 * y) \
      + "Z" \
      + "M" + (2.5 * x) + "," + (y + 8) \
      + "V" + (2 * y - 8) \
      + "M" + (4.5 * x) + "," + (y + 8) \
      + "V" + (2 * y - 8))

    div.each ->
      div = d3.select(this)
      g = div.select("g")

      # Create the skeletal chart.
      if (g.empty())
        div.select(".title").append("a")
            .attr("href", "javascript:reset(" + id + ")")
            .attr("class", "reset")
            .text("reset")
            .style("display", "none")

        g = div.append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
          .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

        g.append("clipPath")
            .attr("id", "clip-" + id)
          .append("rect")
            .attr("width", width)
            .attr("height", height)

        g.selectAll(".bar")
            .data(["background", "foreground"])
          .enter().append("path")
            .attr("class", (d) -> "#{d} bar")
            .datum(group.all());

        g.selectAll(".foreground.bar")
            .attr("clip-path", "url(#clip-" + id + ")")

        g.append("g")
            .attr("class", "axis")
            .attr("transform", "translate(0," + height + ")")
            .call(axis);

        # Initialize the brush component with pretty resize handles.
        gBrush = g.append("g").attr("class", "brush").call(brush)
        gBrush.selectAll("rect").attr("height", height)
        gBrush.selectAll(".resize").append("path").attr("d", resizePath)

      # Only redraw the brush if set externally.
      if (brushDirty) 
        brushDirty = false
        g.selectAll(".brush").call(brush)
        div.select(".title a").style("display", if brush.empty() then "none" else null)
        if (brush.empty())
          g.selectAll("#clip-" + id + " rect")
              .attr("x", 0)
              .attr("width", width)
        else
          extent = brush.extent()
          g.selectAll("#clip-" + id + " rect")
              .attr("x", x_scale(extent[0]))
              .attr("width", x_scale(extent[1]) - x_scale(extent[0]))

      g.selectAll(".bar").attr("d", barPath);

  brush.on "brushstart.chart", ->
    div = d3.select(this.parentNode.parentNode.parentNode)
    div.select(".title a").style("display", null);

  brush.on "brush.chart", ->
    g = d3.select(this.parentNode)
    extent = brush.extent()

    if (round) then g.select(".brush")
        .call(brush.extent(extent = extent.map(round)))
      .selectAll(".resize")
        .style("display", null)
    g.select("#clip-" + id + " rect")
        .attr("x", x_scale(extent[0]))
        .attr("width", x_scale(extent[1]) - x_scale(extent[0]))
    dimension.filterRange(extent)

  brush.on "brushend.chart", ->
    if (brush.empty())
      div = d3.select(this.parentNode.parentNode.parentNode)
      div.select(".title a").style("display", "none")
      div.select("#clip-" + id + " rect").attr("x", null).attr("width", "100%")
      dimension.filterAll()

  chart.margin = (_) ->
    return margin if (!arguments.length)
    margin = _
    chart

  chart.barWidth = (_) ->
    return barWidth if (!arguments.length)
    barWidth = _
    chart

  chart.x = (_) ->
    return x_scale if (!arguments.length)
    x_scale = _
    axis.scale(x_scale)
    brush.x(x_scale)
    chart

  chart.y = (_) ->
    return y_scale if (!arguments.length)
    y_scale = _
    chart

  chart.dimension = (_) ->
    return dimension if (!arguments.length)
    dimension = _
    chart

  chart.filter = (_) ->
    if (_) 
      brush.extent(_)
      dimension.filterRange(_)
    else
      brush.clear()
      dimension.filterAll()
    
    brushDirty = true
    chart

  chart.group = (_) ->
    ireturn group if (!arguments.length)
    group = _
    chart

  chart.round = (_) ->
    return round if (!arguments.length)
    round = _
    chart

  return d3.rebind(chart, brush, "on")
