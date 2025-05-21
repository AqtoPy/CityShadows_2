extends VehicleBody3D

class_name PlayerVehicle

# Настройки камеры
@export var camera_distance = 5.0
@export var camera_height = 2.0
@export var camera_sensitivity = 0.01

# Узлы камер (будем искать в ready)
var first_person_camera: Camera3D
var third_person_camera: Camera3D
var orbit_camera: Camera3D
var camera_pivot: Node3D

# Состояние
enum CameraMode { FIRST_PERSON, THIRD_PERSON, ORBIT }
var current_camera_mode = CameraMode.THIRD_PERSON
var is_player_controlling = false

func _ready():
    # Инициализация камер
    camera_pivot = $CameraPivot
    first_person_camera = $CameraPivot/FirstPersonCamera
    third_person_camera = $CameraPivot/ThirdPersonCamera
    orbit_camera = $CameraPivot/OrbitCamera
    
    # Проверка наличия камер
    if not first_person_camera:
        push_error("FirstPersonCamera not found!")
    if not third_person_camera:
        push_error("ThirdPersonCamera not found!")
    if not orbit_camera:
        push_error("OrbitCamera not found!")
    
    update_camera_mode()

func _physics_process(delta):
    if is_player_controlling:
        handle_vehicle_input()

func update_camera_mode():
    # Отключаем все камеры
    first_person_camera.clear_current()
    third_person_camera.clear_current()
    orbit_camera.clear_current()
    
    # Включаем текущую камеру
    match current_camera_mode:
        CameraMode.FIRST_PERSON:
            first_person_camera.make_current()
        CameraMode.THIRD_PERSON:
            third_person_camera.make_current()
            camera_pivot.position = Vector3(0, camera_height, -camera_distance)
        CameraMode.ORBIT:
            orbit_camera.make_current()
            camera_pivot.position = Vector3.ZERO

func cycle_camera_mode():
    current_camera_mode = (current_camera_mode + 1) % 3
    update_camera_mode()

func handle_vehicle_input():
    # Управление движением
    engine_force = Input.get_axis("brake", "accelerate") * 500.0
    steering = Input.get_axis("steer_right", "steer_left") * 0.4
    brake = 1.0 if Input.is_action_pressed("handbrake") else 0.0
    
    # Переключение камеры
    if Input.is_action_just_pressed("change_camera"):
        cycle_camera_mode()

func enter_vehicle(player):
    is_player_controlling = true
    player.get_node("Camera").clear_current()
    update_camera_mode()

func exit_vehicle(player):
    is_player_controlling = false
    player.get_node("Camera").make_current()
    for camera in [first_person_camera, third_person_camera, orbit_camera]:
        camera.clear_current()
