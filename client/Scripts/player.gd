extends CharacterBody3D

signal player_ready
signal game_over

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

var laser = load("res://Models/Guns/laser.tscn")
var bullet_trail = load("res://Scenes/BulletTrail.tscn")
var instance

enum weapons {
	AUTO,
	PISTOLS
}

var weapon = weapons.PISTOLS

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

#@onready var melee_weapon = $Head/Camera3D/WeaponManager/Axe
@onready var melee_aim_ray = $Head/Camera3D/MeleeAimRay

@onready var cur_weapon_label = $CurrentWeapon
@onready var cur_ammo_label = $CurrentAmmo
@onready var weapon_manager = $Head/Camera3D/WeaponManager

@onready var walking_audio = $Walking
@onready var running_audio = $Running
@onready var jump_audio = $Jump
@onready var punched = $Punched
@onready var slammed = $Slammed

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	weapon_manager.connect("update_ammo",_on_weapon_manager_update_ammo)
	weapon_manager.connect("weapon_change", _on_weapon_manager_weapon_change)
	player_ready.emit()
#	_raise_weapon(weapons.AUTO)
		
func _input(event):
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
		walking_audio.stop()
		running_audio.stop()
		jump_audio.play()
		velocity.y = JUMP_VELOCITY
		
		
	var input_dir = Input.get_vector("left", "right", "up", "down")
		
	if Input.is_action_just_pressed("sprint") and not sprinting and stamina > 0 and input_dir != Vector2.ZERO:
		sprinting = true
		walking_audio.stop()
		running_audio.play()
		
	elif (Input.is_action_just_pressed("sprint") and sprinting) or stamina <= 0 or input_dir == Vector2.ZERO:
		sprinting = false
		running_audio.stop()
	
	if sprinting:
		speed = SPRINT_SPEED
		stamina -= 1
	else:
		speed = WALK_SPEED
		if stamina < 80:
			stamina += .7

	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			if !walking_audio.playing and !sprinting:
				walking_audio.play()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta*7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta*7.0)
			if abs(velocity.x) < .2 and abs(velocity.z) < .2:
				walking_audio.stop()
	else: 
		velocity.x = lerp(velocity.x, direction.x * speed, delta*3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta*3.0)
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob) 
	
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED *2)
	var target_fov = BASE_FOV + FOV_CHANGE  * velocity_clamped
	
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
	
	
func  _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ /2) * BOB_AMP
	return pos
	
func hit(dir):
	if !playing:
		return
	punched.play()
	hit_rect.visible = true
	health -= 1
	get_tree().create_timer(5).timeout.connect(regen_health)
	
	
	await get_tree().create_timer(0.2).timeout
	
	hit_rect.visible = false
	if is_on_floor():
		velocity += (dir * HEAD_STAGGER)
	if health <= 0:
		slammed.play()
		playing = false
		walking_audio.stop()
		running_audio.stop()
		pistol.visible = false
		pistol2.visible = false
		auto_gun.visible = false
		weapon_switching.play("DeathFall")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		emit_signal("game_over")
	
		
func _on_weapon_manager_shoot_bullet(barrel_position: Vector3, damage: int, head_damage: int, turso: int):
	
	instance = bullet_trail.instantiate()
	if !aim_ray.is_colliding():
		instance.init(barrel_position, aim_ray_end.global_position)
		get_parent().add_child(instance)
		return
		
	instance.init(barrel_position, aim_ray.get_collision_point())
	var hit_enemy = aim_ray.get_collider().is_in_group("enemy")
	if hit_enemy:
		aim_ray.get_collider().hit(damage, false, head_damage, turso)
	
	get_parent().add_child(instance)
	instance.trigger_particles(	aim_ray.get_collision_point(), 
						barrel_position, hit_enemy)
						
func _on_weapon_manager_shoot_laser(barrel_position: Vector3, _damage: int, _head_damage: int, _turso: int):
	instance = laser.instantiate()
	instance.position = barrel_position
	get_parent().add_child(instance)
	if aim_ray.is_colliding():
			instance.set_velocity(aim_ray.get_collision_point())
	else:
		instance.set_velocity(aim_ray_end.global_position)
		
func _on_weapon_manager_do_melee():
	if melee_aim_ray.is_colliding():
		instance = bullet_trail.instantiate()	

		instance.init(auto_barrel.global_position, melee_aim_ray.get_collision_point())
		var hit_enemy = melee_aim_ray.get_collider().is_in_group("enemy")
		if hit_enemy:
			melee_aim_ray.get_collider().hit(150, true, 1, 1)
		
		get_parent().add_child(instance)
		instance.trigger_particles(	melee_aim_ray.get_collision_point(), 
							auto_barrel.global_position, hit_enemy)
	
	
	
func regen_health():
	health += 1
	


func _on_weapon_manager_update_ammo(ammo:int, reserve: int):
	cur_ammo_label.text = str(ammo) + " / " + str(reserve)
	

func _on_weapon_manager_weapon_change(weapon_name: String):
	cur_weapon_label.text = weapon_name
	

