extends VehicleBody3D

class_name PlayerVehicle

# Настройки
@export var max_speed = 20.0
@export var acceleration = 5.0
@export var steering_speed = 2.0
@export var camera_modes = {
    "first_person": $CameraPivot/FirstPersonCamera,
    "third_person": $CameraPivot/ThirdPersonCamera,
    "orbit": $CameraPivot/OrbitCamera
}

# Состояние
var current_driver = null
var current_camera_mode = "third_person"
var orbit_angle = 0.0
var is_player_controlling = false

func _ready():
    # Отключаем все камеры при старте
    for camera in camera_modes.values():
        camera.clear_current()
    
    # Настройка коллизии
    $InteractionArea.body_entered.connect(_on_body_entered)

func _physics_process(delta):
    if is_player_controlling:
        handle_movement(delta)
    
    # Плавное торможение когда никто не управляет
    if not is_player_controlling and linear_velocity.length() > 0.1:
        brake = 0.5
    else:
        brake = 0.0

func _input(event):
    if not is_player_controlling: return
    
    # Переключение камеры
    if event.is_action_pressed("change_camera"):
        cycle_camera_mode()
    
    # Вращение камеры
    if event is InputEventMouseMotion:
        handle_camera_rotation(event)

func handle_movement(delta):
    # Управление движением
    var steer_input = Input.get_axis("steer_right", "steer_left")
    var accel_input = Input.get_axis("brake", "accelerate")
    
    steering = move_toward(steering, steer_input * 0.4, delta * steering_speed)
    engine_force = accel_input * acceleration * 100.0
    
    # Ручной тормоз
    brake = 1.0 if Input.is_action_pressed("handbrake") else 0.0
    
    # Ограничение скорости
    if linear_velocity.length() > max_speed:
        linear_velocity = linear_velocity.normalized() * max_speed

func handle_camera_rotation(event):
    match current_camera_mode:
        "first_person":
            rotate_y(-event.relative.x * 0.005)
            camera_modes["first_person"].rotate_x(-event.relative.y * 0.005)
            camera_modes["first_person"].rotation.x = clamp(
                camera_modes["first_person"].rotation.x, 
                deg_to_rad(-70), 
                deg_to_rad(70)
            )
        "orbit":
            orbit_angle += event.relative.x * 0.01
            camera_modes["orbit"].rotation.y = orbit_angle

func cycle_camera_mode():
    var modes = camera_modes.keys()
    var current_index = modes.find(current_camera_mode)
    current_camera_mode = modes[(current_index + 1) % modes.size()]
    
    # Активируем новую камеру
    for name, camera in camera_modes:
        camera.clear_current()
    camera_modes[current_camera_mode].make_current()

func take_control(player):
    current_driver = player
    is_player_controlling = true
    set_process_input(true)
    
    # Переключаем камеру
    camera_modes[current_camera_mode].make_current()
    
    # Отключаем управление игроком
    player.set_process_input(false)
    player.get_node("Camera").clear_current()

func release_control():
    if current_driver:
        current_driver.set_process_input(true)
        current_driver.get_node("Camera").make_current()
    
    current_driver = null
    is_player_controlling = false
    set_process_input(false)
    
    # Возвращаем камеру игроку
    for camera in camera_modes.values():
        camera.clear_current()

func _on_body_entered(body):
    if body.is_in_group("player") and Input.is_action_pressed("interact"):
        if current_driver == null:
            take_control(body)
        elif current_driver == body:
            release_control()
            body.global_transform = $ExitPosition.global_transform
