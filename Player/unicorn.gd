tool
extends KinematicBody2D

export (Color) var particlesColor setget setParticlesColor, getParticlesColor

func setParticlesColor(color):
	particlesColor = color
	$colorStomp.process_material.color = color
	$colorParticles.process_material.color = color

func getParticlesColor():
	return particlesColor