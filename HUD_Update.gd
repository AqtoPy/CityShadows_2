# Добавляем в HUD.gd
func show_message(text: String, duration: float = 2.0):
    $MessagePanel.visible = true
    $MessagePanel/MessageLabel.text = text
    await get_tree().create_timer(duration).timeout
    $MessagePanel.visible = false
