extends Node3D

@export var angular_spring_stiffness: float = 50.0
@export var angular_spring_damping: float = 20.0
@export var max_angular_force: float = 9999.0
@export var walk_speed: float = 5


@onready var BodyControl = $BodyControl
@onready var LeftLegControl = $BodyControl/LeftLegController
@onready var RightLegControl = $BodyControl/RightLegController
@onready var RightArmControl = $BodyControl/RightArmController
@onready var LeftArmControl = $BodyControl/LeftArmController
@onready var NeckControl = $BodyControl/NeckController
@onready var JumpRayCast = $Armature/Skeleton3D/JumpRayCast
@onready var BodyControlStaticBody = $"BodyControl/StaticBody3D"
@onready var CameraPivot = $CameraPivot
@onready var LeftHandIK = $Armature/Skeleton3D/LeftHand
@onready var RightHandIK = $Armature/Skeleton3D/RightHand
@onready var Torso = $"Armature/Skeleton3D/Physical Bone Torso"
@onready var TorsoRB = $"Armature/Skeleton3D/Physical Bone Torso/RigidBody3D"
@onready var RightLowerArm = $"Armature/Skeleton3D/Physical Bone Right_Lower_Arm"
@onready var LeftLowerArm = $"Armature/Skeleton3D/Physical Bone Left_Lower_Arm"
@onready var LeftGrabJoint = $"Armature/Skeleton3D/Physical Bone Left_Lower_Arm/GrabJoint"
@onready var RightGrabJoint = $"Armature/Skeleton3D/Physical Bone Right_Lower_Arm/GrabJoint"
@onready var Skeleton = $Armature/Skeleton3D
@export var plane: MeshInstance3D
@export var totalHeadDamageTreshold: float = 0.03
@export var knocked_out: bool = false
@onready var LeftHand: SkeletonIK3D = $Armature/Skeleton3D/LeftHand
@onready var LeftHandTarget: Marker3D = $Armature/Skeleton3D/LeftHandTarget
signal box_entered

var left_upper_arm: Quaternion
var left_shoulder: Quaternion
var totalHeadDamage = 0.0
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
var JumpStrength = 200.0
var LeftHandActive = false
var RightHandActive = false
var LeftHandGrab = null
var RightHandGrab = null
# Called when the node enters the scene tree for the first time.
func _ready():
	spine = get_node("Armature/Skeleton3D/Physical Bone Spine")
	head = get_node("Armature/Skeleton3D/Physical Bone Head")
	left_hip = get_node("Armature/Skeleton3D/Physical Bone Left_Hip")
	right_hip =  get_node("Armature/Skeleton3D/Physical Bone Right_Hip")
	$"Armature/Skeleton3D".physical_bones_start_simulation()
	physics_bones = get_children().filter(func(x): return x is PhysicalBone3D)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	CameraPivot.global_transform.origin = head.global_transform.origin
	handle_rotation()
	HandleGrab()

func _physics_process(delta):
	if(knocked_out != true):
		walk(delta)
		handle_punch()
	pass

func handle_rotation():
	BodyControl.rotation.y = CameraPivot.rotation.y
	pass

func _input(event):
	if Input.is_action_just_pressed("left_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
		
	if event is InputEventMouseMotion:
		CameraPivot.rotation_degrees.y -= event.relative.x * Mouse_sensitivity
		CameraPivot.rotation_degrees.x -= event.relative.y * Mouse_sensitivity
		CameraPivot.rotation_degrees.x = clamp(CameraPivot.rotation_degrees.x, -90, 90)
		pass


func walk(delta):
	
	Iswalking = false
	if Input.is_physical_key_pressed(KEY_W):
		Iswalking = true
		spine.apply_central_impulse(BodyControl.transform.basis.z * walk_speed)

	if Input.is_physical_key_pressed(KEY_S):
		Iswalking = true
		spine.apply_central_impulse(-BodyControl.transform.basis.z * walk_speed)
	
	if Input.is_physical_key_pressed(KEY_D):
		Iswalking = true
		right_hip.apply_central_impulse(-BodyControl.transform.basis.x * walk_speed)
		
	if Input.is_physical_key_pressed(KEY_A):
		Iswalking = true
		left_hip.apply_central_impulse(BodyControl.transform.basis.x * walk_speed)
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
	RightLegControl.rotation.x = sin(WalkAnimationTimer) 
	LeftLegControl.rotation.x= -sin(WalkAnimationTimer)
	
func AnimateJump():
	JumpAnimationTimer += 0.1

func HandleGrab():
	if (Input.is_action_pressed("left_mouse") && knocked_out != true):
		LeftArmControl.rotation.y = - 1.5
		LeftArmControl.rotation.x = CameraPivot.rotation.x
		
		LeftHandActive = true
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
		BodyControl.rotation.x = 0
		#left_shoulder.y = 0.0
		#left_upper_arm.x = 0.0
		LeftGrabJoint.set_node_a("")
		LeftGrabJoint.set_node_b("")
		LeftHandGrab = null
		
	if (Input.is_action_pressed("right_mouse")  && knocked_out != true):

		RightArmControl.rotation.y = - 1.5
		RightArmControl.rotation.x = CameraPivot.rotation.x
		RightHandActive= true
		RightArmControl.get_node("RightUpperArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		RightArmControl.get_node("RightUpperArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		RightArmControl.get_node("RightUpperArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		RightArmControl.get_node("RightLowerArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		RightArmControl.get_node("RightLowerArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
		RightArmControl.get_node("RightLowerArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
	else:
		RightArmControl.get_node("RightUpperArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		RightArmControl.get_node("RightUpperArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		RightArmControl.get_node("RightUpperArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		RightArmControl.get_node("RightLowerArm6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		RightArmControl.get_node("RightLowerArm6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		RightArmControl.get_node("RightLowerArm6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
		RightHandActive = false
		BodyControl.rotation.x = 0
		
		RightGrabJoint.set_node_a("")
		RightGrabJoint.set_node_b("")
		RightHandGrab = null

func left_punch():
	pass
	#get_tree().create_tween()
	#print_debug("We are in left punch")
	#LeftHand = get_node("Armature/Skeleton3D/LeftHand")
	#LeftHand.start()
	#var left_shoulder = Skeleton.find_bone("Left_Shoulder")
	#var left_upper_arm = Skeleton.find_bone("Left_Upper_Arm")
	#var left_shoulder_rotation = Skeleton.get_bone_pose_rotation(left_shoulder)
	#var left_upper_arm_rotation =  Skeleton.get_bone_pose_rotation(left_upper_arm)
	#left_shoulder_rotation.y = 0.225
	#left_upper_arm_rotation.x = 1.198
	#Skeleton.set_bone_pose_rotation(left_shoulder,left_shoulder_rotation)
	#Skeleton.set_bone_pose_rotation(left_upper_arm, left_upper_arm_rotation)
	#Skeleton.set_bone_enabled(left_shoulder,true)
	#Skeleton.set_bone_enabled(left_upper_arm,true)
	#print_debug(left_shoulder_rotation)
	
func release_left_punch():
	print_debug("We are leaving left punch")
	#LeftHand.
	#4.928
func handle_punch():
	if (Input.is_action_pressed("q") && knocked_out != true):
		left_punch()
	if (Input.is_action_just_released("q") && knocked_out != true):
		release_left_punch()

func _on_RightHand_3d_body_entered(b):
	if RightHandActive:
		if b.is_in_group("CanGrab"):
			if RightHandGrab == null:
				RightGrabJoint.set_node_a(RightLowerArm.get_path())
				RightGrabJoint.set_node_b(b.get_path())
				RightHandGrab = b


func _on_LeftHand_3d_body_entered(b):
	if LeftHandActive:
		if b.is_in_group("CanGrab"):
			if LeftHandGrab == null:
				LeftGrabJoint.set_node_a(LeftLowerArm.get_path())
				LeftGrabJoint.set_node_b(b.get_path())
				LeftHandGrab = b # Replace with function body.





func _on_Body_3d_body_entered(body):
	if body.is_in_group("CanGrab"):
		if body.name == "Box":
			print_debug("We are in head")
			box_entered.emit()
				
			#body. # Replace with function body.


func _on_Head_3d_body_entered(body):
	if body.is_in_group("CanGrab"):
		if body.name == "Box":
			pass
			#BodyControl.get_node("Body6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#BodyControl.get_node("Body6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#BodyControl.get_node("Body6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#LeftLegControl.get_node("LeftUpperLeg6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#LeftLegControl.get_node("LeftUpperLeg6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#LeftLegControl.get_node("LeftUpperLeg6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#
			#RightLegControl.get_node("RightUpperLeg6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#RightLegControl.get_node("RightUpperLeg6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#RightLegControl.get_node("RightUpperLeg6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#await get_tree().create_timer(0.5).timeout

func ragdoll():
	BodyControl.get_node("Body6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	BodyControl.get_node("Body6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	BodyControl.get_node("Body6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	#LeftLegControl.get_node("LeftUpperLeg6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	#LeftLegControl.get_node("LeftUpperLeg6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	#LeftLegControl.get_node("LeftUpperLeg6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
			#
	#RightLegControl.get_node("RightUpperLeg6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	#RightLegControl.get_node("RightUpperLeg6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	#RightLegControl.get_node("RightUpperLeg6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,false)
	await get_tree().create_timer(5).timeout
	knocked_out = false
	active_ragdoll()
		
func active_ragdoll():
	BodyControl.get_node("Body6DOFJoint3D").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
	BodyControl.get_node("Body6DOFJoint3D").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
	BodyControl.get_node("Body6DOFJoint3D").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
	NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
	NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)
	NeckControl.get_node("NeckGeneric6DOFJoint").set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING,true)

func _on_head_rigid_total_force_signal_with_body(force, body):
	print_debug(force,"box owner", body.owner, "my owner", owner)
	if(body.owner != owner):
		totalHeadDamage += force
		print_debug(totalHeadDamage)
		if(totalHeadDamage >= totalHeadDamageTreshold):
			knocked_out = true
			ragdoll()
	pass # Replace with function body.
