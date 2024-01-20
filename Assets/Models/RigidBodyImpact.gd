extends RigidBody3D

signal total_force_signal
var collision = false;


# Called when the node enters the scene tree for the first time.
func _ready():
	set_contact_monitor(true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _integrate_forces(state):
	#pass
	if(collision):
		#var force = state.inverse_inertia_tensor
		#print_debug(force)
		var force = state.get_linear_velocity() / state.get_inverse_mass() / state.get_step()
		print_debug("This is the other one", force)
		total_force_signal.emit(force)
		collision = false


func _on_player_box_entered():
	collision = true; # Replace with function body.
