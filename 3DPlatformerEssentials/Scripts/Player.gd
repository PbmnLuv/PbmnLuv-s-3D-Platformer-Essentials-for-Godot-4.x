class_name Player
extends CharacterBody3D

###
#read the ReadMe for full instructions!!
###
@export var maxSpeed: float = 15.0
@export var acceleration: float = 300.0
@export var breakSpeed: float = 2000.0
@export var default_gravity: float = 120.0
@onready var gravity: float = 120.0
@export var hold_gravity: float = 80.0

@export var Camera: Camera3D

@onready var jump_amount: int = 1
@export var default_jump_amount: int = 1
@export var jump_impulse: float = 28.0

enum CoyoteTimeModes {
	
	ZERO,
	TIMING,
	INFINITE,
}

@export var coyoteTimeMode: CoyoteTimeModes

@onready var speed: float = 0.0
@onready var groundPoint = null
@onready var jumpPoint = null
@onready var temp_vel = Vector3.ZERO
@onready var last_temp_vel = Vector3.ZERO
@onready var analog_limit = 0.0
@onready var isWallJumping = false
@onready var supposed_speed_x = 0
@onready var supposed_speed_z = 0

@export var smooth_turn: bool = true

@onready var desired_rotation_y : float = 0.0
@onready var coyoteTimer: float = 0.0
@export var coyoteTimeLimit: float = 1000 #in milliseconds

func _physics_process(delta):
	
	_updateGravity(delta)
		
	_updatePlayer(delta)
	
	
	pass


func _updatePlayer(delta):

	if Input.is_action_just_pressed("Reset"):
		get_tree().call_deferred("reload_current_scene")
		
	
		
	if Camera.type == 0:
		#TANK TYPE
		var up_strength = Input.get_action_strength("UpJoy")
		if Input.is_action_pressed("UpJoy"):
			speed += acceleration*delta
			if speed >= maxSpeed*up_strength:
				speed = maxSpeed*up_strength
			var temp_vel = Vector3(-sin(rotation.y),0,-cos(rotation.y)).normalized()
			
			velocity = Vector3(temp_vel.x*speed, velocity.y, temp_vel.z*speed)
			
		elif Input.is_action_pressed("LeftJoy"):
			rotation.y += delta*Camera.tank_cam_speed
		elif Input.is_action_pressed("RightJoy"):
			rotation.y -= delta*Camera.tank_cam_speed
		else:
			velocity = Vector3(0,velocity.y,0)
		pass
	elif (Camera.type == 1 or Camera.type == 2 or Camera.type == 3 or Camera.type == 4) and isWallJumping == false:
		#MANUAL TYPE
		var right_strength = Input.get_action_strength("RightJoy")
		var left_strength = Input.get_action_strength("LeftJoy")
		var down_strength = Input.get_action_strength("DownJoy")
		var up_strength = Input.get_action_strength("UpJoy")
		
		var action_strength_vec = Vector2.ZERO
		
		temp_vel = Vector3.ZERO
		if Input.is_action_pressed("RightJoy"):
			action_strength_vec.x += right_strength
			temp_vel += Vector3(-sin(Camera.horizontal_angle-PI/2), 0, -cos(Camera.horizontal_angle-PI/2))*right_strength
		elif Input.is_action_pressed("LeftJoy"):
			action_strength_vec.x += left_strength
			temp_vel += Vector3(-sin(Camera.horizontal_angle+PI/2), 0, -cos(Camera.horizontal_angle+PI/2))*left_strength
			pass
			
		if Input.is_action_pressed("DownJoy"):
			action_strength_vec.y += down_strength
			temp_vel += Vector3(-sin(Camera.horizontal_angle+PI), 0, -cos(Camera.horizontal_angle+PI))*down_strength
		elif Input.is_action_pressed("UpJoy"):
			action_strength_vec.y += up_strength
			temp_vel += Vector3(-sin(Camera.horizontal_angle), 0, -cos(Camera.horizontal_angle))*up_strength
			pass
		
		
		
		temp_vel = temp_vel.normalized()
		
		if temp_vel.length() > 0.05:
			last_temp_vel = temp_vel
		
		
		analog_limit = action_strength_vec.length()
		
		if temp_vel.length() > 0.05:	
			speed += acceleration*delta
			if speed >= maxSpeed*analog_limit:
				speed = maxSpeed*analog_limit
				
			
			velocity = Vector3(temp_vel.x*speed, velocity.y, temp_vel.z*speed)
			if smooth_turn:
				desired_rotation_y = -Vector2(velocity.x, velocity.z).angle()-PI/2
				rotation.y -= 10*angle_difference(desired_rotation_y, rotation.y)*delta
			else:
				rotation.y = -Vector2(velocity.x, velocity.z).angle()-PI/2
		else:
			speed -= breakSpeed*delta
			if speed <= 0:
				speed = 0.0	
				analog_limit = 0.0	
					
			velocity = Vector3(last_temp_vel.x*speed, velocity.y, last_temp_vel.z*speed)
		
		
		pass
	
	jumpUpdate(delta)
	
		#groundPoint = position
	if isWallJumping == false:
		supposed_speed_x = velocity.x
		supposed_speed_z = velocity.z
		
	move_and_slide()
	
	if $RayCast3D.is_colliding() and is_on_floor():
		groundPoint = $RayCast3D.get_collision_point()
	
	pass

func jumpUpdate(delta):
	if coyoteTimeMode == CoyoteTimeModes.INFINITE:
		if Input.is_action_just_pressed("Jump") and jump_amount > 0:# and is_on_floor():
			velocity.y = jump_impulse
			rotation = Vector3(0,rotation.y,0)
			jump_amount -= 1
	elif coyoteTimeMode == CoyoteTimeModes.ZERO:
		if ( Input.is_action_just_pressed("Jump") and jump_amount > 0 and is_on_floor() ) or (Input.is_action_just_pressed("Jump") and jump_amount > 1 and is_on_floor() == false):# and is_on_floor():
			velocity.y = jump_impulse
			rotation = Vector3(0,rotation.y,0)
			if is_on_floor():
				pass
			else:
				jump_amount -= 1
	elif coyoteTimeMode == CoyoteTimeModes.TIMING:
		
		if is_on_floor() == false:
			coyoteTimer += delta
			if coyoteTimer >= coyoteTimeLimit/1000.0 and jump_amount == default_jump_amount:
				jump_amount -= 1
			pass
		else:
			coyoteTimer = 0.0
			pass
		
		if Input.is_action_just_pressed("Jump") and jump_amount > 0:# and is_on_floor():
			velocity.y = jump_impulse
			rotation = Vector3(0,rotation.y,0)
			jump_amount -= 1
		pass
			
func _updateGravity(delta):
	

	if Input.is_action_pressed("Jump"):
		gravity = hold_gravity
	else:
		gravity = default_gravity
		pass
	
	velocity.y -= gravity * delta
	
	
	if jumpPoint != null:
		if position.y < jumpPoint.y:
			jumpPoint.y = position.y
	
	if is_on_floor():
		velocity.y = 0
		jump_amount = default_jump_amount
		isWallJumping = false
		
		if jumpPoint != null:
			if jumpPoint.y < position.y + 0.0001 and jumpPoint.y > position.y - 0.0001:
				jumpPoint = position
			else:
				if jumpPoint.y < position.y:
					var jpDif = position.y - jumpPoint.y
					jumpPoint.y += jpDif * delta * 1
					
					
					pass
				pass
		else:
			jumpPoint = position
	
	pass
	
