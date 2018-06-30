extends ColorRect

func _ready():
	$unicorn.winScreen = true
	$unicorn/Node2D/AnimationPlayer.play('winning')
	
	$Dragon.winScreen = true
	$Dragon/Node2D/AnimationPlayer.play('winning')
