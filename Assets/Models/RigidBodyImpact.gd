extends RigidBody3D
var collision = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _integrate_forces(state):
	#pass
	if(collision):
		var force = state.angular_velocity()
		print_debug(force)
		collision = false


func _on_player_box_entered():
	collision = true; # Replace with function body.
