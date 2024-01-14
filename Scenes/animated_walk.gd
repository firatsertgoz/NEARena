extends Skeleton3D
@export var walk_speed: float = 1.0

var spine: PhysicalBone3D

func _ready():
	spine = get_node("Spine")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	walk()

func walk():
	if Input.is_physical_key_pressed(KEY_W):
		spine.apply_central_impulse(-spine.basis.y * walk_speed)

	if Input.is_physical_key_pressed(KEY_S):
		spine.apply_central_impulse(spine.basis.y * walk_speed)
	
	if Input.is_physical_key_pressed(KEY_D):
		spine.apply_central_impulse(spine.basis.x * walk_speed)
		
	if Input.is_physical_key_pressed(KEY_A):
		spine.apply_central_impulse(-spine.basis.x * walk_speed)
