extends Node3D
## MegaKit seviyeleri için yükleme sonrası düzeltmeler:
## - Opak gelen pencere camlarını gerçek şeffaf cama çevirir.

static var _glass: StandardMaterial3D


func _ready() -> void:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.albedo_color = Color(0.55, 0.75, 0.95, 0.12)
		_glass.metallic = 0.6
		_glass.roughness = 0.05
		_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null:
			continue
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.mesh.surface_get_material(i)
			if mat and mat.resource_name == "M_Glass":
				mesh.set_surface_override_material(i, _glass)
