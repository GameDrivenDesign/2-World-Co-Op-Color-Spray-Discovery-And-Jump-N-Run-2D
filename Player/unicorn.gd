tool
extends "res://Player/Player.gd"

export (Color) var particlesColor setget setParticlesColor, getParticlesColor

func setParticlesColor(color):
	particlesColor = color
	$colorStomp.process_material.color = color
	$colorParticles.process_material.color = color

func getParticlesColor():
	return particlesColor