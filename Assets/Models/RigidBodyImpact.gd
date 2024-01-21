extends RigidBody3D

signal total_force_signal
var collision = false;
var collision_force: Vector3 = Vector3.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready():
	max_contacts_reported = 5
	contact_monitor = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _integrate_forces(state):
	#pass
	if(collision):
		#var force = state.inverse_inertia_tensor
		#print_debug(state.inverse_inertia)
		for i in range(state.get_contact_count()):
			#collision_force += state.get_contact_impulse(i) * state.get_contact_local_normal(i)
			print_debug(state.get_linear_velocity().length())
			
		var force = state.get_linear_velocity() / state.get_inverse_mass() / state.get_step()
		# print_debug("This is the other one", force.length())
		total_force_signal.emit(force)
		collision = false


func _on_player_box_entered():
	collision = true; # Replace with function body.


