# Set dimensions
width = 600
height = 600
outerRadius = 200

# Constants
PI = 3.1415

# Make linear scale
roundScale = d3.scale.linear()
	.domain([0, 1])
	.range([0, 360])

# Initial year
currentYear = 1970

# Years in dataset
years = d3.range(1970, 2011+1)

# Find SVG HTML element
svg = d3.select("svg")
	.attr("width", width)
	.attr("height", height)
	.append("g")

# Center arcs
arcWrapper = svg
	.append("g")
	.attr("class", "arcWrapper")
	.attr("transform", "translate(" + (width / 2) + "," + (height / 2 + 20) + ")")

# A label for the current year
title = svg.append("text")
	.attr("class", "title")
	.attr("dy", "1em")
	.text(currentYear)

# Tooltip
tooltipName = svg.append("text")
	.attr("class", "tooltip-name")
	.attr("x", width/2)
	.attr("y", height/2 + 20)
tooltipReserve = svg.append("text")
	.attr("class", "tooltip-reserve")
	.attr("x", width/2)
	.attr("y", height/2 + 20)
	.attr("dy", "1.6em")


# Format number
format = (number) ->
	return "$ " + number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");


# Function to get current year data from raw dataset
parseData = (input, currentYear) ->

	output = []
	sum = 0

	input.forEach (d, i) ->
		value = parseInt(d[currentYear], 10) || 0
		output.push({
			countryCode: d["Country_Code"]
			countryName: d["Country_Name"]
			reserve: value
			start: sum
			end: sum + value
		})
		sum += value

	output.forEach (d, i) ->
		d.start = d.start / sum
		d.end = d.end / sum
		d.hue = i * 360 / output.length

	return output


# Draw arc
arc = (extend = 0) ->
	d3.svg.arc()
		.startAngle((d) -> d.start * 2 * PI - PI)
		.endAngle((d) -> d.end * 2 * PI - PI)
		.innerRadius(outerRadius - 80)
		.outerRadius(outerRadius + extend)


# Mouse events
hover = (d) ->
	d3.select(@).select("path")
		.transition().duration(200)
			.attr("d", arc(20))
	d3.select(@).selectAll("text")
		.transition().duration(200)
			.attr("y", -30)
	tooltipName.text(d.countryName)
	tooltipReserve.text(format(d.reserve))

unhover = (d) ->
	d3.select(@)
		.select("path")
		.transition().duration(200)
			.attr("d", arc(0))
	d3.select(@).selectAll("text")
		.transition().duration(200)
			.attr("y", -10)
	tooltipName.text("")
	tooltipReserve.text("")



# Load data
d3.csv "countries.csv", (error, data) ->

	currentData = parseData data, currentYear

	arcs = arcWrapper.selectAll(".arc")
		.data(currentData)
		.enter()
		.append("g")
			.attr("class", "arc")
			.on("mouseover", hover)
			.on("mouseout", unhover)

	arcs.append("path")
	arcs.append("text")


	# Return update function
	update = ->
		title.text currentYear

		currentData = parseData data, currentYear

		arcWrapper.selectAll(".arc")
			.data(currentData)

		arcWrapper.selectAll("path")
			.data(currentData)
			.transition().duration(500)
				.attr("d", arc(0))
				.attr("fill", (d, i) -> return "hsl(#{d.hue}, 60%, #{i%2 * 2 + 40}%)")
				.attr("stroke", (d, i) -> return "hsl(#{d.hue}, 60%, #{i%2 * 2 + 40}%)")

		arcWrapper.selectAll("text")
			.data(currentData)
			.transition().duration(500)
				.attr("opacity", (d, i) -> return (d.end - d.start) * 20)
				.attr("y", -10)
				.text((d, i) -> return d.countryCode)
				.attr("transform", (d, i) -> return "rotate(#{ (d.start + d.end) / 2 * 360 + 180 }) translate(0, #{-outerRadius})")


	# Run first update
	update()


	# Change years buttons
	leftButton = document.querySelector ".button.left"
	rightButton = document.querySelector ".button.right"

	increaseYear = ->
		currentYear = Math.min(d3.max(years), currentYear + 1)
		rightButton.classList.add("disabled") if d3.max(years) == currentYear
		leftButton.classList.remove("disabled")
		update()

	decreaseYear = ->
		currentYear = Math.max(d3.min(years), currentYear - 1)
		leftButton.classList.add("disabled") if d3.min(years) == currentYear
		rightButton.classList.remove("disabled")
		update()

	window.focus()
	d3.select(window).on "keydown", ->
		switch d3.event.keyCode
			when 37 then decreaseYear(); break
			when 39 then increaseYear(); break

	# Buttons
	leftButton.on "click", -> decreaseYear()
	rightButton.on "click", -> increaseYear()
