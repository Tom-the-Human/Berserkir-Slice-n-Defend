extends Node2D

@export var enemy_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_enemy_spawn_timer_timeout() -> void:
	if enemy_scene == null:
		print("Error: Enemy scene is not assigned in the Inspector!")
		return
	
	var new_enemy = enemy_scene.instantiate()
	add_child(new_enemy)
	
	# send SwipeTrail coords to enemy
	$SwipeTrail.swipe_completed.connect(new_enemy.apply_cut)
