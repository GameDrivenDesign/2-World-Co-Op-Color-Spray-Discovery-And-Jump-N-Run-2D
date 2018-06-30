extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
func start_scene(scenePath):
	var s = ResourceLoader.load(scenePath)
	var currentScene = s.instance()
	get_tree().get_root().add_child(currentScene)
	self.queue_free()

func _on_WinArea_body_entered(body):
	if body.is_in_group("player"):
		start_scene("res://Win/Win.tscn")
