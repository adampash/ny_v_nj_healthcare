d3 = require 'd3'
$ = require 'jQuery'

removeables = [
  "Utah"
  "Pacific Northwest"
  "Midwest"
  "Colorado"
  "North Carolina"
]
removeable_ops = [
  "bunion"
  "decompression"
  "arthroscopy"
]

window.BarChart =
  barHeight: 43
  width: 420
  edge: 135
  textX: 121
  moneyX: 145
  data: DATA
  init: ->
    @width = $('.chart').width()
    @mobile = @width < 480
    if @mobile
      @barHeight = 30
      diff = 30
      @edge = @edge - diff - 8
      @moneyX = @moneyX - diff - 8
      @textX = 0
    new_data = []
    for region in @data
      unless region["Region"] in removeables
        new_data.push region
    @data = new_data
    $('.chart').height(@data.length * (@barHeight))
    if /(iPad|iPhone|iPod)/g.test( navigator.userAgent )
      $('body').addClass('ios')

  clean_num: (dollar_amount) ->
    parseFloat dollar_amount.replace("$", "").replace(',', '')
  getXData: (key) ->
    @data.map (data) =>
      @clean_num data[key]

  toTitleCase: (str) ->
    str.replace /\w\S*/g, (txt) ->
      txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

  formatKey: (key) ->
    initial_type = key.match(/([A-Z,]+ )+/)[0]
    type = @toTitleCase(initial_type).replace(/with /i, 'w/')
    "<span class=\"type\">#{type}</span> #{key.split(initial_type)[1]}"

  renderGraph: (key) ->
    $('h2.operation').html(@formatKey(key))
    @init()
    X_DATA = @getXData(key)
    x = d3.scale.linear()
          .domain([0, d3.max(X_DATA)])
          .range([0, @width - @edge])

    @chart = d3.select(".chart")
      .attr("width", @width)
      .attr("height", @barHeight * X_DATA.length)

    @bar = @chart.selectAll('g')
        .data(@data)
      .enter().append("g")
        .attr("transform", (d, i) => "translate(0, #{i * @barHeight})")

    @bar.append('rect')
        .attr('class', 'gray')
        .attr('x', @edge)
        .attr('width', "100%")
        .attr('height', @barHeight - 5)

    @bar.append('rect')
        .attr('x', @edge)
        .attr('class', 'data')
        .attr('width', (d) => x(@clean_num d[key]))
        .attr('height', @barHeight - 5)

    @bar.append("text")
        .attr("x", @moneyX)
        .attr("y", @barHeight/2 - 3)
        .attr("dy", ".35em")
        .text (d) -> d[key].replace(/\.\d\d/, '')

    @bar.append("text")
        .attr('class', 'name')
        .attr("x", @textX)
        .attr("y", @barHeight/2 - 3)
        .attr("dy", ".35em")
        .text (d) -> d["Region"]

  updateGraph: (key) ->
    @formatKey(key)
    $('h2.operation').text()
    $('h2.operation').html(@formatKey(key))
    X_DATA = @getXData(key)
    x = d3.scale.linear()
          .domain([0, d3.max(X_DATA)])
          .range([0, @width - @edge])

    @chart.attr("height", @barHeight * X_DATA.length)
    @bar.data(@data)
      .transition()
      .select('rect.data')
        .attr('width', (d) =>
          x(@clean_num d[key]) or 0
        )

    @bar.transition()
      .select("text")
        .attr("dy", ".35em")
        .text (d) -> d[key].replace(/\.\d\d/, '')

  showOperations: ->
    _ = require 'underscore'
    operations = _.keys(@data[0])
    operations.shift()

    for operation, index in operations
      add = true
      if @mobile
        for op in removeable_ops
          if operation.toLowerCase().indexOf(op) > -1
            add = false

      if add
        display_operation = @toTitleCase operation
        display_operation = display_operation
                      # .toLowerCase()
                      .replace("Inpatient", "(In)")
                      .replace("Outpatient", "")
                      .replace("With ", "w/")
        $('.operations').append """
          <div class="operation" data-op="#{operation}">
           #{display_operation}
          </div>
        """
        $('.operations').append "|" unless index is operations.length - 1

    $('div.operation').first().addClass('selected')

    $('div.operation').on 'click', (e) =>
      $el = $(e.target)
      @updateGraph $el.data('op')

      $('.selected').removeClass('selected')
      $el.addClass('selected')

BarChart.renderGraph("APPENDECTOMY Outpatient")
BarChart.showOperations()
