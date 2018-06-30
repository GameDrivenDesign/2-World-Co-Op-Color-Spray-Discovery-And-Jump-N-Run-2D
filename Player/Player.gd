tool
extends RigidBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"


enum MovementState {
	STANDING,
	WALKING,
	JUMPING,
	FALLING,
	STOMPING
}

export (NodePath) var mapPath

export (int) var playerId = 1
export (int) var movementVelocity = 100
export (int) var jumpVelocity = 400
export (bool) var isAlive = true
export (bool) var winScreen = false
export (String, "white", "black", "red", "magenta", \
				"blue", "cyan", "green", "yellow") var startColor = "green"
				

var paintColor = Color(1.0, 0.0, 1.0) setget setPaintColor, getPaintColor

var upDirection
var inputMovementDirection
var movementState = MovementState.STANDING
var lastMovementState = MovementState.STANDING
var currentLinearVelocity
var screenDims = OS.get_real_window_size()
const marginToScreenWidth = 50

var playerID

var blockTintQueue = []
const TINT_DELAY = 0.7
const STUCK_COLLISION_AVOIDANCE_DISTANCE = 0.1

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	if winScreen:
		return
	if playerId == 1:
		upDirection = Vector2(0, -1)
	else:
		upDirection = Vector2(0, 1)
	add_to_group("player")
	setPaintColor(Colors.color_name_to_rgb(startColor))

func currentMovementState():
	if movementState == MovementState.STOMPING and $Node2D/AnimationPlayer.is_playing():
		return MovementState.STOMPING
	if onFloor():
		if inputMovementDirection == Vector2(0, 0):
			if Input.is_action_pressed('player' + String(playerId) + '_crouch'):
				return MovementState.STOMPING
			else:
				return MovementState.STANDING
		else:
			return MovementState.WALKING
	elif currentLinearVelocity.y * upDirection.y > 0:
		return MovementState.JUMPING
	else:
		return MovementState.FALLING

func updateMovementState():
	lastMovementState = movementState
	movementState = currentMovementState()

func processAnimation():
	if inputMovementDirection.x > 0:
		$Node2D.scale.x = 1
	else:
		$Node2D.scale.x = -1
	
	if lastMovementState == MovementState.FALLING && (movementState == MovementState.STANDING || movementState == MovementState.WALKING):
		$sounds/common/landing.play()
	
	if movementState != lastMovementState:
		var animationName
		match movementState:
			MovementState.STANDING:
				animationName = "standing"
			MovementState.WALKING:
				animationName = "walking"
				$sounds/walking.play()
			MovementState.JUMPING:
				animationName = "jumping"
			MovementState.FALLING:
				animationName = "falling"
			MovementState.STOMPING:
				animationName = "stomping"
		$Node2D/AnimationPlayer.play(animationName)
	if movementState == MovementState.WALKING && !$sounds/walking.playing:
		$sounds/walking.play()

func _process(delta):
	if winScreen:
		return
	updateMovementState()
	processAnimation()
	disposeColor(delta)
	checkSpikes()

func setPaintColor(inputColor):
	paintColor = inputColor
	setParticlesColor(inputColor)

func setParticlesColor(inputColor):
	var colorStomp = $Node2D/colorStomp
	var colorParticles = $Node2D/colorParticles
	if colorStomp and colorParticles:
		colorStomp.process_material.color = inputColor
		colorParticles.process_material.color = inputColor

func getPaintColor():
	return paintColor

func movementDirectionFromInput():
	var direction = Vector2(0, 0)
	if Input.is_action_pressed('player' + String(playerId) + '_left'):
		direction.x += -1
	if Input.is_action_pressed('player' + String(playerId) + '_right'):
		direction.x += 1
	return (direction if direction == Vector2(0, 0) else direction.normalized())

func requestsJump():
	return Input.is_action_pressed('player' + String(playerId) + '_jump')

func onFloor():
	return test_motion(-upDirection)
	
func onWall(direction):
	return test_motion(direction)
	
func queueTint():
	var map = get_node(mapPath)
	var colPos = $CollisionShape2D.position
	var pos = position
	var playerPos = position + $CollisionShape2D.position
	var playerExt = $CollisionShape2D.shape.extents
	var verticalHalfTileExtent = map.cell_size.y * 0.5
	var playerBottomPosition = playerPos + Vector2(0, -upDirection.y * playerExt.y)
	var tilePoint = playerBottomPosition + Vector2(0, -upDirection.y * verticalHalfTileExtent)
	var tilePos = map.world_to_map(tilePoint)
	queuePaintBlock(tilePos)

func queuePaintBlock(tilePos):
	var map = get_node(mapPath)
	var currentTileIndex = 0
	var is_additive = tilePos.y >= 0
	var currentTileName = map.tile_set.tile_get_name(map.get_cellv(tilePos))
	var currentTileColorName = currentTileName.split("Block")[0].to_lower()
	var newColor = getPaintColor()	
	if is_additive:
		newColor = Colors.mix_additive_rgb(Colors.color_name_to_rgb(currentTileColorName), getPaintColor())
	else:
		newColor = Colors.mix_subtractive_rgb(Colors.color_name_to_rgb(currentTileColorName), getPaintColor())
	if newColor == Colors.color_name_to_rgb(currentTileColorName):
		var newTilePos = tilePos - upDirection
		if map.get_cellv(newTilePos) != -1:
			queuePaintBlock(newTilePos)
	else:			
		var tileName = Colors.rgb_to_color_name(newColor).capitalize() + "Block"
		var tileId = map.tile_set.find_tile_by_name(tileName)
		blockTintQueue.append([TINT_DELAY, tilePos, tileId])
	
func disposeColor(delta):
	if movementState == MovementState.STOMPING and movementState != lastMovementState:
		queueTint()
		$sounds/common/stomp.play()
	
	var newTintQueue = []
	for element in blockTintQueue:
		element[0] -= delta
		if element[0] < 0:
			get_node(mapPath).set_cellv(element[1], element[2])
		else:
			newTintQueue.append(element)
	blockTintQueue = newTintQueue
		
func correctMovementAccordingToViewport(movementFromInput):
	var posRelativeToViewportX = get_global_transform_with_canvas().get_origin().x
	if(posRelativeToViewportX < marginToScreenWidth and movementFromInput.x < 0) or (posRelativeToViewportX > screenDims.x - marginToScreenWidth and movementFromInput.x > 0):
		movementFromInput.x = 0 # stop moving to far to one side
	return movementFromInput

func stuckAvoidance(state):
	if onFloor():
		state.transform.origin += upDirection * STUCK_COLLISION_AVOIDANCE_DISTANCE
	elif onWall(Vector2(1, 0)):
		state.linear_velocity.x = 0
		state.transform.origin -= Vector2(1, 0) * STUCK_COLLISION_AVOIDANCE_DISTANCE
	elif onWall(Vector2(-1, 0)):
		state.linear_velocity.x = 0
		state.transform.origin -= Vector2(-1, 0) * STUCK_COLLISION_AVOIDANCE_DISTANCE

func _integrate_forces(state):
	if winScreen:
		return
	
	if movementState == MovementState.STOMPING:
		return
	var velocity = Vector2(0, 0)
	
	if (requestsJump() && onFloor()):
		var jump_factor = 1
		if checkBlock() == "BlueBlock":
			jump_factor = 2.7 
		velocity += upDirection * jumpVelocity *jump_factor
		$sounds/common/jump.play()
		
	inputMovementDirection = correctMovementAccordingToViewport(movementDirectionFromInput())

	velocity += inputMovementDirection * movementVelocity
	state.linear_velocity += velocity
	state.linear_velocity.x = clamp(state.linear_velocity.x, -movementVelocity, movementVelocity)
	stuckAvoidance(state)
	currentLinearVelocity = state.linear_velocity	
		
func checkSpikes():
	var val = checkBlock()
	if val == "SpikeBlockWhite" or val == "SpikeBlockBlack":
		isAlive = false
		print("player died")
		playerDies()
		
func checkBlock():
	if not mapPath:
		return ''
	var map = get_node(mapPath)
	var playerPos = position
	var playerExt = get_node("CollisionShape2D").shape.extents
	var verticalHalfTileExtent = map.cell_size.y * 0.5
	var playerBottomPosition = playerPos + Vector2(0, -upDirection.y * playerExt.y)
	var tilePoint = playerBottomPosition + Vector2(0, -upDirection.y * verticalHalfTileExtent)
	var tilePos = map.world_to_map(tilePoint)
	var tileID = map.get_cellv(tilePos)
	return map.tile_set.tile_get_name(tileID)
	

var dead = false
func playerDies():
	if dead:
		return
	dead = true
	
	# Remove the current level
	var root = get_tree().get_root()
	var world = root.get_node("World")
	var level = world.get_node("Level0")
	root.remove_child(level)
	level.call_deferred("free")
	var unicornLive = self.get_parent().get_node("Player1").isAlive
	var dragonLive = self.get_parent().get_node("Player2").isAlive

	# Add the next level
	var gameOver = load("res://GameOver/ColorRect.tscn").instance()
	gameOver.test(dragonLive, unicornLive)
	root.add_child(gameOver)
	
	#get_tree().current_scene.replace_by(gameOver)
