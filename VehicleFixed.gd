extends VehicleBody3D

class_name PlayerVehicle

# Настройки движения
@export var max_speed = 20.0
@export var acceleration = 5.0
@export var steering_speed = 2.0
@export var brake_force = 4.0

# Настройки камеры
@export var camera_distance = 5.0
@export var camera_height = 2.0
@export var camera_sensitivity = 0.005
@export var orbit_camera_distance = 3.0

# Состояния камеры
enum CameraMode { FIRST_PERSON, THIRD_PERSON, ORBIT }
var current_camera_mode = CameraMode.THIRD_PERSON
var orbit_angle = 0.0
var orbit_vertical_angle = 0.0

# Управление
var is_player_controlling = false
var current_driver = null

# Узлы камеры
@onready var camera_pivot = $CameraPivot
@onready var first_person_camera = $CameraPivot/FirstPersonCamera
@onready var third_person_camera = $CameraPivot/ThirdPersonCamera
@onready var orbit_camera = $CameraPivot/OrbitCamera
@onready var exit_position = $ExitPosition

func _ready():
    # Инициализация камер
    if not first_person_camera:
        first_person_camera = Camera3D.new()
        first_person_camera.name = "FirstPersonCamera"
        camera_pivot.add_child(first_person_camera)
    
    if not third_person_camera:
        third_person_camera = Camera3D.new()
        third_person_camera.name = "ThirdPersonCamera"
        camera_pivot.add_child(third_person_camera)
    
    if not orbit_camera:
        orbit_camera = Camera3D.new()
        orbit_camera.name = "OrbitCamera"
        camera_pivot.add_child(orbit_camera)
    
    # Начальная настройка камер
    setup_cameras()
    update_camera_mode()

func setup_cameras():
    # Позиция камеры от первого лица (в салоне)
    first_person_camera.position = Vector3(0, 0.5, 0.3)
    first_person_camera.fov = 75
    
    # Позиция камеры от третьего лица (сзади)
    third_person_camera.position = Vector3(0, 1.5, -camera_distance)
    third_person_camera.look_at(position)
    
    # Позиция орбитальной камеры
    orbit_camera.position = Vector3(0, 0, 0)
    orbit_camera.fov = 85

func _physics_process(delta):
    if is_player_controlling:
        handle_vehicle_input(delta)
        handle_camera_behavior(delta)

func _input(event):
    if is_player_controlling:
        if event.is_action_pressed("change_camera"):
            cycle_camera_mode()
        
        if event is InputEventMouseMotion:
            handle_camera_rotation(event)

func handle_vehicle_input(delta):
    # Управление движением
    var steer_input = Input.get_axis("steer_right", "steer_left")
    var accel_input = Input.get_axis("brake", "accelerate")
    
    steering = move_toward(steering, steer_input * 0.4, delta * steering_speed)
    engine_force = accel_input * acceleration * 100.0
    
    # Ручной тормоз
    brake = brake_force if Input.is_action_pressed("handbrake") else 0.0
    
    # Ограничение скорости
    if linear_velocity.length() > max_speed:
        linear_velocity = linear_velocity.normalized() * max_speed

func handle_camera_behavior(delta):
    # Плавное перемещение камеры третьего лица
    if current_camera_mode == CameraMode.THIRD_PERSON:
        var target_pos = Vector3(0, camera_height, -camera_distance)
        camera_pivot.position = camera_pivot.position.lerp(target_pos, delta * 5.0)

func handle_camera_rotation(event: InputEventMouseMotion):
    match current_camera_mode:
        CameraMode.FIRST_PERSON:
            # Вращение от первого лица
            rotate_y(-event.relative.x * camera_sensitivity)
            first_person_camera.rotate_x(-event.relative.y * camera_sensitivity)
            first_person_camera.rotation.x = clamp(
                first_person_camera.rotation.x,
                deg_to_rad(-70),  # Макс. угол вверх
                deg_to_rad(70)    # Макс. угол вниз
            )
        
        CameraMode.ORBIT:
            # Вращение вокруг машины
            orbit_angle += event.relative.x * camera_sensitivity
            orbit_vertical_angle = clamp(
                orbit_vertical_angle - event.relative.y * camera_sensitivity,
                deg_to_rad(-30),  # Макс. угол вверх
                deg_to_rad(30)    # Макс. угол вниз
            )
            
            # Вычисляем позицию камеры
            var offset = Vector3(
                sin(orbit_angle) * orbit_camera_distance,
                orbit_vertical_angle * 2.0 + 1.5,
                cos(orbit_angle) * orbit_camera_distance
            )
            
            orbit_camera.transform.origin = offset
            orbit_camera.look_at(Vector3.ZERO)

func cycle_camera_mode():
    current_camera_mode = (current_camera_mode + 1) % 3
    update_camera_mode()

func update_camera_mode():
    # Отключаем все камеры
    for camera in [first_person_camera, third_person_camera, orbit_camera]:
        camera.clear_current()
    
    # Включаем нужную камеру
    match current_camera_mode:
        CameraMode.FIRST_PERSON:
            first_person_camera.make_current()
        CameraMode.THIRD_PERSON:
            third_person_camera.make_current()
        CameraMode.ORBIT:
            orbit_camera.make_current()

func enter_vehicle(player):
    if is_player_controlling:
        return false
    
    current_driver = player
    is_player_controlling = true
    
    # Отключаем управление игроком
    player.set_process_input(false)
    player.get_node("Camera").clear_current()
    
    # Включаем управление машиной
    set_process_input(true)
    update_camera_mode()
    
    return true

func exit_vehicle():
    if not is_player_controlling:
        return
    
    # Возвращаем управление игроку
    current_driver.set_process_input(true)
    current_driver.get_node("Camera").make_current()
    
    # Сбрасываем состояние
    current_driver = null
    is_player_controlling = false
    
    # Отключаем все камеры машины
    for camera in [first_person_camera, third_person_camera, orbit_camera]:
        camera.clear_current()

func _on_interaction_area_body_entered(body):
    if body.is_in_group("player") and Input.is_action_just_pressed("interact"):
        if not is_player_controlling:
            enter_vehicle(body)
        else:
            exit_vehicle()
            body.global_transform = exit_position.global_transform
