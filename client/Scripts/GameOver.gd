extends Control

@onready var loading = $Loading
@onready var play = $Play
@onready var quit = $Quit

@onready var world = load("res://Scenes/world.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_play_pressed():
	loading.visible = true
	loading.play("Loading")
	play.visible = false
	quit.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().create_timer(.05).timeout
	get_tree().change_scene_to_packed(world)


func _on_quit_pressed():
	get_tree().quit()
