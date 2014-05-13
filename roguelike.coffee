mapString = """
	# # # # # # # # # # # # # # # # # # # # # # # # #
	. . . . . . . . . . . . . . . . . . . . . . . . #
	# # # # # # # # # # # . # # # # # # # # # # # # #
	. . . . . . . . . . # . # . . . . . . . . . . . .
	. . . . . . . . . . # . # . . . . . . . . . . . .
	. . . . . . . . . . # . # . . . . . . . . . . . .
	. . . . . . . . . # # . # # . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	. . . . . . . . . . . . . . . . . . . . . . . . .
	"""

tiles =
	'#':
		name: 'brick'
		passable: false
		fg: '#888'
		bg: '#444'
		action: ->
			console.log 'Your way is blocked by a brick wall.'
	
	'.':
		name: 'ground'
		passable: true
		fg: '#888'

	undefined:
		passable: false
		action: -> console.log 'Your way is blocked by the void.'



class Map
	@fromString: (map) ->
		new this((col for col in row.split(' ') for row in map.split('\n')))
	
	constructor: (@map) ->
		@cellSize = 20
		@canvas = @getCanvas()
		@context = @canvas.getContext('2d')

	getCanvas: ->
		currentCanvas = document.getElementsByTagName('canvas')
		if currentCanvas.length
			return currentCanvas[0]
		else
			canvas = document.createElement('canvas')
			canvas.height = 500
			canvas.width = 500
			document.body.appendChild canvas
			return canvas	

	draw: ->
		# paint background
		@context.fillStyle = '#333'
		@context.fillRect(0, 0, @canvas.height, @canvas.width)
		@context.fillStyle = '#ffefef'
		for row, y in @map
			for cell, x in row
				tile = tiles[cell]
				@drawTile(x, y, cell, tile.fg, tile.bg)
				
		for entity in entities
			x = entity.location.x
			y = entity.location.y
			if entity.marker 
				@context.fillText(entity.marker, x * @cellSize, ++y * @cellSize)

	drawTile: (x, y, text, fg = 'white', bg = 'black') ->
		@context.font = '25px Menlo'
		@context.fillStyle = bg
		@context.fillRect(x * @cellSize, y * @cellSize, @cellSize, @cellSize)
		@context.fillStyle = fg
		@context.fillText(text, x * @cellSize, ++y * @cellSize, @cellSize, @cellSize)
		# reset context
		@context.fillStyle = 'white'

	clear: ->
		@context.clearRect(0, 0, @canvas.width, @canvas.height)

	checkCollision: (x, y, executeActions = false) ->
		entity = _.where(entities, {location: {x: x, y: y}})?[0]
		cell = tiles[@map[y]?[x]]
		
		if executeActions
			entity?.action?() if entity?.marker isnt null
			cell?.action?()

		return not (cell?.passable is false or entity?.passable is false)

	inRadius: (center, radius, point) ->
		# Is point in radius of center?
		for y in [center.y - radius .. center.y + radius]
			for x in [center.x - radius .. center.x + radius]
				if point.x == x and point.y == y
					return true

# An entity is an item, actor, or an event
class Entity
	constructor: (options) ->
		defaults = 
			location: { x: null, y: null }
			marker: null
			name: ''
			passable: true
		_.extend(defaults, options)
		this[key] = value for key, value of defaults
		entities.push(this)

class Item extends Entity

class Event extends Entity
	constructor: (options) ->
		super options
		@marker = ' '
	action: -> 
		console.log @name
		@marker = null

class Actor extends Entity
	move: (x, y) ->
		if map.checkCollision(x, y)
			@location.x = x
			@location.y = y

	# AI Behaviors
	randomMovement: ->
		x = this.location.x + _.random(-1, 1)
		y = this.location.y + _.random(-1, 1)
		if map.checkCollision(x, y)
			this.location.x = x
			this.location.y = y

	moveTowardsDude: ->
		if dude.location.x > @location.x
			@location.x++
		else if dude.location.x < @location.x
			@location.x--

		if dude.location.y < @location.y
			@location.y--
		else if dude.location.y > @location.y
			@location.y++

	attack: (location) ->
		entity = dude
		if entity and entity.health > 0
			console.log "#{ @name } attacks #{ entity.name } for #{ @damage } points."
			entity.health -= @damage

class GiantSpider extends Actor
	constructor: (options) ->
		super options
		@marker = 'm'
		@name = 'giant spider'
		@passable = false
		@health = 30
		@damage = 3
		@agro = 5
		@attackRange = 1
	action: ->
		if @health > 0
			dude.attack(this)
		else
			console.log "You killed the #{ @name }."
			@passable = true
			@marker = '%'
	behavior: ->
		return if @health <= 0
		
		if map.inRadius(@location, @attackRange, dude.location)
			@attack(dude.location)

		else if map.inRadius(@location, @agro, dude.location)
			@moveTowardsDude(this)

		else
			@randomMovement(this)

entities = []

new Item
	location:
		x: 11
		y: 3
	marker: '¶'
	name: 'pilcrow of might'
	type: 'weapon'
	rating: 30
	action: ->
		console.log "You wield the #{ @name }"
		dude.equip(this)
		@marker = null

new Event
	location:
		x: 11
		y: 7
	name: "You walk into an open courtyard. In the middle creeps a giant spider!"

for i in [0..10]
	new GiantSpider
		location:
			x: _.random(0, 20)
			y: _.random(8, 20)




map = Map.fromString(mapString)

dude = new Actor
	name: 'dude'
	health: 100
	armor:
		name: 'clothes'
		rating: 0
	weapon:
		name: 'fists'
		rating: 5
	location:
		x: 1
		y: 1
	move: (key) ->
		LEFT = 37
		UP = 38
		RIGHT = 39
		DOWN = 40
		x = @location.x
		y = @location.y
		switch key
			when LEFT then x--
			when RIGHT then x++
			when UP then y--
			when DOWN then y++

		if map.checkCollision(x, y, true)
			@location.x = x
			@location.y = y
	equip: (item) ->
		if item.type is 'armor'
			@armor.name = item.name
			@armor.rating = item.rating
			console.log "Your armor rating is now #{ @armor.rating }."
		else if item.type is 'weapon'
			@weapon.name = item.name
			@weapon.rating = item.rating
			console.log "Your weapon rating is now #{ @weapon.rating }."
	attack: (entity) ->
		damage = @weapon.rating
		entity.health -= damage
		console.log("You attack the #{ entity.name } for #{ damage } points")
	draw: ->
		map.context.fillText('@', @location.x * map.cellSize, (@location.y + 1) * map.cellSize)



step = ->
	map.clear()
	map.draw()
	dude.draw()
	robots = _.filter(entities, 'behavior')
	robot.behavior() for robot in robots
		
	
$(document).on 'keydown', (e) ->
	dude.move(e.which)
	step()

# initialize everything
step()