extends ColorRect

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

func test(dragon, unicorn):
	if dragon:
		var new_texture = ImageTexture.new()
		new_texture.load("res://Player/cry_dragon.png")
		self.get_node("TextureRect").texture = new_texture
	if unicorn:
		var new_texture = ImageTexture.new()
		new_texture.load("res://Player/cry_unicorn.png")
		self.get_node("TextureRect2").texture = new_texture