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

const FLOOR_COLLISION_AVOIDANCE_DISTANCE = 0.1

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
	if movementState != nextMovementState:
		movementState = nextMovementState
		var animationName
		match movementState:
			MovementState.STANDING:
				animationName = "standing"
			MovementState.WALKING:
				animationName = "walking"
			MovementState.JUMPING:
				animationName = "jumping"
			MovementState.FALLING:
				animationName = "falling"
		$Node2D/AnimationPlayer.play(animationName)
			

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
	
func disposeColor():
	if Input.is_action_pressed('player' + String(playerId) + '_crouch') and onFloor():
		var map = get_node(mapPath)
		var colPos = $CollisionShape2D.position
		var pos = position
		var playerPos = position + $CollisionShape2D.position
		var playerExt = $CollisionShape2D.shape.extents
		var verticalHalfTileExtent = map.cell_size.y * 0.5
		var playerBottomPosition = playerPos + Vector2(0, -upDirection.y * playerExt.y)
		var tilePoint = playerBottomPosition + Vector2(0, -upDirection.y * verticalHalfTileExtent)
		var tilePos = map.world_to_map(tilePoint)
		var currentTileIndex = map.get_cellv(tilePos)
		map.set_cellv(tilePos, Colors.color_name_to_tile_index(getPaintColor()))
		

func _integrate_forces(state):
	var velocity = Vector2(0, 0)
	if (requestsJump() && onFloor()):
		velocity += upDirection * jumpVelocity
		$sounds/jump.play()
	inputMovementDirection = movementDirectionFromInput()
	velocity += inputMovementDirection * movementVelocity
	state.linear_velocity += velocity
	state.linear_velocity.x = clamp(state.linear_velocity.x, -movementVelocity, movementVelocity)
	currentLinearVelocity = state.linear_velocity
	if (onFloor()):
		state.transform.origin += upDirection * FLOOR_COLLISION_AVOIDANCE_DISTANCE
		
func playerDies():
	pass
	
	
