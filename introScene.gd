extends Node2D

func _ready():
	$AnimationPlayer.play("visible")
	
	$Dragon/Node2D/AnimationPlayer.play('walking')
	$unicorn/Node2D/AnimationPlayer.play('walking')
	
	yield(get_tree().create_timer(24), "timeout")
	get_tree().change_scene("res://World/World.tscn")