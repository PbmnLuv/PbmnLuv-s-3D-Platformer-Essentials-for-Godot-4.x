extends Camera3D

@export var PlayerNode: Node3D
@export var TargetNode: Node3D

enum CameraTypes {
	
	TANK, #fixed behind
	MANUAL, #100% manual
	AUTOMATIC, #100% automatic
	HYBRID, #automatic and manual
	RETRO, #retro style cam
}

enum JumpFollowTypes {
	
	TOTAL,
	PERCENTAGE,
	ZERO,
	#THRESHOLD, #not finished yet
	
}

@export var type: CameraTypes = CameraTypes.HYBRID
@export var jumpFollow: JumpFollowTypes = JumpFollowTypes.TOTAL
@export var jumpFollowPercentage: float = 0.5


###
#read the ReadMe for full instructions!!
###
@onready var desiredPosition: Vector3 = Vector3(0,2.5,0)

@export var tank_cam_speed: float = 3.0

@onready var manual_rotation_speed: float = 0.0
@onready var manual_rotation_speed_vert: float = 0.0
@export var manual_rotation_max_speed: float = 5.0
@export var manual_rotation_acceleration: float = 1000.0


@export var isAutomaticCameraActive: bool = false

@onready var automatic_rotation_speed: float = 0.0
@export var automatic_rotation_max_speed: float = 5.0
@export var automatic_rotation_acceleration: float = 1000.0
@export var reset_cam_speed: float = 5.0

@export var automatic_rotation_sensitivity: float = 1.0
@export var manual_rotation_sensitivity: float = 1.0
@export var retro_rotation_sensitivity: float = 5.0
@export var retro_rotation_breakSpeed: float = 5.0

@export var default_radius: float = 20.0
@export var default_height: float = 3.0

@export var invert_cam_x: bool = false
@export var invert_cam_y: bool = false

@onready var horizontal_angle: float = PI
@onready var vertical_angle: float = 0.5

@export var vertical_adjust_speed: float = 8.0
@export var water_vertical_adjust_speed: float = 4.5

@onready var toResetCam: bool = false
@onready var startResetAngle = 0.0
@onready var targetResetAngle = 0.0

#NOT USEFUL
@onready var SolidObjects: Array = []

@export var isOcclusionDetectionActive: bool = true

@onready var cameraRestrictionRadiusAmount: float = 0.0
@onready var blockUpDownCam: bool = false

@export var default_retroRotateAmount: float = 2*PI/8.0
@onready var retroRotateAmount: float = 0.0


var toRotate
var init_radius

func _ready():
	
	init_radius = default_radius
	
	
	pass

func update_occlusion_rays(delta):
	
	
	if isOcclusionDetectionActive:
		
		$FrontRay.look_at(PlayerNode.position)
		
		if $FrontRay.is_colliding() and $FrontRay.get_collision_point().distance_to(self.global_position) < self.global_position.distance_to(PlayerNode.global_position):
			default_radius -= 10*delta
			cameraRestrictionRadiusAmount += 10*delta*$FrontRay.get_collision_point().distance_to(self.global_position)*delta*$FrontRay.get_collision_point().distance_to(self.global_position)
			blockUpDownCam = true
			if default_radius <= 1.0:
				default_radius = 1.0
			pass
		#else:
			#blockUpDownCam = false
		
		pass
		
		if  ($BackRay.is_colliding() and self.global_position.distance_to($BackRay.get_collision_point()) > 2):
			if not ($FrontRay.is_colliding() and $FrontRay.get_collision_point().distance_to(self.global_position) < self.global_position.distance_to(PlayerNode.global_position)):
				#if cameraRestrictionRadiusAmount > 0.0:
				if default_radius < 6.0:
					cameraRestrictionRadiusAmount -= 10*delta*self.global_position.distance_to($BackRay.get_collision_point())*delta*self.global_position.distance_to($BackRay.get_collision_point())
					default_radius += 10*delta
		elif $BackRay.is_colliding() == false or self.global_position.distance_to($BackRay.get_collision_point()) > 0.5:
			blockUpDownCam = false		
			if default_radius < 6.0 and not($FrontRay.is_colliding() and $FrontRay.get_collision_point().distance_to(self.global_position) < self.global_position.distance_to(PlayerNode.global_position)):
					#cameraRestrictionRadiusAmount -= 10*delta*self.global_position.distance_to($BackRay.get_collision_point())*delta*self.global_position.distance_to($BackRay.get_collision_point())
					default_radius += 10*delta
			
			#pass
		
		if $DownRay.is_colliding() and $DownRay.get_collision_point().distance_to(self.global_position) < 0.1:
			vertical_angle += 10*delta
			blockUpDownCam = true
		else:
			blockUpDownCam = false
	
	
	pass

func update_cam_movement(delta):
	
	update_occlusion_rays(delta)
	
	if type == CameraTypes.TANK:
		position = PlayerNode.position + Vector3(sin(PlayerNode.rotation.y)*default_radius,default_height,cos(PlayerNode.rotation.y)*default_radius)
		look_at_from_position(position, PlayerNode.position)
		pass
	elif type == CameraTypes.MANUAL:
		var right_strength = Input.get_action_strength("CamRight")
		var left_strength = Input.get_action_strength("CamLeft")
		var up_strength = Input.get_action_strength("CamUp")
		var down_strength = Input.get_action_strength("CamDown")
		if toResetCam == false:
			if Input.is_action_pressed("CamRight"):
				manual_rotation_speed += manual_rotation_acceleration*delta
				if manual_rotation_speed >= manual_rotation_max_speed:
					manual_rotation_speed = manual_rotation_max_speed
					
				if invert_cam_x:
					horizontal_angle -= delta*manual_rotation_speed*right_strength*manual_rotation_sensitivity
				else:
					horizontal_angle += delta*manual_rotation_speed*right_strength*manual_rotation_sensitivity
			elif Input.is_action_pressed("CamLeft"):
				manual_rotation_speed -= manual_rotation_acceleration*delta
				if manual_rotation_speed <= -manual_rotation_max_speed:
					manual_rotation_speed = -manual_rotation_max_speed
					
				if invert_cam_x:
					horizontal_angle -= delta*manual_rotation_speed*left_strength*manual_rotation_sensitivity
				else:
					horizontal_angle += delta*manual_rotation_speed*left_strength*manual_rotation_sensitivity
				
				pass
			if horizontal_angle > 2*PI:
				horizontal_angle -= 2*PI
			elif horizontal_angle < 0:
				horizontal_angle += 2*PI
		else:
			#is resetting camera
			
			if toRotate >= 0:
				horizontal_angle += reset_cam_speed*delta
				toRotate -= reset_cam_speed*delta
				if toRotate < 0.0:
					toRotate = 0.0
					toResetCam = false
				pass
			elif toRotate < 0:
				horizontal_angle -= reset_cam_speed*delta
				toRotate += reset_cam_speed*delta
				if toRotate > 0.0:
					toRotate = 0.0
					toResetCam = false
			
			pass
			
			
		if Input.is_action_just_pressed("ResetCam") and toResetCam == false:
			toResetCam = true
			startResetAngle = rotation.y
			targetResetAngle = PlayerNode.rotation.y
			toRotate = angle_difference(rotation.y, targetResetAngle)
					
		if Input.is_action_pressed("CamDown") and blockUpDownCam == false:
			manual_rotation_speed_vert -= manual_rotation_acceleration*delta
			if manual_rotation_speed_vert <= -manual_rotation_max_speed:
				manual_rotation_speed_vert = -manual_rotation_max_speed
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
			else:
				vertical_angle += delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
		
			if vertical_angle < 0.2:
				vertical_angle = 0.2
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
		elif Input.is_action_pressed("CamUp") and blockUpDownCam == false:
			manual_rotation_speed_vert += manual_rotation_acceleration*delta
			if manual_rotation_speed_vert >= manual_rotation_max_speed:
				manual_rotation_speed_vert = manual_rotation_max_speed
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
			else:
				vertical_angle += delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
		
			if vertical_angle < 0.2:
				vertical_angle = 0.2
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
		
			
				
			
			pass
		update_jump_follow(delta)
	elif type == CameraTypes.AUTOMATIC:
		var right_strength = Input.get_action_strength("RightJoy")
		var left_strength = Input.get_action_strength("LeftJoy")
		var up_strength = Input.get_action_strength("CamUp")
		var down_strength = Input.get_action_strength("CamDown")
		if toResetCam == false:
			if Input.is_action_pressed("RightJoy"):
				automatic_rotation_speed += automatic_rotation_acceleration*delta
				if automatic_rotation_speed >= automatic_rotation_max_speed:
					automatic_rotation_speed = automatic_rotation_max_speed
					
				if invert_cam_x:
					horizontal_angle -= delta*automatic_rotation_speed*right_strength*automatic_rotation_sensitivity
				else:
					horizontal_angle += delta*automatic_rotation_speed*right_strength*automatic_rotation_sensitivity
			elif Input.is_action_pressed("LeftJoy"):
				automatic_rotation_speed -= automatic_rotation_acceleration*delta
				if automatic_rotation_speed <= -automatic_rotation_max_speed:
					automatic_rotation_speed = -automatic_rotation_max_speed
					
				if invert_cam_x:
					horizontal_angle -= delta*automatic_rotation_speed*left_strength*automatic_rotation_sensitivity
				else:
					horizontal_angle += delta*automatic_rotation_speed*left_strength*automatic_rotation_sensitivity
				
				pass
			if horizontal_angle > 2*PI:
				horizontal_angle -= 2*PI
			elif horizontal_angle < 0:
				horizontal_angle += 2*PI
		else:
			#is resetting camera
			
			if toRotate >= 0:
				horizontal_angle += reset_cam_speed*delta
				toRotate -= reset_cam_speed*delta
				if toRotate < 0.0:
					toRotate = 0.0
					toResetCam = false
				pass
			elif toRotate < 0:
				horizontal_angle -= reset_cam_speed*delta
				toRotate += reset_cam_speed*delta
				if toRotate > 0.0:
					toRotate = 0.0
					toResetCam = false
			
			pass
			
			
		if Input.is_action_just_pressed("ResetCam") and toResetCam == false:
			toResetCam = true
			startResetAngle = rotation.y
			targetResetAngle = PlayerNode.rotation.y
			toRotate = angle_difference(rotation.y, targetResetAngle)
					
		if Input.is_action_pressed("CamDown") and blockUpDownCam == false:
			manual_rotation_speed_vert -= manual_rotation_acceleration*delta
			if manual_rotation_speed_vert <= -manual_rotation_max_speed:
				manual_rotation_speed_vert = -manual_rotation_max_speed
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
			else:
				vertical_angle += delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
		
			if vertical_angle < 0.2:
				vertical_angle = 0.2
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
		elif Input.is_action_pressed("CamUp")and blockUpDownCam == false:
			manual_rotation_speed_vert += manual_rotation_acceleration*delta
			if manual_rotation_speed_vert >= manual_rotation_max_speed:
				manual_rotation_speed_vert = manual_rotation_max_speed
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
			else:
				vertical_angle += delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
		
			if vertical_angle < 0.2:
				vertical_angle = 0.2
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
		
		update_jump_follow(delta)
		
		
	elif type == CameraTypes.HYBRID:
		
		var right_strength = Input.get_action_strength("CamRight")
		var left_strength = Input.get_action_strength("CamLeft")
		var right_strength_auto = Input.get_action_strength("RightJoy")
		var left_strength_auto = Input.get_action_strength("LeftJoy")
		var up_strength = Input.get_action_strength("CamUp")
		var down_strength = Input.get_action_strength("CamDown")
		if toResetCam == false:
			#if Input.is_action_pressed("RightJoy") or Input.is_action_pressed("CamRight"):
			if Input.is_action_pressed("RightJoy"):
				automatic_rotation_speed += automatic_rotation_acceleration*delta
				if automatic_rotation_speed >= automatic_rotation_max_speed:
					automatic_rotation_speed = automatic_rotation_max_speed
			elif Input.is_action_pressed("LeftJoy"):
				automatic_rotation_speed -= automatic_rotation_acceleration*delta
				if automatic_rotation_speed <= -automatic_rotation_max_speed:
					automatic_rotation_speed = -automatic_rotation_max_speed
					
			if Input.is_action_pressed("CamRight"):
				manual_rotation_speed += manual_rotation_acceleration*delta
				if manual_rotation_speed >= manual_rotation_max_speed:
					manual_rotation_speed = manual_rotation_max_speed
			elif Input.is_action_pressed("CamLeft"):
				manual_rotation_speed -= manual_rotation_acceleration*delta
				if manual_rotation_speed <= -manual_rotation_max_speed:
					manual_rotation_speed = -manual_rotation_max_speed
		
			
			var lstick_amount
			var rstick_amount
			
			if left_strength_auto > right_strength_auto:
				lstick_amount = left_strength_auto
			else:
				lstick_amount = right_strength_auto
				
			if left_strength > right_strength:
				rstick_amount = left_strength
			else:
				rstick_amount = right_strength
			
			if invert_cam_x:
				
				horizontal_angle += -delta*automatic_rotation_speed*lstick_amount*automatic_rotation_sensitivity + delta*manual_rotation_speed*rstick_amount*manual_rotation_sensitivity
			else:
				horizontal_angle += -delta*automatic_rotation_speed*lstick_amount*automatic_rotation_sensitivity + delta*manual_rotation_speed*rstick_amount*manual_rotation_sensitivity
					
			
			if horizontal_angle > 2*PI:
				horizontal_angle -= 2*PI
			elif horizontal_angle < 0:
				horizontal_angle += 2*PI
		else:
			#is resetting camera
			
			if toRotate >= 0:
				horizontal_angle += reset_cam_speed*delta
				toRotate -= reset_cam_speed*delta
				if toRotate < 0.0:
					toRotate = 0.0
					toResetCam = false
				pass
			elif toRotate < 0:
				horizontal_angle -= reset_cam_speed*delta
				toRotate += reset_cam_speed*delta
				if toRotate > 0.0:
					toRotate = 0.0
					toResetCam = false
			
			pass
			
			
		if Input.is_action_just_pressed("ResetCam") and toResetCam == false:
			toResetCam = true
			startResetAngle = rotation.y
			targetResetAngle = PlayerNode.rotation.y
			toRotate = angle_difference(rotation.y, targetResetAngle)
					
		if Input.is_action_pressed("CamDown") and blockUpDownCam == false:
			manual_rotation_speed_vert -= manual_rotation_acceleration*delta
			if manual_rotation_speed_vert <= -manual_rotation_max_speed:
				manual_rotation_speed_vert = -manual_rotation_max_speed
				
			
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity < 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
				
			else:
				vertical_angle += delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity > 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
			if vertical_angle < 0.2:
				vertical_angle = 0.2
				default_radius -= delta*8.0
				if default_radius < 6:
					default_radius = 6
				
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
				
		elif Input.is_action_pressed("CamUp") and blockUpDownCam == false:
			manual_rotation_speed_vert += manual_rotation_acceleration*delta
			if manual_rotation_speed_vert >= manual_rotation_max_speed:
				manual_rotation_speed_vert = manual_rotation_max_speed
						
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity < 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
				
			else:
				vertical_angle += delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity > 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
				
			if vertical_angle < 0.2:
				vertical_angle = 0.2
				default_radius -= delta*8.0
				if default_radius < 6:
					default_radius = 6
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
				
		
		update_jump_follow(delta)
		
			
		pass
	
	elif type == CameraTypes.RETRO:
		
		
		var right_strength = Input.get_action_strength("CamRight")
		var left_strength = Input.get_action_strength("CamLeft")
		var right_strength_auto = Input.get_action_strength("RightJoy")
		var left_strength_auto = Input.get_action_strength("LeftJoy")
		var up_strength = Input.get_action_strength("CamUp")
		var down_strength = Input.get_action_strength("CamDown")
		var retro_speed = 0.0
		if toResetCam == false:
			#if Input.is_action_pressed("RightJoy") or Input.is_action_pressed("CamRight"):
			if Input.is_action_pressed("RightJoy"):
				automatic_rotation_speed += automatic_rotation_acceleration*delta
				if automatic_rotation_speed >= automatic_rotation_max_speed:
					automatic_rotation_speed = automatic_rotation_max_speed
			elif Input.is_action_pressed("LeftJoy"):
				automatic_rotation_speed -= automatic_rotation_acceleration*delta
				if automatic_rotation_speed <= -automatic_rotation_max_speed:
					automatic_rotation_speed = -automatic_rotation_max_speed
					
			if Input.is_action_just_pressed("CamRight"):
				if invert_cam_x:
					retroRotateAmount = default_retroRotateAmount
				else:
					retroRotateAmount = -default_retroRotateAmount
				pass
			elif Input.is_action_just_pressed("CamLeft"):
				if invert_cam_x:
					retroRotateAmount =-default_retroRotateAmount
				else:
					retroRotateAmount = default_retroRotateAmount
				pass
		
			
			var lstick_amount
			var rstick_amount
			
			if left_strength_auto > right_strength_auto:
				lstick_amount = left_strength_auto
			else:
				lstick_amount = right_strength_auto
				
			
			
			
			if invert_cam_x:
				horizontal_angle += -delta*automatic_rotation_speed*lstick_amount*automatic_rotation_sensitivity
				horizontal_angle += delta*retroRotateAmount*retro_rotation_sensitivity
				retroRotateAmount -= delta*retroRotateAmount*retro_rotation_breakSpeed
				if retroRotateAmount < 0.05 and retroRotateAmount > -0.05:
					retroRotateAmount = 0.0
			else:
				horizontal_angle += -delta*automatic_rotation_speed*lstick_amount*automatic_rotation_sensitivity
				horizontal_angle += delta*retroRotateAmount*retro_rotation_sensitivity
				retroRotateAmount -= delta*retroRotateAmount*retro_rotation_breakSpeed
				if retroRotateAmount < 0.05 and retroRotateAmount > -0.05:
					retroRotateAmount = 0.0
			
			if horizontal_angle > 2*PI:
				horizontal_angle -= 2*PI
			elif horizontal_angle < 0:
				horizontal_angle += 2*PI
		else:
			#is resetting camera
			
			if toRotate >= 0:
				horizontal_angle += reset_cam_speed*delta
				toRotate -= reset_cam_speed*delta
				if toRotate < 0.0:
					toRotate = 0.0
					toResetCam = false
				pass
			elif toRotate < 0:
				horizontal_angle -= reset_cam_speed*delta
				toRotate += reset_cam_speed*delta
				if toRotate > 0.0:
					toRotate = 0.0
					toResetCam = false
			
			pass
			
			
		if Input.is_action_just_pressed("ResetCam") and toResetCam == false:
			toResetCam = true
			startResetAngle = rotation.y
			targetResetAngle = PlayerNode.rotation.y
			toRotate = angle_difference(rotation.y, targetResetAngle)
					
		if Input.is_action_pressed("CamDown") and blockUpDownCam == false:
			manual_rotation_speed_vert -= manual_rotation_acceleration*delta
			if manual_rotation_speed_vert <= -manual_rotation_max_speed:
				manual_rotation_speed_vert = -manual_rotation_max_speed
				
			
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity < 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
				
			else:
				vertical_angle += delta*manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity > 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
			if vertical_angle < 0.2:
				vertical_angle = 0.2
				default_radius -= delta*8.0
				if default_radius < 6:
					default_radius = 6
				
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
				
		elif Input.is_action_pressed("CamUp") and blockUpDownCam == false:
			manual_rotation_speed_vert += manual_rotation_acceleration*delta
			if manual_rotation_speed_vert >= manual_rotation_max_speed:
				manual_rotation_speed_vert = manual_rotation_max_speed
						
				
			if invert_cam_y:
				vertical_angle -= delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity < 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
				
			else:
				vertical_angle += delta*manual_rotation_speed_vert*up_strength*manual_rotation_sensitivity
				if manual_rotation_speed_vert*down_strength*manual_rotation_sensitivity > 0:
					default_radius += delta*15.0
					if default_radius > init_radius:
						default_radius = init_radius	
				
			if vertical_angle < 0.2:
				vertical_angle = 0.2
				default_radius -= delta*8.0
				if default_radius < 6:
					default_radius = 6
			elif vertical_angle > PI/2.0:
				vertical_angle = PI/2.0
				
		
		update_jump_follow(delta)
		
			
		pass
		
		
		
		
		
		pass
	
	
	
	
	
func update_jump_follow(delta):
	if jumpFollow == JumpFollowTypes.TOTAL:
		position = TargetNode.global_position + Vector3(sin(horizontal_angle),vertical_angle,cos(horizontal_angle)).normalized()*default_radius
		look_at_from_position(position, TargetNode.global_position)
	elif jumpFollow == JumpFollowTypes.ZERO:
		if PlayerNode.groundPoint == null:
			position = Vector3(TargetNode.global_position.x,PlayerNode.position.y,TargetNode.global_position.z) + Vector3(sin(horizontal_angle),vertical_angle,cos(horizontal_angle)).normalized()*default_radius
			look_at_from_position(position, TargetNode.global_position)
		else:
			position = Vector3(TargetNode.position.x,PlayerNode.groundPoint.y,TargetNode.position.z) + Vector3(sin(horizontal_angle),vertical_angle,cos(horizontal_angle)).normalized()*default_radius
			look_at_from_position(position, Vector3(TargetNode.global_position.x,PlayerNode.groundPoint.y,TargetNode.global_position.z))
	elif jumpFollow == JumpFollowTypes.PERCENTAGE:
		if PlayerNode.jumpPoint != null:
			
			var dif = abs(TargetNode.position.y-PlayerNode.jumpPoint.y)
			var waterExtraDistMult = 1.0
			if false: 
				waterExtraDistMult = 1.8
			else:
				waterExtraDistMult = 1.0
				
			position = Vector3(TargetNode.global_position.x,self.position.y,TargetNode.global_position.z) + Vector3(sin(horizontal_angle),0,cos(horizontal_angle)).normalized()*default_radius#*waterExtraDistMult
			
			
			if false: #PlayerNode.is_on_water == false:
				desiredPosition.y = TargetNode.global_position.y+vertical_angle*default_radius - dif*jumpFollowPercentage
			else:
				desiredPosition.y = TargetNode.global_position.y+vertical_angle*default_radius
				if false: #PlayerNode.desiredWaterVertSpeed > 0:
					desiredPosition.y -= 5.0
				pass
			
			
			look_at_from_position(position, TargetNode.global_position)
		else:
			
			position = Vector3(TargetNode.global_position.x,self.position.y,TargetNode.global_position.z) + Vector3(sin(horizontal_angle),0,cos(horizontal_angle)).normalized()*default_radius
			
			desiredPosition.y = vertical_angle*default_radius+TargetNode.global_position.y
			look_at_from_position(position, TargetNode.global_position)
			
			
			
			pass
	pass
func _physics_process(delta):
	
	if PlayerNode != null:
		update_cam_movement(delta)
		
	
		var dif = desiredPosition.y - position.y
		
		if abs(dif) <= 0.01:
			desiredPosition.y = position.y
			pass
		else:
			if false:#if PlayerNode.is_on_water:
				position.y += dif*delta*water_vertical_adjust_speed#*10
			else:
				position.y += dif*delta*vertical_adjust_speed
				
				
		#if PlayerNode.is_on_floor():
			#desiredPosition.y += PlayerNode.lastMotion.y*10000
			#pass
	
	
	
	pass
