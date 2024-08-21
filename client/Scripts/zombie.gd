extends CharacterBody3D

var player = null
var state_machine
var health = 150
var speed = WALK_SPEED

const WALK_SPEED = 3.2
const RUN_SPEED = 4.2
const ATTACK_RANGE = 2.5

@export var player_path := "/root/World/Map/NavigationRegion3D/Player"

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var crosshair_hit = $CrosshairHit
@onready var collision_capsule = $CollisionShape3D
@onready var head = $Armature/Skeleton3D/Head/Area3D/CollisionShape3D
@onready var spine = $Armature/Skeleton3D/Spine/Area3D/CollisionShape3D
@onready var left_hand = $Armature/Skeleton3D/LeftHand/Area3D/CollisionShape3D
@onready var right_hand = $Armature/Skeleton3D/RightHand/Area3D/CollisionShape3D

@onready var noises = [$ZombieNoisesTrack1, $ZombieNoisesTrack2, $ZombieNoisesTrack3, $ZombieNoisesTrack4]
var rng = RandomNumberGenerator.new()

@onready var flesh_hit = $FleshHit

enum HitType {
	BODY,
	HEAD,
	MELEE
} 

signal zombie_death(kill_area:HitType)
signal non_lethal_hit

func  _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
	crosshair_hit.position.x = get_viewport().size.x / 2 - 32
	crosshair_hit.position.y = get_viewport().size.y / 2 - 32
	var i = rng.randf_range(0, 3)
	noises[i].play()
	
func init(level):
	if(level < 9):
		health = 50 + (level * 100)
	else:
		health = 950 * (1.1 ** (level - 9))
	
	if level < 5:
		speed = WALK_SPEED
	elif level > 6 and level < 12:
		var rand = randi()  % 2
		if rand > 0:
			speed = RUN_SPEED
		else:
			speed = WALK_SPEED
	else: 
		speed = RUN_SPEED
	
func _process(delta):
	velocity = Vector3.ZERO

	match state_machine.get_current_node():
		"Run":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * speed * 1.5
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	move_and_slide()
	
func _target_in_range():
		return global_position.distance_to(player.global_position) < ATTACK_RANGE
		
func _hit_fiished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir  = global_position.direction_to(player.global_position)
		player.hit(dir)


func _on_area_3d_body_part_hit(dam, hit_type: HitType):
	flesh_hit.play()
	crosshair_hit.visible = true
	emit_signal("non_lethal_hit")
	health -= dam
	await get_tree().create_timer(0.05).timeout
	crosshair_hit.visible = false
	if health <=  0:
		collision_capsule.disabled = true
		head.disabled = true
		spine.disabled = true
		left_hand.disabled = true
		right_hand.disabled = true
		zombie_death.emit(hit_type)
		anim_tree.set("parameters/conditions/die", true)
		await get_tree().create_timer(2.55).timeout
		queue_free()
