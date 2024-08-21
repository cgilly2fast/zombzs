extends Control

@onready var loading = $Play/Control/Loading
@onready var play = $Play
@onready var controls = $Controls

@onready var world = load("res://Scenes/world.tscn")
@onready var start = load("res://UI/Start.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_play_pressed():
	loading.visible = true
	loading.play("Loading")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().create_timer(.05).timeout
	get_tree().change_scene_to_packed(world)


func _on_quit_pressed():
	get_tree().change_scene_to_packed(start)
	

func _on_controls_pressed():
	play.visible = false
	controls.visible = true
	
func _on_back_pressed():
	print("here")
	controls.visible = false
	play.visible = true
