extends Node3D

@onready var weapon_switching = $WeaponSwitching

@onready var gun_anim = $Pistol/AnimationPlayer
@onready var gun_barrel = $Pistol/RayCast3D
@onready var gun_anim2 = $Pistol2/AnimationPlayer
@onready var gun_barrel2 = $Pistol2/RayCast3D

@onready var laser_shot = $LaserShot
@onready var heavery_gun_shot = $HeaveyGunShot
@onready var reload_sound = $Reload
@onready var melee_weapon = $Axe
@onready var melee_swing = $MeleeSwing
@onready var lower_audio = $Lower
@onready var empty_shot = $EmptyShot


var laser = load("res://Models/Guns/laser.tscn")
var bullet_trail = load("res://Scenes/BulletTrail.tscn")

signal weapon_change(name: String)
signal update_ammo(ammo:int, reserve: int)
signal shoot_bullet
signal shoot_laser
signal do_melee

var instance

var current_weapon = {}
var start_weapon = "MR6"

var equiped_weapons: Array = []

var max_weapons = 3

var index = 0

var _weapon_stats =  ImportData.gun_data
var _weapon_references = {}

var raised_x = .059
var raised_y = -.052
var raised_z = -.114

#const lowered_position = Vector3(0, -1, 0)

const lowered_x = 0
const lowered_y = -1
const lowered_z = -0

var raise_tween 
var lower_tween
var shoot_tween
var reload_tween

var cheat = false
var cheat_code = [ '4','2','0', '6', '9']
var code_idx = 0

enum SwitchSpeeds {
	STD,
	FAST,
	FIRST,
	MELEE
}

var switch_speed = SwitchSpeeds.STD
var melee_weapon_change_speed = .1



func _ready():
	var weapon_keys = _weapon_stats.keys()
	equiped_weapons.push_front( { 	"name": start_weapon, 
								  	"mag_ammo":_weapon_stats[start_weapon].ammo_std_mag,
									"reserve_ammo":_weapon_stats[start_weapon].ammo_std_start})
	max_weapons = 1
	for key in weapon_keys:
		if _weapon_stats[key].asset != "null" :
			_weapon_references[_weapon_stats[key].name] = get_node(_weapon_stats[key].asset)
			if key != start_weapon && !key.contains('DW') && key != 'RayGun69' && key != 'RayGun69420':
				equiped_weapons.push_back( { 	"name": _weapon_stats[key].name, 
											  	"mag_ammo":_weapon_stats[key].ammo_std_mag,
												"reserve_ammo":_weapon_stats[key].ammo_std_start})
				max_weapons += 1
		
	equiped_weapons.push_back({ 	"name": "RayGun69", 
								  	"mag_ammo":_weapon_stats["RayGun69"].ammo_std_mag,
									"reserve_ammo":_weapon_stats["RayGun69"].ammo_std_start})
	equiped_weapons.push_back({ 	"name": "RayGun69420", 
								  	"mag_ammo":_weapon_stats["RayGun69420"].ammo_std_mag,
									"reserve_ammo":_weapon_stats["RayGun69420"].ammo_std_start})
	

#	equiped_weapons.push_front( { 	"name": start_weapon, 
#								  	"mag_ammo":_weapon_stats[start_weapon].ammo_std_mag,
#									"reserve_ammo":_weapon_stats[start_weapon].ammo_std_start})
#	equiped_weapons.push_back({ 	"name": "ICR-1", 
#								  	"mag_ammo":_weapon_stats["ICR-1"].ammo_std_mag,
#									"reserve_ammo":_weapon_stats["ICR-1"].ammo_std_start})
#	equiped_weapons.push_back({ 	"name": "Man-O-War", 
#								  	"mag_ammo":_weapon_stats["Man-O-War"].ammo_std_mag,
#									"reserve_ammo":_weapon_stats["Man-O-War"].ammo_std_start})
#	equiped_weapons.push_back({ 	"name": "RayGun69", 
#								  	"mag_ammo":_weapon_stats["RayGun69"].ammo_std_mag,
#									"reserve_ammo":_weapon_stats["RayGun69"].ammo_std_start})
#	equiped_weapons.push_back({ 	"name": "RayGun69420", 
#								  	"mag_ammo":_weapon_stats["RayGun69420"].ammo_std_mag,
#									"reserve_ammo":_weapon_stats["RayGun69420"].ammo_std_start})
	
	
#	current_weapon = _weapon_stats[start_weapon]
#	if current_weapon.type == "handgun":
#		raised_z -= .073
		
#	var trigger_position = _weapon_references[start_weapon].get_node("trigger").position
#	_weapon_references[start_weapon].position = Vector3(raised_x-trigger_position.x, raised_y - trigger_position.y, raised_z - trigger_position.z)
	
	
	
	
func _process(_delta):
	if len(equiped_weapons) == 0:
		return
	
	if (raise_tween and raise_tween.is_running()) or (lower_tween and lower_tween.is_running()):
		return
		
	if Input.is_action_pressed("shoot"):
		if cheat:
			shoot_rayguns()
		elif equiped_weapons[index].name == 'RayGun':
			shoot_raygun()
		else:
			shoot()

func _input(event):
	if (raise_tween and raise_tween.is_running()) or (lower_tween and lower_tween.is_running()):
		return
	
	if event.is_action_pressed("reload"):
		reload()
		return
		
	
		
	if event.is_action_pressed("42069"):
		if cheat_code[code_idx] == event.as_text():
			code_idx += 1
			if code_idx >= len(cheat_code):
				if cheat:
					lower(max_weapons, switch_speed)
					lower(max_weapons +1 ,switch_speed)
					raise(index, switch_speed)
					cheat = false
				else:
					lower(index, switch_speed)
					raise(max_weapons, switch_speed)
					raise(max_weapons +1, switch_speed, -1)
					cheat = true
				code_idx = 0
		else: 
			code_idx = 0
		
	if len(equiped_weapons) <= 1:
		return
		
	if event.is_action_pressed("weapon_up") && !cheat:
		lower(index, switch_speed)
		index = (index +1) % max_weapons
		raise(index, switch_speed)
	elif event.is_action_pressed("weapon_down") && !cheat:
		lower(index, switch_speed)
		index = (index + max_weapons -1 ) % max_weapons
		raise(index, switch_speed)
	elif event.is_action_pressed("melee"):
		melee()

func init():
	pass
	
func raise(weapon_index: int, speed: SwitchSpeeds, offset: int = 1):
	var switch 
	var cur_weapon = equiped_weapons[weapon_index].name
	
	match speed:
		SwitchSpeeds.STD:
			switch = _weapon_stats[cur_weapon].switch_std_raise
		SwitchSpeeds.FAST:
			switch = _weapon_stats[cur_weapon].switch_fast_raise
		SwitchSpeeds.FIRST:
			switch = _weapon_stats[cur_weapon].switch_first_raise
		SwitchSpeeds.MELEE:
			switch = melee_weapon_change_speed
			
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var trigger_position = cur_weapon_ref.get_node("trigger").position
	cur_weapon_ref.visible = true
	var raised_position = Vector3(offset * (raised_x - trigger_position.x), raised_y - trigger_position.y, raised_z - trigger_position.z)
	raise_tween = get_tree().create_tween()
	raise_tween.tween_property(cur_weapon_ref, "position", raised_position, switch)
#	raise_audio.play()
	emit_signal('update_ammo', equiped_weapons[weapon_index].mag_ammo, equiped_weapons[weapon_index].reserve_ammo)
	emit_signal('weapon_change',cur_weapon)
	
func lower(weapon_index: int, speed: SwitchSpeeds):
	var switch 
	var cur_weapon = equiped_weapons[weapon_index].name
	
	match speed:
		SwitchSpeeds.STD:
			switch = _weapon_stats[cur_weapon].switch_std_lower
		SwitchSpeeds.FAST:
			switch = _weapon_stats[cur_weapon].switch_fast_lower
		SwitchSpeeds.FIRST:
			switch = _weapon_stats[cur_weapon].switch_first_lower
		SwitchSpeeds.MELEE:
			switch = melee_weapon_change_speed
			
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var lowered_position = Vector3(lowered_x, lowered_y, lowered_z)
	lower_tween = get_tree().create_tween()
	lower_tween.tween_property(cur_weapon_ref, "position", lowered_position, switch)
	lower_audio.play()
	await get_tree().create_timer(switch -.1).timeout
	cur_weapon_ref.visible = false
	
func shoot():
	if  weapon_switching.is_playing() or (reload_tween and reload_tween.is_running()) or (shoot_tween and shoot_tween.is_running()):
		return
	
	if equiped_weapons[index].mag_ammo <= 0:
		empty_shot.play()
		return
	
	var cur_weapon = equiped_weapons[index].name
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var cur_postion = cur_weapon_ref.position
	var cur_rotation = cur_weapon_ref.rotation
	
	var barrel = cur_weapon_ref.get_node("barrel")
	
	var back_position = Vector3(cur_postion.x, cur_postion.y,cur_postion.z +.04)
	var back_rotation = Vector3(cur_rotation.x+.2, cur_rotation.y, cur_rotation.z)
	
	var animation_time = _weapon_stats[cur_weapon].rate_std_time / 2
	
	heavery_gun_shot.play()

	shoot_tween = create_tween().set_parallel(true)
	
	shoot_tween.tween_property(cur_weapon_ref, "position", back_position, animation_time )
	shoot_tween.tween_property(cur_weapon_ref, "rotation", back_rotation, animation_time )
	shoot_tween.chain().tween_property(cur_weapon_ref, "position", cur_postion, animation_time )
	shoot_tween.chain().tween_property(cur_weapon_ref, "rotation", cur_rotation, animation_time )
	equiped_weapons[index].mag_ammo -= 1
	update_ammo.emit(equiped_weapons[index].mag_ammo, equiped_weapons[index].reserve_ammo)
	shoot_bullet.emit(	barrel.global_position, _weapon_stats[cur_weapon].damage, 
						_weapon_stats[cur_weapon].headshot, _weapon_stats[cur_weapon].turso)
						
func shoot_rayguns():
	
	if !gun_anim.is_playing():
		laser_shot.play()
		gun_anim.play("Shoot")
		shoot_laser.emit(	gun_barrel.global_position, 500, 1, 1)
		
	if !gun_anim2.is_playing():
		gun_anim2.play("Shoot")
		shoot_laser.emit(	gun_barrel2.global_position, 500, 1, 1)
		
func shoot_raygun():
	if !gun_anim.is_playing():
		laser_shot.play()
		gun_anim.play("Shoot")
		equiped_weapons[index].mag_ammo -= 1
		update_ammo.emit(equiped_weapons[index].mag_ammo, equiped_weapons[index].reserve_ammo)
		shoot_laser.emit(	gun_barrel.global_position, 500, 1, 1)
		
			

func reload():
	if weapon_switching.is_playing() or (reload_tween and reload_tween.is_running()) or (shoot_tween and shoot_tween.is_running()):
		return
		
	var cur_mag = equiped_weapons[index].mag_ammo
	var max_mag = _weapon_stats[equiped_weapons[index].name].ammo_std_mag
		
	if( cur_mag == max_mag):
		return
		
	if( equiped_weapons[index].reserve_ammo <=0):
		return
		
	var cur_weapon = equiped_weapons[index].name
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var cur_postion = cur_weapon_ref.position
	var cur_rotation = cur_weapon_ref.rotation
	
	var back_position = Vector3(cur_postion.x, cur_postion.y+.06,cur_postion.z+.03 )
	var back_rotation = Vector3(cur_rotation.x+1.2, cur_rotation.y+1, cur_rotation.z)

	var animation_time = _weapon_stats[cur_weapon].reload_std_add / 3

	reload_tween = create_tween().set_parallel(true)

	reload_tween.tween_property(cur_weapon_ref, "position", back_position, animation_time  )
	reload_tween.tween_property(cur_weapon_ref, "rotation", back_rotation, animation_time )
	reload_tween.chain().tween_property(cur_weapon_ref, "position", cur_postion, animation_time ).set_delay(animation_time)
	reload_tween.parallel().tween_property(cur_weapon_ref, "rotation", cur_rotation, animation_time ).set_delay(animation_time)
	
	
	var reload_amount = min(max_mag - cur_mag, equiped_weapons[index].reserve_ammo)
	
	equiped_weapons[index].mag_ammo += reload_amount
	equiped_weapons[index].reserve_ammo -= reload_amount
	update_ammo.emit(equiped_weapons[index].mag_ammo, equiped_weapons[index].reserve_ammo)
	await get_tree().create_timer(animation_time).timeout
	reload_sound.play()
	


func _on_player_player_ready():
	raise(0, switch_speed)
	
func melee():		
	if weapon_switching.is_playing() or (reload_tween and reload_tween.is_running()) or (shoot_tween and shoot_tween.is_running()):
		return
		
#	_lower_weapon(2.5)
	await get_tree().create_timer(.1).timeout
	melee_weapon.visible = true
	
	do_melee.emit()
	
	lower(index, SwitchSpeeds.MELEE)
	melee_swing.play()
	weapon_switching.play("Melee")
	await get_tree().create_timer(.1).timeout
	raise(index, SwitchSpeeds.MELEE)
	
	melee_weapon.visible = false

	await get_tree().create_timer(.3).timeout
