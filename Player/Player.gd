tool
extends RigidBody2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

enum MovementState {
	STANDING,
	WALKING,
	JUMPING,
	FALLING
}

export (NodePath) var mapPath

export (int) var playerId = 1
export (int) var movementVelocity = 100
export (int) var jumpVelocity = 200
export (String, "white", "black", "red", "magenta", \
				"blue", "cyan", "green", "yellow") var startColor = "green"
				

var paintColor = Color(1.0, 0.0, 1.0) setget setPaintColor, getPaintColor

var upDirection
var inputMovementDirection
var movementState = MovementState.STANDING
var currentLinearVelocity
var screenDims = OS.get_real_window_size()
const marginToScreenWidth = 50

const STUCK_COLLISION_AVOIDANCE_DISTANCE = 0.1

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	if playerId == 1:
		upDirection = Vector2(0, -1)
	else:
		upDirection = Vector2(0, 1)
	add_to_group("player")
	setPaintColor(Colors.color_name_to_rgb(startColor))

func currentMovementState():
	if onFloor():
		if inputMovementDirection == Vector2(0, 0):
			return MovementState.STANDING
		else:
			return MovementState.WALKING
	elif currentLinearVelocity.y * upDirection.y > 0:
		return MovementState.JUMPING
	else:
		return MovementState.FALLING

func processAnimation():
	if inputMovementDirection.x > 0:
		$Node2D.scale.x = 1
	else:
		$Node2D.scale.x = -1
	var nextMovementState = currentMovementState()
	
	if movementState == MovementState.FALLING && (nextMovementState == MovementState.STANDING || nextMovementState == MovementState.WALKING):
		$sounds/landing.play()
	
	if movementState != nextMovementState:
		movementState = nextMovementState
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
		$Node2D/AnimationPlayer.play(animationName)
	if movementState == MovementState.WALKING && !$sounds/walking.playing:
		$sounds/walking.play()

func _process(delta):
	processAnimation()
	disposeColor()

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
	
func paintBlock(tilePos):
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
			paintBlock(newTilePos)
	else:			
		var tileName = Colors.rgb_to_color_name(newColor).capitalize() + "Block"
		var tileId = map.tile_set.find_tile_by_name(tileName)
		map.set_cellv(tilePos, tileId)
		
	
func disposeColor():
	if Input.is_action_just_pressed('player' + String(playerId) + '_crouch') and onFloor():
		var map = get_node(mapPath)
		var colPos = $CollisionShape2D.position
		var pos = position
		var playerPos = position + $CollisionShape2D.position
		var playerExt = $CollisionShape2D.shape.extents
		var verticalHalfTileExtent = map.cell_size.y * 0.5
		var playerBottomPosition = playerPos + Vector2(0, -upDirection.y * playerExt.y)
		var tilePoint = playerBottomPosition + Vector2(0, -upDirection.y * verticalHalfTileExtent)
		var tilePos = map.world_to_map(tilePoint)
		paintBlock(tilePos)
		if $sounds/stomp.get_playback_position() > 0.2 || !$sounds/stomp.playing:
			$sounds/stomp.play()


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
	var velocity = Vector2(0, 0)
	if (requestsJump() && onFloor()):
		velocity += upDirection * jumpVelocity
		$sounds/jump.play()
	inputMovementDirection = correctMovementAccordingToViewport(movementDirectionFromInput())
	velocity += inputMovementDirection * movementVelocity
	state.linear_velocity += velocity
	state.linear_velocity.x = clamp(state.linear_velocity.x, -movementVelocity, movementVelocity)
	stuckAvoidance(state)
	currentLinearVelocity = state.linear_velocity	
		
func playerDies():
	pass
	
	
