extends CharacterBody3D

var speed
var sprinting = false
var health = 3 

const MAX_STANIMA = 80
const SPRINT_SPEED = 8.0
const WALK_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003
const HEAD_STAGGER = 8.00

var stamina = MAX_STANIMA

const BOB_FREQ =2.0
const BOB_AMP = .08
var t_bob = 0.0

const BASE_FOV = 90
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

var bullet = load("res://Models/Guns/bullet.tscn")
var bullet_trail = load("res://Scenes/BulletTrail.tscn")
var instance

enum weapons {
	AUTO,
	PISTOLS
}

var weapon = weapons.PISTOLS
var can_shoot = true

signal game_over
var playing = true

@onready var weapon_switching = $Head/Camera3D/WeaponManager/WeaponSwitching

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var aim_ray = $Head/Camera3D/GunAimRay
@onready var crosshair  = $Head/Camera3D/Crosshair
@onready var hit_rect = $Head/Camera3D/HitRect
@onready var aim_ray_end = $Head/Camera3D/AimRayEnd

@onready var gun_anim = $Head/Camera3D/WeaponManager/Pistol/AnimationPlayer
@onready var gun_barrel = $Head/Camera3D/WeaponManager/Pistol/RayCast3D
@onready var gun_anim2 = $Head/Camera3D/WeaponManager/Pistol2/AnimationPlayer
@onready var gun_barrel2 = $Head/Camera3D/WeaponManager/Pistol2/RayCast3D
@onready var pistol = $Head/Camera3D/WeaponManager/Pistol
@onready var pistol2 = $Head/Camera3D/WeaponManager/Pistol2

@onready var auto_anim = $Head/Camera3D/WeaponManager/SteampunkAuto/AnimationPlayer
@onready var auto_gun = $Head/Camera3D/WeaponManager/SteampunkAuto
@onready var auto_barrel = $Head/Camera3D/WeaponManager/SteampunkAuto/Barrel

@onready var melee_weapon = $Head/Camera3D/WeaponManager/Axe
@onready var melee_aim_ray = $Head/Camera3D/MeleeAimRay

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.position.x = get_viewport().size.x / 2 - 64
	crosshair.position.y = get_viewport().size.y / 2 - 64
#	_raise_weapon(weapons.AUTO)
		
func _unhandled_input(event):
	if !(event is InputEventMouseMotion) or !playing:
		return
	head.rotate_y(-event.relative.x * SENSITIVITY)
	camera.rotate_x(-event.relative.y * SENSITIVITY)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40.0), deg_to_rad(60.0))
		
func _physics_process(delta):
	if !playing:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir = Input.get_vector("left", "right", "up", "down")
		
	#Handle sprint
	if Input.is_action_just_pressed("sprint") and not sprinting and stamina > 0 and input_dir != Vector2.ZERO:
		sprinting = true
	elif (Input.is_action_just_pressed("sprint") and sprinting) or stamina <= 0 or input_dir == Vector2.ZERO:
		sprinting = false
	
	if sprinting:
		speed = SPRINT_SPEED
		stamina -= 1
	else:
		speed = WALK_SPEED
		if stamina < 80:
			stamina += .7
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta*7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta*7.0)
	else: 
		velocity.x = lerp(velocity.x, direction.x * speed, delta*3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta*3.0)
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob) 
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED *2)
	var target_fov = BASE_FOV + FOV_CHANGE  * velocity_clamped
	
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	if Input.is_action_pressed("melee") and can_shoot:
		_melee()
		
	
	if Input.is_action_pressed("shoot") and can_shoot:
		pass
#		match weapon:
#			weapons.AUTO:
#				_shoot_auto()
#			weapons.PISTOLS:
#				_shoot_pistols()
	
#	if Input.is_action_just_pressed("weapon_one") and weapon != weapons.AUTO:
#		_lower_weapon()
#		await get_tree().create_timer(.3).timeout
#		_raise_weapon(weapons.AUTO)
#
#	if Input.is_action_just_pressed("weapon_two") and weapon != weapons.PISTOLS:
#		_lower_weapon()
#		await get_tree().create_timer(.3).timeout
#		_raise_weapon(weapons.PISTOLS)
		
	
	
			
	move_and_slide()

func _melee():
	if weapon_switching.is_playing():
		return
		
	can_shoot = false
#	_lower_weapon(2.5)
	await get_tree().create_timer(.1).timeout
	melee_weapon.visible = true
	
	if melee_aim_ray.is_colliding():
		var instance = bullet_trail.instantiate()		
		instance.init(auto_barrel.global_position, melee_aim_ray.get_collision_point())
		var hit_enemy = melee_aim_ray.get_collider().is_in_group("enemy")
		if hit_enemy:
			melee_aim_ray.get_collider().hit(150, true)
		
		get_parent().add_child(instance)
		instance.trigger_particles(	melee_aim_ray.get_collision_point(), 
							melee_aim_ray.get_collision_point(), hit_enemy)
	weapon_switching.play("Melee")
	await get_tree().create_timer(.1).timeout
	melee_weapon.visible = false
#	match weapon:
#		weapons.AUTO:
#			_raise_weapon(weapons.AUTO)
#		weapons.PISTOLS:
#			_raise_weapon(weapons.PISTOLS)
	await get_tree().create_timer(.3).timeout
	can_shoot = true
	
func  _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ /2) * BOB_AMP
	return pos
	
func hit(dir):
	if !playing:
		return
	health -= 1
	get_tree().create_timer(5).timeout.connect(regen_health)
	_player_hit()
	if is_on_floor():
		velocity += (dir * HEAD_STAGGER)
	if health <= 0:
		playing = false
		pistol.visible = false
		pistol2.visible = false
		auto_gun.visible = false
		weapon_switching.play("DeathFall")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal("game_over")
	
func _shoot_pistols():
	if !gun_anim.is_playing():
		gun_anim.play("Shoot")
		instance = bullet.instantiate()
		instance.position = gun_barrel.global_position
		get_parent().add_child(instance)
		if aim_ray.is_colliding():
			instance.set_velocity(aim_ray.get_collision_point())
		else:
			instance.set_velocity(aim_ray_end.global_position)
	if !gun_anim2.is_playing():
		gun_anim2.play("Shoot")
		instance = bullet.instantiate()
		instance.position = gun_barrel2.global_position
		get_parent().add_child(instance)
		if aim_ray.is_colliding():
			instance.set_velocity(aim_ray.get_collision_point())
		else:
			instance.set_velocity(aim_ray_end.global_position)	
		
func _shoot_auto():
	if auto_anim.is_playing():
		return
	
	auto_anim.play("Shoot")
	instance = bullet_trail.instantiate()
	if !aim_ray.is_colliding():
		instance.init(auto_barrel.global_position, aim_ray_end.global_position)
		get_parent().add_child(instance)
		return
		
	instance.init(auto_barrel.global_position, aim_ray.get_collision_point())
	var hit_enemy = aim_ray.get_collider().is_in_group("enemy")
	if hit_enemy:
		aim_ray.get_collider().hit(50, false)
	
	get_parent().add_child(instance)
	instance.trigger_particles(	aim_ray.get_collision_point(), 
						auto_barrel.global_position, hit_enemy)
				
func _player_hit():
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false
	
func _lower_weapon(speed=1):
	match weapon:
		weapons.AUTO:
			weapon_switching.play("LowerAuto", -1, speed)
		weapons.PISTOLS:
			weapon_switching.play("LowerPistols", -1, speed)

func _raise_weapon(new_weapon):
	can_shoot = false
	match new_weapon:
		weapons.AUTO:
			auto_gun.visible = true
			pistol.visible = false
			pistol2.visible = false
			weapon_switching.play_backwards("LowerAuto")
		weapons.PISTOLS:
			auto_gun.visible = false
			pistol.visible = true
			pistol2.visible = true
			weapon_switching.play_backwards("LowerPistols")
	weapon = new_weapon
	can_shoot = true
	
func regen_health():
	health += 1
	
