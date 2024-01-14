extends Skeleton3D


var spine: BoneAttachment3D
var physics_bones
var target_skeleton_local
var walk_speed = 1.0
var spine_index
func _ready():
	spine_index = find_bone("Spine")
	# print_debug("Spine" $spui)
	physical_bones_start_simulation()
	physics_bones = get_children().filter(func(x): return x is PhysicalBone3D)

func _input(event):
	pass

func _process(delta):
	walk()

func _physics_process(delta):
	pass

func walk():
	if Input.is_physical_key_pressed(KEY_UP):
		spine.apply_central_impulse(-spine.basis.y * walk_speed)

	if Input.is_physical_key_pressed(KEY_DOWN):
		spine.apply_central_impulse(spine.basis.y * walk_speed)
	
	if Input.is_physical_key_pressed(KEY_RIGHT):
		spine.apply_central_impulse(spine.basis.x * walk_speed)
		
	if Input.is_physical_key_pressed(KEY_LEFT):
		spine.apply_central_impulse(-spine.basis.x * walk_speed)
