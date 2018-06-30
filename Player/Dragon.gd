extends "res://Player/Player.gd"


func _ready():
	$Node2D.scale.y = -1
	$CollisionShape2D.position.y = -5
	._ready()

