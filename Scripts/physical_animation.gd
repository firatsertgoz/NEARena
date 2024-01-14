extends Skeleton3D

@export var target_skeleton: Skeleton3D

@export var linear_spring_stiffness: float = 100.0
@export var linear_spring_damping: float = 10.0
@export var max_linear_force: float = 9999.0

@export var angular_spring_stiffness: float = 50.0
@export var angular_spring_damping: float = 20.0
@export var max_angular_force: float = 9999.0
@export var walk_speed: float = 0.5

@onready var BodyControl = $BodyControl
@onready var LeftLegControl = $BodyControl/LeftLegController
@onready var RightLegControl = $BodyControl/RightLegController
@onready var RightArmControl = $BodyControl/RightArmController
@onready var LeftArmControl = $BodyControl/LeftArmController
@onready var JumpRayCast = $"Physical Bone Spine/JumpRayCast"
@onready var BodyControlStaticBody = $"BodyControl/StaticBody3D"
@onready var CameraPivot: Node3D
var JumpAnimationTimer = 0.0
var WalkAnimationTimer = 0.0
var right_hip: PhysicalBone3D
var left_hip: PhysicalBone3D
var spine: PhysicalBone3D
var physics_bones
var target_skeleton_local
var Iswalking = false
var lower_body: PhysicalBone3D
var upper_body: PhysicalBone3D
var Mouse_sensitivity = 0.3
var head: PhysicalBone3D
var CanJump = true
var JumpStrength = 100.0
var LeftHandActive = false
# Called when the node enters the scene tree for the first time.
func _ready():
	CameraPivot = get_node("CameraPivot")
	#LeftLegControl = get_node("Body Control/LeftLegController")
	#RightLegControl = get_node("Body Control/RightLegController")
	spine = get_node("Physical Bone Spine")
	head = get_node("Physical Bone Neck")
	left_hip = get_node("Physical Bone LeftHip")
	right_hip =  get_node("Physical Bone RightHip")
	upper_body = get_node("Physical Bone UpperChest")
	lower_body =  get_node("Physical Bone LowerChest") 
	physical_bones_start_simulation()
	physics_bones = get_children().filter(func(x): return x is PhysicalBone3D)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	CameraPivot.global_transform.origin = head.global_transform.origin
	walk()
	handle_rotation()
	HandleGrab()
func _physics_process(delta):
	pass

func handle_rotation():
	BodyControl.rotation.y = CameraPivot.rotation.y
	LeftArmControl.rotation.y = CameraPivot.rotation.y
	RightArmControl.rotation.y = CameraPivot.rotation.y
	LeftLegControl.rotation.y = CameraPivot.rotation.y
	RightLegControl.rotation.y  = CameraPivot.rotation.y

func _input(event):
	if Input.is_action_just_pressed("left_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion:
		CameraPivot.rotation_degrees.y -= event.relative.x * Mouse_sensitivity
		CameraPivot.rotation_degrees.x -= event.relative.y * Mouse_sensitivity
		CameraPivot.rotation_degrees.x = clamp(CameraPivot.rotation_degrees.x, -90, 90)


func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffness: float, damping: float) -> Vector3:
	return (stiffness * displacement) - (damping * current_velocity)

func walk():
	Iswalking = false
	if Input.is_physical_key_pressed(KEY_W):
		Iswalking = true
		spine.apply_central_impulse(-BodyControl.transform.basis.z * walk_speed)
		left_hip.apply_central_impulse(-BodyControl.transform.basis.z * walk_speed)
		right_hip.apply_central_impulse(-BodyControl.transform.basis.z * walk_speed)

	if Input.is_physical_key_pressed(KEY_S):
		Iswalking = true
		spine.apply_central_impulse(BodyControl.transform.basis.z * walk_speed)
		left_hip.apply_central_impulse(BodyControl.transform.basis.z * walk_speed)
		right_hip.apply_central_impulse(BodyControl.transform.basis.z * walk_speed)
	
	if Input.is_physical_key_pressed(KEY_D):
		Iswalking = true
		spine.apply_central_impulse(BodyControl.transform.basis.x * walk_speed)
		left_hip.apply_central_impulse(BodyControl.transform.basis.x * walk_speed)
		right_hip.apply_central_impulse(BodyControl.transform.basis.x * walk_speed)
		
	if Input.is_physical_key_pressed(KEY_A):
		Iswalking = true
		spine.apply_central_impulse(-BodyControl.transform.basis.x * walk_speed)
		left_hip.apply_central_impulse(-BodyControl.transform.basis.x * walk_speed)
		right_hip.apply_central_impulse(-BodyControl.transform.basis.x * walk_speed)
	if Input.is_physical_key_pressed(KEY_SPACE):
		if CanJump == true:
			if JumpRayCast.is_colliding():
				if JumpRayCast.get_collision_normal().y > 0.5:
					CanJump = false
					spine.apply_central_impulse(-spine.transform.basis.z*JumpStrength)
					await get_tree().create_timer(0.5).timeout
					CanJump = true
	if Iswalking:
		AnimateWalk()
		pass
	else:
		LeftLegControl.rotation.x = 0
		RightLegControl.rotation.x = 0
	
func AnimateWalk():
	WalkAnimationTimer += 0.1
	RightLegControl.rotation.x = sin(WalkAnimationTimer)*1
	LeftLegControl.rotation.x= -sin(WalkAnimationTimer)*1
		
func AnimateJump():
	JumpAnimationTimer += 0.1

func HandleGrab():
	if Input.is_action_pressed("left_mouse"):
		LeftArmControl.rotation.x = CameraPivot.rotation.x*2
		LeftHandActive = true
		print_debug("this works")
		LeftArmControl.get_node("LeftUpperArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		LeftArmControl.get_node("LeftUpperArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		LeftArmControl.get_node("LeftUpperArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		LeftArmControl.get_node("LeftLowerArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		LeftArmControl.get_node("LeftLowerArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		LeftArmControl.get_node("LeftLowerArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
	else:
		LeftArmControl.get_node("LeftUpperArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		LeftArmControl.get_node("LeftUpperArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		LeftArmControl.get_node("LeftUpperArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		LeftArmControl.get_node("LeftLowerArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		LeftArmControl.get_node("LeftLowerArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		LeftArmControl.get_node("LeftLowerArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		
		LeftHandActive = false
		#LeftGrabJoint.set_node_a("")
		#LeftGrabJoint.set_node_b("")
		#LeftHandGrab = null
