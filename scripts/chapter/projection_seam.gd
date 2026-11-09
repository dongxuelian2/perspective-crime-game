extends RefCounted
## An explicitly authored, screen-continuous non-Euclidean edge.
## Endpoint medallions remain visible through decorative geometry by design.
static func aligned(camera: Camera3D, a: Vector3, b: Vector3, tolerance := 12.0) -> bool:
	if camera.is_position_behind(a) or camera.is_position_behind(b): return false
	var rect := camera.get_viewport().get_visible_rect()
	var pa := camera.unproject_position(a)
	var pb := camera.unproject_position(b)
	return rect.has_point(pa) and rect.has_point(pb) and pa.distance_to(pb) < tolerance
