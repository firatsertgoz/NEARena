extends Skeleton3D


# Called when the node enters the scene tree for the first time.
func _ready():
	physical_bones_start_simulation()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)
