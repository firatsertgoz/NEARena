extends RigidBody3D

signal total_force_signal_with_body(float , Node3D )
var collision = false;
var collision_force: Vector3 = Vector3.ZERO;
var rigid_body: Node3D
# Called when the node enters the scene tree for the first time.
func _ready():
	max_contacts_reported = 5
	contact_monitor = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _integrate_forces(state):
	if(collision):
		for i in range(state.get_contact_count()):
			collision_force += state.get_contact_impulse(i) * state.get_contact_local_normal(i)
		total_force_signal_with_body.emit(collision_force.length(), rigid_body)
		collision = false
		collision_force = Vector3.ZERO


func _on_player_box_entered():
	collision = true; # Replace with function body.




func _on_body_entered(body):
	#print_debug(body.name)
	#if(body.get_tree())
	rigid_body = body
	collision = true; # Replace with function body.
