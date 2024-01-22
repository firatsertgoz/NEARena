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

@onready var LeftHandIK = $Armature/Skeleton3D/LeftHand
@onready var RightHandIK = $Armature/Skeleton3D/RightHand
@onready var Torso = $"Armature/Skeleton3D/Physical Bone Torso"
@onready var TorsoRB = $"Armature/Skeleton3D/Physical Bone Torso/RigidBody3D"
@onready var RightLowerArm = $"Armature/Skeleton3D/Physical Bone Right_Lower_Arm"
@onready var LeftLowerArm = $"Armature/Skeleton3D/Physical Bone Left_Lower_Arm"
@onready var LeftGrabJoint = $"Armature/Skeleton3D/Physical Bone Left_Lower_Arm/GrabJoint"
@onready var RightGrabJoint = $"Armature/Skeleton3D/Physical Bone Right_Lower_Arm/GrabJoint"
@export var plane: MeshInstance3D
@export var totalHeadDamageTreshold: float = 0.03
@export var knocked_out: bool = false
signal box_entered


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
	pass
func _physics_process(delta):

	pass

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
