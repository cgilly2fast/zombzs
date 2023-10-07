extends Node3D

@onready var weapon_switching = $WeaponSwitching

var current_weapon = {}
var start_weapon = "MR6"

var equiped_weapons: Array = []

var max_weapons = 3

var index = 0

var next_weapon:String

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

var switch_speed = 0

enum SwitchSpeeds {
	STD,
	FAST,
	FIRST,
}

@export var start_weapons: Array[String]

@onready var pistol_1 = $pistol_1

func _ready():
	var weapon_keys = _weapon_stats.keys()
	for key in weapon_keys:
		if _weapon_stats[key].asset != null:
			_weapon_references[_weapon_stats[key].name] = get_node(_weapon_stats[key].asset)

	equiped_weapons.push_front(_weapon_stats[start_weapon])
	equiped_weapons.push_back(_weapon_stats["Drakon"])
	equiped_weapons.push_back(_weapon_stats["Gorgon"])
	

	raise(0, switch_speed)
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
		

func init():
	pass
	
func raise(index: int, speed: SwitchSpeeds):
	var switch 
	match speed:
		SwitchSpeeds.STD:
			switch = equiped_weapons[index].switch_std_raise
		SwitchSpeeds.FAST:
			switch = equiped_weapons[index].switch_fast_raise
		SwitchSpeeds.FIRST:
			switch = equiped_weapons[index].switch_first_raise
			
	var cur_weapon = equiped_weapons[index].name
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var trigger_position = cur_weapon_ref.get_node("trigger").position
	cur_weapon_ref.visible = true
	var raised_position = Vector3(raised_x-trigger_position.x, raised_y - trigger_position.y, raised_z - trigger_position.z)
	raise_tween = get_tree().create_tween()
	raise_tween.tween_property(cur_weapon_ref, "position", raised_position, switch)
	
func lower(index: int, speed: SwitchSpeeds):
	var switch 
	match speed:
		SwitchSpeeds.STD:
			switch = equiped_weapons[index].switch_std_lower
		SwitchSpeeds.FAST:
			switch = equiped_weapons[index].switch_fast_lower
		SwitchSpeeds.FIRST:
			switch = equiped_weapons[index].switch_first_lower
	var cur_weapon = equiped_weapons[index].name
	var cur_weapon_ref = _weapon_references[cur_weapon]
	var lowered_position = Vector3(lowered_x, lowered_y, lowered_z)
	lower_tween = get_tree().create_tween()
	lower_tween.tween_property(cur_weapon_ref, "position", lowered_position, switch)
	await get_tree().create_timer(switch -.1).timeout
	cur_weapon_ref.visible = false
	
