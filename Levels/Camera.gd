extends Node2D

export (NodePath) var player1_path
export (NodePath) var player2_path

var player1 = null
var player2 = null

const BEFORE_REACHING_SIDE_ZOOM_FACTOR = 1.5
const MIN_ZOOM_FACTOR = 0.8
const MAX_ZOOM_FACTOR = 2.0

func _ready():
	player1 = get_node(player1_path)
	player2 = get_node(player2_path)

func _process(delta):
	var p1 = player1.global_position
	var p2 = player2.global_position
	var screen_size = get_viewport().size
	
	var middle = (p1 + p2) / 2
	var distance = (p1 - p2).abs()
	
	# Move the camera left and right, but never move it vertically.
	self.global_position.x = middle.x
	
	# Zoom the camera. Bigger zoom factors leads to zooming out.
	# The lower bound zoom is set to MIN_ZOOM_FACTOR, so that we never zoom nearer than initially. 
	var zoom = distance / screen_size * BEFORE_REACHING_SIDE_ZOOM_FACTOR
	var zoom_factor = min(max(max(zoom.x, zoom.y), MIN_ZOOM_FACTOR), MAX_ZOOM_FACTOR)
	$Camera.zoom = Vector2(zoom_factor, zoom_factor)
	