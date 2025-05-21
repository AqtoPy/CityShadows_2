extends VehicleBody3D

class_name PlayerVehicle

## Настройки автомобиля
@export var max_passengers = 4
@export var camera_distance = 5.0
@export var camera_height = 2.0
@export var camera_sensitivity = 0.01

## Состояние автомобиля
enum CameraMode { FIRST_PERSON, THIRD_PERSON, ORBIT }
var current_camera_mode = CameraMode.THIRD_PERSON
var passengers = []
var free_seats = []
var orbit_angle = 0.0

## Узлы
@onready var camera_pivot = $CameraPivot
@onready var first_person_camera = $CameraPivot/FirstPersonCamera
@onready var third_person_camera = $CameraPivot/ThirdPersonCamera
@onready var exit_positions = $ExitPositions
@onready var seat_positions = $SeatPositions

func _ready():
    # Инициализация свободных мест
    for i in range(seat_positions.get_child_count()):
        free_seats.append(i)
    
    # Настройка камер
    update_camera_mode()

func _physics_process(delta):
    # Управление камерой в режиме орбиты
    if current_camera_mode == CameraMode.ORBIT:
        orbit_angle += Input.get_axis("camera_left", "camera_right") * delta * 2.0
        camera_pivot.rotation.y = orbit_angle

func _input(event):
    # Переключение режимов камеры
    if Input.is_action_just_pressed("change_camera"):
        cycle_camera_mode()
    
    # Вращение камеры от первого лица
    if current_camera_mode == CameraMode.FIRST_PERSON and event is InputEventMouseMotion:
        rotate_y(-event.relative.x * camera_sensitivity)
        first_person_camera.rotate_x(-event.relative.y * camera_sensitivity)
        first_person_camera.rotation.x = clamp(first_person_camera.rotation.x, deg_to_rad(-70), deg_to_rad(70))

func cycle_camera_mode():
    current_camera_mode = (current_camera_mode + 1) % 3
    update_camera_mode()

func update_camera_mode():
    match current_camera_mode:
        CameraMode.FIRST_PERSON:
            first_person_camera.make_current()
            third_person_camera.clear_current()
        CameraMode.THIRD_PERSON:
            third_person_camera.make_current()
            first_person_camera.clear_current()
            camera_pivot.position = Vector3(0, camera_height, -camera_distance)
        CameraMode.ORBIT:
            third_person_camera.make_current()
            first_person_camera.clear_current()
            camera_pivot.position = Vector3(0, camera_height, 0)

## Система посадки/высадки
func enter_vehicle(character):
    if free_seats.is_empty():
        return false
    
    var seat_index = free_seats.pop_front()
    var seat = seat_positions.get_child(seat_index)
    
    # Прикрепляем персонажа к сиденью
    character.get_parent().remove_child(character)
    seat.add_child(character)
    character.global_transform = Transform3D()
    character.set_process_input(false)
    
    # Если это игрок - передаем управление
    if character.is_in_group("player"):
        take_control(character)
    
    passengers.append({
        "character": character,
        "seat_index": seat_index
    })
    
    return true

func exit_vehicle(character):
    for i in range(passengers.size()):
        if passengers[i]["character"] == character:
            var seat_index = passengers[i]["seat_index"]
            var exit_pos = exit_positions.get_child(seat_index % exit_positions.get_child_count())
            
            # Возвращаем персонажа на сцену
            character.get_parent().remove_child(character)
            get_parent().add_child(character)
            character.global_transform = exit_pos.global_transform
            character.set_process_input(true)
            
            # Освобождаем место
            free_seats.append(seat_index)
            passengers.remove_at(i)
            
            # Если это был игрок - сбрасываем управление
            if character.is_in_group("player"):
                release_control(character)
            
            return true
    return false

func take_control(player):
    # Передаем управление игроку
    player.set_process_input(false)
    set_process_input(true)
    
    # Настраиваем камеру
    update_camera_mode()

func release_control(player):
    # Возвращаем управление игроку
    set_process_input(false)
    player.set_process_input(true)
    player.get_node("Camera").make_current()

## Управление автомобилем
func _unhandled_input(event):
    if passengers.is_empty():
        return
    
    # Только если водитель - игрок
    for passenger in passengers:
        if passenger["character"].is_in_group("player") and passenger["seat_index"] == 0:
            handle_vehicle_input(event)
            break

func handle_vehicle_input(event):
    # Базовое управление
    engine_force = Input.get_axis("brake", "accelerate") * 500.0
    steering = Input.get_axis("steer_right", "steer_left") * 0.4
    
    # Ручной тормоз
    if Input.is_action_pressed("handbrake"):
        brake = 1.0
    else:
        brake = 0.0
    
    # Выход из машины
    if Input.is_action_just_pressed("interact"):
        for passenger in passengers:
            if passenger["character"].is_in_group("player"):
                exit_vehicle(passenger["character"])
                break
