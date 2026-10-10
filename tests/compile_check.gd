extends SceneTree
## Carica tutti gli script del progetto per scoprire subito gli errori di compilazione.
func _init() -> void:
	var bad := 0
	for dir in ["res://scripts/core", "res://scripts/ai", "res://scripts/ui", "res://tests"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				var sc = load(dir.path_join(f))
				if sc == null or not sc.can_instantiate():
					print("ERRORE in ", dir.path_join(f))
					bad += 1
	print("compilazione: ", "OK" if bad == 0 else "%d script con errori" % bad)
	quit(bad)
