extends VehicleBody3D

class_name Car

# Настройки движения
@export var max_speed = 20.0
@export var acceleration = 300.0
@export var steering_speed = 0.8
@export var brake_force = 5.0

# Настройки камер
@export var third_person_offset = Vector3(0, 2.5, -5)
@export var camera_sensitivity = 0.005

# Состояния
enum CameraMode { FIRST_PERSON, THIRD_PERSON, ORBIT }
var current_camera_mode = CameraMode.THIRD_PERSON
var is_player_inside = false
var orbit_angle = 0.0

# Узлы
@onready var camera_pivot = $CameraPivot
@onready var interaction_area = $InteractionArea
@onready var exit_position = $ExitPosition

var player_ref = null

func _ready():
    # Настройка взаимодействия
    interaction_area.body_entered.connect(_on_body_entered)
    interaction_area.body_exited.connect(_on_body_exited)
    
    # Отключить управление при старте
    set_process_input(false)
    engine_force = 0
    brake = 0
    steering = 0

func _physics_process(delta):
    if is_player_inside:
        handle_movement(delta)

func _input(event):
    if is_player_inside:
        handle_camera_input(event)
        
        if event.is_action_pressed("change_camera"):
            cycle_camera_mode()
            
        if event.is_action_pressed("exit_vehicle"):
            exit_vehicle()

func handle_movement(delta):
    var accelerate = Input.get_action_strength("accelerate")
    var brake = Input.get_action_strength("brake")
    var steer = Input.get_axis("steer_right", "steer_left")
    
    # Управление двигателем и тормозом
    self.engine_force = accelerate * acceleration
    self.brake = brake * brake_force
    
    # Управление рулем
    steering = move_toward(steering, steer * 0.4, delta * steering_speed)
    
    # Ограничение скорости
    if linear_velocity.length() > max_speed:
        linear_velocity = linear_velocity.normalized() * max_speed

func handle_camera_input(event):
    if event is InputEventMouseMotion:
        match current_camera_mode:
            CameraMode.FIRST_PERSON:
                rotate_y(-event.relative.x * camera_sensitivity)
                $CameraPivot/FirstPersonCamera.rotate_x(-event.relative.y * camera_sensitivity)
                $CameraPivot/FirstPersonCamera.rotation.x = clamp(
                    $CameraPivot/FirstPersonCamera.rotation.x, 
                    deg_to_rad(-70), 
                    deg_to_rad(70)
                )
            
            CameraMode.ORBIT:
                orbit_angle += event.relative.x * camera_sensitivity
                camera_pivot.rotation.y = orbit_angle

func cycle_camera_mode():
    current_camera_mode = (current_camera_mode + 1) % 3
    update_camera()

func update_camera():
    for camera in camera_pivot.get_children():
        if camera is Camera3D:
            camera.clear_current()
    
    match current_camera_mode:
        CameraMode.FIRST_PERSON:
            $CameraPivot/FirstPersonCamera.make_current()
        
        CameraMode.THIRD_PERSON:
            $CameraPivot/ThirdPersonCamera.make_current()
            camera_pivot.position = third_person_offset
        
        CameraMode.ORBIT:
            $CameraPivot/OrbitCamera.make_current()
            camera_pivot.position = Vector3.ZERO

func enter_vehicle(player):
    if is_player_inside: return
    
    player_ref = player
    is_player_inside = true
    
    # Отключить управление игроком
    player.set_process_input(false)
    player.get_node("Camera").clear_current()
    
    # Включить управление машиной
    set_process_input(true)
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    update_camera()

func exit_vehicle():
    if !is_player_inside: return
    
    # Вернуть управление игроку
    player_ref.set_process_input(true)
    player_ref.get_node("Camera").make_current()
    player_ref.global_transform = exit_position.global_transform
    
    # Отключить управление машиной
    set_process_input(false)
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    is_player_inside = false
    player_ref = null
    
    # Сброс управления
    engine_force = 0
    brake = 1.0
    steering = 0

func _on_body_entered(body):
    if body.is_in_group("player") and Input.is_action_just_pressed("interact"):
        enter_vehicle(body)

func _on_body_exited(body):
    if body == player_ref:
        exit_vehicle()
