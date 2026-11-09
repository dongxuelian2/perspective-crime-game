extends RefCounted
## Geometry-derived graph; all movement queries use the current graph snapshot.
var points: Dictionary = {}
var edges: Dictionary = {}
func add_point(id: String, p: Vector3) -> void:
	points[id] = p
	edges[id] = []
func connect_points(a: String, b: String) -> void:
	if not edges[a].has(b): edges[a].append(b)
	if not edges[b].has(a): edges[b].append(a)
func route(start: String, goal: String) -> Array:
	if not points.has(start) or not points.has(goal): return []
	var queue: Array = [start]
	var previous := {start: ""}
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if current == goal:
			var result: Array = [goal]
			while result[0] != start: result.push_front(previous[result[0]])
			return result
		for other in edges[current]:
			if not previous.has(other):
				previous[other] = current
				queue.append(other)
	return []
