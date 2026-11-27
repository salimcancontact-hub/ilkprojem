extends SceneTree
func _initialize():
	for k in ["rendering/shader_compiler/shader_cache/enabled", "rendering/shader_compiler/shader_cache/compress", "rendering/shader_compiler/shader_cache/use_zstd_compression", "rendering/gl_compatibility/driver", "rendering/environment/defaults/default_clear_color"]:
		print(k, " = ", ProjectSettings.get_setting(k, "YOK"), " var=", ProjectSettings.has_setting(k))
	quit()
