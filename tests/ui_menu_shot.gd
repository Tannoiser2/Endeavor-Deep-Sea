extends SceneTree
## Screenshot del menu iniziale. Uso: godot --path . -s res://tests/ui_menu_shot.gd -- <cartella>
var frames := 0
func _initialize() -> void:
	root.add_child(load("res://scenes/main.tscn").instantiate())
func _process(_d: float) -> bool:
	frames += 1
	if frames == 5:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join("shot_menu.png"))
		return true
	return false
