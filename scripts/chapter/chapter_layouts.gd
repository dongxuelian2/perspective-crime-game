extends RefCounted
## Authored puzzle topology. Positions are actual world-space feet/hinge origins.
static var RAY := Vector3(12,16,22).normalized()
static func count() -> int: return 5
static func get_layout(index: int) -> Dictionary:
	var d := {"fixed": [], "seams": [], "pins": [], "groups": [], "gates": [], "docks": [], "counterweight": [], "offsets": {}, "target": Vector3(0,1,0), "size": 23.0}
	match index:
		0:
			d.merge({"name":"The Folded Quay", "exit":"E", "points":{
				"A":Vector3(-6,0,3), "B":Vector3(-2,0,3), "R":Vector3(2,0,3),
				"C":Vector3(-3,4,3), "D":Vector3(-3,4,-1), "E":Vector3(1,4,-1)},
				"mechanisms":[
					{"kind":"hinge","a":"A","b":"B","start":-PI/2},
					{"kind":"lift","a":"B","carrier":"R","start":0.0,"docks":["C"]},
					{"kind":"hinge","a":"C","b":"D","start":PI}],
				"fixed":[["D","E"]]},true)
		1:
			d.merge({"name":"The Sorting House", "exit":"F", "points":{
				"A":Vector3(-5,0,-3), "B":Vector3(-5,0,1), "R":Vector3(-3.5,0,1),
				"C":Vector3(5,0,1), "S":Vector3(5,4,1), "D":Vector3(5,4,.5),
				"E":Vector3(1,4,.5), "F":Vector3(1,4,-3.5)},
				"mechanisms":[
					{"kind":"shuttle","at":Vector3(0,0,1),"carrier":"R","start":-3.5,"docks":["B","C"]},
					{"kind":"lift","a":"C","carrier":"S","start":PI/2,"yaw":-PI/2,"interactive":false,"docks":["D"]},
					{"kind":"hinge","a":"E","b":"F","start":0.0}],
				"fixed":[["A","B"],["D","E"]], "counterweight":[0,1]},true)
		2:
			var seam := Vector3(-1,0,-1) + RAY*5
			d.merge({"name":"The False Facade", "exit":"F", "size":24.0, "target":Vector3(1,2,0), "points":{
				"A":Vector3(-5,0,3), "B":Vector3(-1,0,3), "C":Vector3(-1,0,-1),
				"D":seam+Vector3(2,0,0), "E":seam+Vector3(4,0,0),
				"R":seam+Vector3(8,0,0), "F":seam+Vector3(3,4,0)},
				"mechanisms":[
					{"kind":"hinge","a":"A","b":"B","start":PI/2},
					{"kind":"slide","at":seam,"carrier":"D","start":2.0},
					{"kind":"hinge","a":"D","b":"E","start":PI/2,"follows":"D"},
					{"kind":"lift","a":"E","carrier":"R","start":0.0,"docks":["F"]}],
				"fixed":[["B","C"]],"seams":[["C","D"]]},true)
		3:
			d.merge({"name":"The Hinged Archive", "exit":"E", "target":Vector3(0,0,0), "size":21.0, "points":{
				"A":Vector3(-5,0,3), "B":Vector3(-1,0,3), "C":Vector3(-1,0,-1),
				"D":Vector3(3,0,-1), "E":Vector3(3,0,-5)},
				"mechanisms":[
					{"kind":"hinge","a":"A","b":"B","start":PI/2},
					{"kind":"hinge","a":"B","b":"C","start":PI/2},
					{"kind":"hinge","a":"C","b":"D","start":PI/2}],
				"groups":[[0,1,2]],"pins":[{"at":"B","locks":0},{"at":"C","locks":1}],
				"gates":[{"at":"C","requires":0,"value":0.0},{"at":"D","requires":1,"value":PI/2}],
				"fixed":[["D","E"]]},true)
		4:
			var seam := Vector3(-2,4,-1) + RAY*4
			d.merge({"name":"The Undeliverable Tower", "exit":"E", "target":Vector3(1,2.5,0), "size":25.0, "points":{
				"A":Vector3(-5,0,3), "B":Vector3(-1,0,3), "R":Vector3(3,0,3),
				"C":Vector3(-2,4,3), "D":Vector3(-2,4,-1), "S":seam+Vector3(2,0,0),
				"T":seam+Vector3(4,0,0), "E":seam+Vector3(4,0,-4)},
				"mechanisms":[
					{"kind":"hinge","a":"A","b":"B","start":PI/2},
					{"kind":"lift","a":"B","carrier":"R","start":0.0,"docks":["C"]},
					{"kind":"hinge","a":"C","b":"D","start":-PI/2},
					{"kind":"slide","at":seam,"carrier":"S","start":2.0},
					{"kind":"hinge","a":"S","b":"T","start":PI/2,"follows":"S"}],
				"groups":[[0,2]],"offsets":{2:PI},"pins":[{"at":"C","locks":0}],
				"gates":[{"at":"D","requires":0,"value":0.0}],
				"fixed":[["T","E"]],"seams":[["D","S"]]},true)
	return d
