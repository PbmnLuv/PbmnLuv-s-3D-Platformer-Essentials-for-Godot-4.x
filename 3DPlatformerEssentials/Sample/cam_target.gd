extends Node3D

@onready var TargetFinal = get_parent().get_parent().get_node("CamTargetFinal")
@onready var PlayerNode = get_parent().get_parent()
@onready var Camera = get_tree().get_root().get_node("World/Camera")



func _ready():
	position = get_parent().get_parent().position

func _physics_process(delta):
	
	var finalPos: Vector3 = TargetFinal.global_position
	
	var dif: Vector3 = finalPos - position
	
	
	#if dif.length() > 2.0:
	#position += delta * 10 * dif
	
	position += Vector3(delta * 10 * dif.x, delta * 10 * (Camera.default_radius/Camera.init_radius)/2.0 * dif.y, delta * 10 * dif.z)
	
	
	
	pass
