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

export (int) var playerId = 1
export (int) var movementVelocity = 100
export (int) var jumpVelocity = 200

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

func _process(delta):
	if playerId != 1:
		return
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
		$AnimationPlayer.play(animationName)
			


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

func _integrate_forces(state):
	var velocity = Vector2(0, 0)
	if (requestsJump() && onFloor()):
		velocity += upDirection * jumpVelocity
	inputMovementDirection = movementDirectionFromInput()
	velocity += inputMovementDirection * movementVelocity
	state.linear_velocity += velocity
	state.linear_velocity.x = clamp(state.linear_velocity.x, -movementVelocity, movementVelocity)
	currentLinearVelocity = state.linear_velocity
	if (onFloor()):
		state.transform.origin += upDirection * FLOOR_COLLISION_AVOIDANCE_DISTANCE
	
	