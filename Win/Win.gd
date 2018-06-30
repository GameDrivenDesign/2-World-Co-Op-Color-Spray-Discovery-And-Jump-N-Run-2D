extends ColorRect

func _ready():
	print("HI")
	$unicorn/Node2D/AnimationPlayer.play('winning')
