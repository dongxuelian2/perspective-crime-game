class_name FoldMath
extends RefCounted
## Orthographic folds are geometric, not a lookup table of allowed views.
## A depth translation parallel to the viewing ray has zero screen displacement.
const ELEVATION := PI / 6.0
const FIRST_A := Vector3(-1.2, 0.0, 3.0)
const FIRST_VIEW := 3.0 * PI / 4.0
const SECOND_A := Vector3(3.4, 1.9, -2.3)
const SECOND_VIEW := 5.0 * PI / 4.0
const THIRD_A := Vector3(-3.4, 4.1, -3.2)
const THIRD_VIEW := PI / 4.0

static func view_ray(angle: float) -> Vector3:
	return Vector3(sin(angle) * cos(ELEVATION), sin(ELEVATION), cos(angle) * cos(ELEVATION))

static func folds() -> Array[Dictionary]:
	return [
		{"a": FIRST_A, "b": FIRST_A + view_ray(FIRST_VIEW) * 3.8, "distance": 3.8},
		{"a": SECOND_A, "b": SECOND_A + view_ray(SECOND_VIEW) * 4.4, "distance": 4.4},
		{"a": THIRD_A, "b": THIRD_A + view_ray(THIRD_VIEW) * 3.8, "distance": 3.8}
	]

static func projected_gap(camera: Camera3D, a: Vector3, b: Vector3, viewport: Rect2) -> float:
	if camera.is_position_behind(a) or camera.is_position_behind(b):
		return INF
	if not camera.is_position_in_frustum(a) or not camera.is_position_in_frustum(b):
		return INF
	var screen_a := camera.unproject_position(a)
	var screen_b := camera.unproject_position(b)
	if not viewport.has_point(screen_a) or not viewport.has_point(screen_b):
		return INF
	return screen_a.distance_to(screen_b)
