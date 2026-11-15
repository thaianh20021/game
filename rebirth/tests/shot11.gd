extends SceneTree
# Picture of the blessing screen on the phone view (run without --headless).
const Meta = preload("res://src/meta.gd")
const D = preload("res://src/data.gd")
var g
func frames(n):
	for k in n: await process_frame
func _initialize():
	Meta.PATH = "user://rebirth_shot11.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Meta.PATH))
	g = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(g)
	await frames(10)
	Meta.S.pet = ""
	Meta.S["tut"] = true
	g.start_run(5, false)
	g.sim["zoom"] = true
	g.tin.on = true
	g.fit()
	await frames(30)
	g.offer_buffs(true)
	var want = ["inf_reap", "inf_cap", "vital"]
	for i in 3:
		for b in D.BUFFS:
			if b.id == want[i]:
				g.buff_choices[i] = b
	await frames(20)
	root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_buff.png")
	g.pick_buff(0)
	g.p.inf = [{key = "fire+ice", col = Color("d8f6ff")}, {key = "fire+water", col = Color("bbb2b5")}, {key = "bolt+ice", col = Color("ffe45c")}]
	g.p.inf_t = 8.0
	await frames(20)
	root.get_texture().get_image().save_png("C:/Users/ADMIN/AppData/Local/Temp/rb_charged.png")
	quit()
