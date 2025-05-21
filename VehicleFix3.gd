# Добавьте в начало скрипта (после class_name)
enum CameraMode { FIRST_PERSON, THIRD_PERSON, ORBIT }
var current_camera_mode: CameraMode = CameraMode.THIRD_PERSON
var cameras_initialized = false

func _ready():
    initialize_cameras()
    update_camera_mode()

func initialize_cameras():
    camera_pivot = $CameraPivot
    
    # Безопасная инициализация камер
    first_person_camera = camera_pivot.get_node_or_null("FirstPersonCamera")
    third_person_camera = camera_pivot.get_node_or_null("ThirdPersonCamera")
    orbit_camera = camera_pivot.get_node_or_null("OrbitCamera")
    
    if first_person_camera and third_person_camera and orbit_camera:
        cameras_initialized = true
    else:
        push_error("Не все камеры инициализированы!")

func handle_camera_rotation(event: InputEventMouseMotion):
    if not cameras_initialized:
        return
    
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
            camera_pivot.rotation.y = orbit_angle
            
            # Наклон камеры вверх/вниз
            var vertical_angle = clamp(
                camera_pivot.rotation.x - event.relative.y * camera_sensitivity * 0.5,
                deg_to_rad(-30),  # Макс. угол вверх
                deg_to_rad(30)    # Макс. угол вниз
            )
            camera_pivot.rotation.x = vertical_angle

func update_camera_mode():
    if not cameras_initialized:
        return
    
    # Отключаем все камеры
    for camera in [first_person_camera, third_person_camera, orbit_camera]:
        camera.clear_current()
    
    # Включаем нужную камеру
    var active_camera: Camera3D
    match current_camera_mode:
        CameraMode.FIRST_PERSON:
            active_camera = first_person_camera
            camera_pivot.position = Vector3.ZERO
            
        CameraMode.THIRD_PERSON:
            active_camera = third_person_camera
            camera_pivot.position = Vector3(0, camera_height, -camera_distance)
            
        CameraMode.ORBIT:
            active_camera = orbit_camera
            camera_pivot.position = Vector3.ZERO
    
    if active_camera:
        active_camera.make_current()
    else:
        push_error("Активная камера не найдена для режима: ", current_camera_mode)
