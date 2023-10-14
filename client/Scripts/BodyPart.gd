extends Area3D

@export var head_area := false

signal body_part_hit(dam, hit_type)

enum HitType {
	BODY,
	HEAD,
	MELEE
} 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func hit(damage, melee, head, turso):
	if melee:
		body_part_hit.emit(damage, HitType.MELEE)
		return
	if!melee and head_area:
		body_part_hit.emit(damage * head, HitType.HEAD)
		return
	body_part_hit.emit(damage * turso, HitType.BODY)
