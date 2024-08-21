extends Node3D

@onready var spawns = $Map/Spawns
@onready var navigation_region = $Map/NavigationRegion3D

#UI
@onready var points_ui = $UI/Points
@onready var level_ui = $UI/Level
@onready var new_points_ui = $UI/NewPoints
@onready var anim_player = $AnimationPlayer
@onready var game_over_ui = $GG/GameOver
@onready var game_music = $GameMusic
@onready var pathetic = $Pathetic
@onready var next_lvl_audio = $NextLevel


const SPAWNED_MAX = 24

var zombie = load("res://Models/Zombie/zombie.tscn")
var instance

var playing = true
var level = 0
var level_kills = 0
var needed_kills = 0
var total_kills = 0
var points = 0
var spawned = 0

enum HitType {
	BODY,
	HEAD,
	MELEE
} 

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	level_up(1)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _get_random_child(parent_node):
	var random_id = randi()  % parent_node.get_child_count()
	return parent_node.get_child(random_id)
	


func _on_zombie_spawn_timer_timeout():
	if spawned < level_kills and playing:
		spawned += 1
		print(spawned)
		var spawn_point = _get_random_child(spawns).global_position
		instance = zombie.instantiate()
		instance.init(level)
		instance.zombie_death.connect( on_zombie_death)
		instance.non_lethal_hit.connect(on_non_lethal_hit)
		instance.position = spawn_point
		navigation_region.add_child(instance)
		
	
func on_zombie_death(kill_area: HitType):
	match kill_area:
		HitType.BODY:
			_update_points(50)
		HitType.HEAD:
			_update_points(100)
		HitType.MELEE:
			_update_points(130)
		
	total_kills += 1
	needed_kills -= 1
	
#	print("total kills: " + str(total_kills))
#	print("needed kills: " + str(needed_kills))
	
	if needed_kills <= 0:
		level_up(level + 1)

func _kills_till_next_lvl(lvl):
	return  ceil(0.000054 * lvl**3 + 0.169717 * lvl**2 + 0.541627 *lvl + 16) *2
	
func on_non_lethal_hit():
	_update_points(10)
	
func level_up(lvl):
	if lvl > 1:
		next_lvl_audio.play()
	spawned = 0
	level = lvl
	level_kills = _kills_till_next_lvl(lvl)
	needed_kills = level_kills 
	level_ui.text = str(lvl)
	anim_player.play("NewLevel")

func _update_points(new_points):
	points += new_points
	points_ui.text = str(points)
	new_points_ui.text = str(new_points)
	new_points_ui.visible = true
	anim_player.play("AddPoints")
	await get_tree().create_timer(.3).timeout
	new_points_ui.visible = false
	
	


func _on_player_game_over():
	game_over_ui.visible = true
	playing = false
	game_music.stop()
	await get_tree().create_timer(.4).timeout
	pathetic.play()
	
