extends Node3D

@onready var weapon_switching = $WeaponSwitching
@onready var aim_ray = $GunAimRay
@onready var aim_ray_end = $AimRayEnd

var bullet = load("res://Models/Guns/bullet.tscn")
var bullet_trail = load("res://Scenes/BulletTrail.tscn")

signal weapon_change
signal update_ammo
signal shoot_bullet

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

const lowered_position = Vector3(0, -1, 0)

const lowered_x = 0
const lowered_y = -1
const lowered_z = -0

var raise_tween 
var lower_tween
var shoot_tween
var reload_tween

var switch_speed = 0

enum SwitchSpeeds {
	STD,
	FAST,
	FIRST,
}

func _ready():
	var weapon_keys = _weapon_stats.keys()
	for key in weapon_keys:
		if _weapon_stats[key].asset != null:
			_weapon_references[_weapon_stats[key].name] = get_node(_weapon_stats[key].asset)

	equiped_weapons.push_front( { 	"name": start_weapon, 
								  	"mag_ammo":_weapon_stats[start_weapon].ammo_std_mag,
									"reserve_ammo":_weapon_stats[start_weapon].ammo_std_start})
	equiped_weapons.push_back({ 	"name": "Drakon", 
								  	"mag_ammo":_weapon_stats["Drakon"].ammo_std_mag,
									"reserve_ammo":_weapon_stats["Drakon"].ammo_std_start})
	equiped_weapons.push_back({ 	"name": "Gorgon", 
								  	"mag_ammo":_weapon_stats["Gorgon"].ammo_std_mag,
									"reserve_ammo":_weapon_stats["Gorgon"].ammo_std_start})
	
	
#	current_weapon = _weapon_stats[start_weapon]
#	if current_weapon.type == "handgun":
#		raised_z -= .073
		
#	var trigger_position = _weapon_references[start_weapon].get_node("trigger").position
#	_weapon_references[start_weapon].position = Vector3(raised_x-trigger_position.x, raised_y - trigger_position.y, raised_z - trigger_position.z)
	
	
	

func _input(event):
	if len(equiped_weapons) <= 1:
		return
	
	if (raise_tween and raise_tween.is_running()) or (lower_tween and lower_tween.is_running()):
		return
	
	if event.is_action_pressed("weapon_up"):
		lower(index, switch_speed)
		index = (index +1) % max_weapons
		raise(index, switch_speed)
	elif event.is_action_pressed("weapon_down"):
		lower(index, switch_speed)
		index = (index + max_weapons -1 ) % max_weapons
		raise(index, switch_speed)
	elif event.is_action_pressed("shoot"):
		shoot()
	elif event.is_action_pressed("reload"):
		reload()
		

func init():
	pass
	
func raise(index: int, speed: SwitchSpeeds):
	var switch 
	var cur_weapon = equiped_weapons[index].name
	
	match speed:
		SwitchSpeeds.STD:
			switch = _weapon_stats[cur_weapon].switch_std_raise
		SwitchSpeeds.FAST:
			switch = _weapon_stats[cur_weapon].switch_fast_raise
		SwitchSpeeds.FIRST:
			switch = _weapon_stats[cur_weapon].switch_first_raise
			
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var trigger_position = cur_weapon_ref.get_node("trigger").position
	cur_weapon_ref.visible = true
	var raised_position = Vector3(raised_x-trigger_position.x, raised_y - trigger_position.y, raised_z - trigger_position.z)
	raise_tween = get_tree().create_tween()
	raise_tween.tween_property(cur_weapon_ref, "position", raised_position, switch)
	update_ammo.emit(equiped_weapons[index].mag_ammo, equiped_weapons[index].reserve_ammo)
	weapon_change.emit(cur_weapon)
	
func lower(index: int, speed: SwitchSpeeds):
	var switch 
	var cur_weapon = equiped_weapons[index].name
	
	match speed:
		SwitchSpeeds.STD:
			switch = _weapon_stats[cur_weapon].switch_std_lower
		SwitchSpeeds.FAST:
			switch = _weapon_stats[cur_weapon].switch_fast_lower
		SwitchSpeeds.FIRST:
			switch = _weapon_stats[cur_weapon].switch_first_lower
			
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var lowered_position = Vector3(lowered_x, lowered_y, lowered_z)
	lower_tween = get_tree().create_tween()
	lower_tween.tween_property(cur_weapon_ref, "position", lowered_position, switch)
	await get_tree().create_timer(switch -.1).timeout
	cur_weapon_ref.visible = false
	
func shoot():
	if (reload_tween and reload_tween.is_running()) or (shoot_tween and shoot_tween.is_running()):
		return
	
	if equiped_weapons[index].mag_ammo <= 0:
		return
	
	var cur_weapon = equiped_weapons[index].name
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var cur_postion = cur_weapon_ref.position
	var cur_rotation = cur_weapon_ref.rotation
	
	var barrel = cur_weapon_ref.get_node("barrel")
	
	var back_position = Vector3(cur_postion.x, cur_postion.y,cur_postion.z +.04)
	var back_rotation = Vector3(cur_rotation.x+.2, cur_rotation.y, cur_rotation.z)
	
	var animation_time = _weapon_stats[cur_weapon].rate_std_time / 2

	shoot_tween = create_tween().set_parallel(true)
	
	shoot_tween.tween_property(cur_weapon_ref, "position", back_position, animation_time )
	shoot_tween.tween_property(cur_weapon_ref, "rotation", back_rotation, animation_time )
	shoot_tween.chain().tween_property(cur_weapon_ref, "position", cur_postion, animation_time )
	shoot_tween.chain().tween_property(cur_weapon_ref, "rotation", cur_rotation, animation_time )
	equiped_weapons[index].mag_ammo -= 1
	update_ammo.emit(equiped_weapons[index].mag_ammo, equiped_weapons[index].reserve_ammo)
	shoot_bullet.emit(	barrel.global_position, _weapon_stats[cur_weapon].damage, 
						_weapon_stats[cur_weapon].headshot, _weapon_stats[cur_weapon].turso)
	
func reload():
	if( reload_tween and reload_tween.is_running()) or (shoot_tween and shoot_tween.is_running()):
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
	


func _on_player_player_ready():
	raise(0, switch_speed)
	
#func _bullet():
#	var cur_weapon = equiped_weapons[index].name
#	var cur_weapon_ref = _weapon_references[cur_weapon]
#	var barrel = cur_weapon_ref.get_node("barrel")
#	instance = bullet_trail.instantiate()
#	if !aim_ray.is_colliding():
#		instance.init(barrel.global_position, aim_ray_end.global_position)
#		get_parent().add_child(instance)
#		return
#
#	instance.init(barrel.global_position, aim_ray.get_collision_point())
#	var hit_enemy = aim_ray.get_collider().is_in_group("enemy")
#	if hit_enemy:
#		aim_ray.get_collider().hit(50, false)
#
#	get_parent().add_child(instance)
#	instance.trigger_particles(	aim_ray.get_collision_point(), 
#						barrel.global_position, hit_enemy)
