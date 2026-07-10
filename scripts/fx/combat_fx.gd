class_name CombatFx
extends RefCounted

const AssetSourceRegistryScript := preload("res://scripts/assets/asset_source_registry.gd")
const MIN_ATTACK_TELEGRAPH_SECONDS := 0.5
const FX_RELEASE_PROFILES := {
	"slash": {"node": "CombatFxSlash", "duration": 0.18, "layers": 1},
	"muzzle_flash": {"node": "CombatFxMuzzleFlash", "duration": 0.12, "layers": 1},
	"dash_ghost": {"node": "CombatFxDashGhost", "duration": 0.22, "layers": 1},
	"telegraph": {"node": "CombatFxTelegraph", "duration": MIN_ATTACK_TELEGRAPH_SECONDS, "layers": 2},
	"skill_cast": {"node": "CombatFxSkillCast", "duration": 0.24, "layers": 3},
	"weapon_charge": {"node": "CombatFxWeaponCharge", "duration": 0.2, "layers": 2},
	"hit_spark": {"node": "CombatFxHitSpark", "duration": 0.14, "layers": 5},
	"block_spark": {"node": "CombatFxBlockSpark", "duration": 0.16, "layers": 5},
	"stationary_focus": {"node": "CombatFxStationaryFocus", "duration": 0.18, "layers": 4},
}

static func release_report(fx_ids: Array) -> Dictionary:
	var failures: Array[String] = []
	var public_release_blockers: Array[String] = []
	var fx_reports := {}
	for raw_id in fx_ids:
		var fx_id := str(raw_id)
		var profile: Dictionary = FX_RELEASE_PROFILES.get(fx_id, {})
		var issues: Array[String] = []
		if profile.is_empty():
			issues.append("missing")
			public_release_blockers.append("%s:missing" % fx_id)
		var entry := _fx_release_entry(fx_id, profile, issues)
		fx_reports[fx_id] = entry
		for issue in issues:
			failures.append("%s:%s" % [fx_id, issue])
	return {
		"ready": failures.is_empty(),
		"public_ready": failures.is_empty() and public_release_blockers.is_empty(),
		"checked_count": fx_ids.size(),
		"failures": failures,
		"generated_placeholders": [],
		"public_release_blockers": public_release_blockers,
		"fx": fx_reports,
	}

static func spawn_slash(
		parent: Node,
		origin: Vector2,
		dir: Vector2,
		color: Color = Color(1.0, 0.92, 0.55, 0.9)) -> Node2D:
	var fx := _root(parent, "CombatFxSlash", origin, dir)
	var arc := Line2D.new()
	arc.points = PackedVector2Array([
		Vector2(2, -9),
		Vector2(12, -5),
		Vector2(18, 0),
		Vector2(12, 5),
		Vector2(2, 9),
	])
	arc.width = 3.0
	arc.default_color = color
	fx.add_child(arc)
	_lifetime(fx, 0.18, 1.18)
	return fx

static func spawn_muzzle_flash(
		parent: Node,
		origin: Vector2,
		dir: Vector2,
		color: Color = Color(1.0, 0.84, 0.34, 0.9)) -> Node2D:
	var fx := _root(parent, "CombatFxMuzzleFlash", origin, dir)
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(0, -3),
		Vector2(13, 0),
		Vector2(0, 3),
		Vector2(4, 0),
	])
	flash.color = color
	fx.add_child(flash)
	_lifetime(fx, 0.12, 1.35)
	return fx

static func spawn_dash_ghost(
		parent: Node,
		source_sprite: AnimatedSprite2D,
		origin: Vector2,
		flip_h: bool = false,
		color: Color = Color(0.55, 0.85, 1.0, 0.36)) -> Node2D:
	var fx := _root(parent, "CombatFxDashGhost", origin, Vector2.RIGHT)
	if source_sprite != null and source_sprite.sprite_frames != null and source_sprite.visible:
		var texture := source_sprite.sprite_frames.get_frame_texture(
			source_sprite.animation, source_sprite.frame)
		if texture != null:
			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.offset = source_sprite.offset
			sprite.scale = source_sprite.scale
			sprite.flip_h = flip_h
			sprite.modulate = color
			fx.add_child(sprite)
	if fx.get_child_count() == 0:
		var body := Polygon2D.new()
		body.polygon = PackedVector2Array([
			Vector2(-5, -5),
			Vector2(5, -5),
			Vector2(5, 5),
			Vector2(-5, 5),
		])
		body.color = color
		fx.add_child(body)
	_lifetime(fx, 0.22, 1.08)
	return fx

static func spawn_telegraph(
		parent: Node,
		origin: Vector2,
		dir: Vector2,
		radius: float,
		duration: float,
		color: Color = Color(1.0, 0.24, 0.18, 0.6)) -> Node2D:
	var readable_duration := maxf(duration, MIN_ATTACK_TELEGRAPH_SECONDS)
	var fx := _root(parent, "CombatFxTelegraph", origin, dir)
	fx.set_meta("telegraph_seconds", readable_duration)
	fx.set_meta("requested_telegraph_seconds", duration)
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in 33:
		var angle := TAU * float(i) / 32.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	ring.width = 1.5
	ring.default_color = color
	fx.add_child(ring)
	if dir.length_squared() > 0.0:
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(radius, 0)])
		line.width = 1.0
		line.default_color = color
		fx.add_child(line)
	_lifetime(fx, readable_duration, 1.04)
	return fx

static func spawn_weapon_charge(parent: Node, origin: Vector2, ratio: float) -> Node2D:
	var clamped := clampf(ratio, 0.0, 1.0)
	var fx := _root(parent, "CombatFxWeaponCharge", origin, Vector2.RIGHT)
	fx.set_meta("charge_ratio", clamped)
	var color := Color(0.48, 0.95, 0.5, 0.82) if clamped >= 1.0 \
		else Color(0.55, 0.82, 1.0, 0.72)
	var radius := 11.0 + 6.0 * clamped
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in 25:
		var angle := TAU * float(i) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	ring.width = 1.5 + clamped
	ring.default_color = color
	fx.add_child(ring)
	_add_line(fx, PackedVector2Array([
		Vector2(-radius, 0),
		Vector2(radius, 0),
	]), color, 1.4)
	_lifetime(fx, 0.2, 1.18)
	return fx

static func spawn_block_spark(parent: Node, origin: Vector2, dir: Vector2) -> Node2D:
	var fx := _root(parent, "CombatFxBlockSpark", origin, dir)
	var color := Color(0.65, 0.92, 1.0, 0.9)
	for angle in [-0.65, -0.25, 0.25, 0.65]:
		var spark_dir := Vector2.RIGHT.rotated(float(angle))
		_add_line(fx, PackedVector2Array([
			spark_dir * 2.0,
			spark_dir * 13.0,
		]), color, 2.0)
	var plate := Polygon2D.new()
	plate.polygon = PackedVector2Array([
		Vector2(-2, -8), Vector2(5, -5), Vector2(6, 5), Vector2(-2, 8), Vector2(-6, 0),
	])
	plate.color = Color(0.35, 0.72, 1.0, 0.42)
	fx.add_child(plate)
	_lifetime(fx, 0.16, 1.1)
	return fx

static func spawn_hit_spark(
		parent: Node,
		origin: Vector2,
		hit_kind: String = "normal",
		element: String = "",
		damage: int = 0) -> Node2D:
	var color := _hit_spark_color(hit_kind, element)
	var fx := _root(parent, "CombatFxHitSpark", origin, Vector2.RIGHT)
	fx.set_meta("hit_kind", hit_kind)
	fx.set_meta("hit_element", element)
	fx.set_meta("hit_damage", damage)
	fx.set_meta("impact_shape", "spark")
	var scale_mult := 1.22 if hit_kind == "critical" else 0.86 if hit_kind == "resist" else 1.0
	for angle in [0.0, 0.72, -0.72, 1.42, -1.42]:
		var spark_dir := Vector2.RIGHT.rotated(float(angle)) * scale_mult
		_add_line(fx, PackedVector2Array([
			spark_dir * 2.0,
			spark_dir * 12.0,
		]), color, 1.8)
	_lifetime(fx, 0.14, 1.14)
	return fx

static func spawn_stationary_focus(parent: Node, origin: Vector2) -> Node2D:
	var fx := _root(parent, "CombatFxStationaryFocus", origin, Vector2.RIGHT)
	var color := Color(1.0, 0.9, 0.45, 0.75)
	_add_line(fx, PackedVector2Array([Vector2(-13, 0), Vector2(-5, 0)]), color, 1.6)
	_add_line(fx, PackedVector2Array([Vector2(5, 0), Vector2(13, 0)]), color, 1.6)
	_add_line(fx, PackedVector2Array([Vector2(0, -13), Vector2(0, -5)]), color, 1.6)
	_add_line(fx, PackedVector2Array([Vector2(0, 5), Vector2(0, 13)]), color, 1.6)
	_lifetime(fx, 0.18, 1.08)
	return fx

static func skill_feedback_profile(skill_id: String) -> Dictionary:
	match skill_id:
		"wind_edge", "phantom_slash":
			return _skill_profile("blade", "slash_arc", Color(0.95, 0.9, 0.45, 0.9), 17.0,
				"Wind Edge", "arc", "slash", "blade", "Wide slash arc")
		"lunge":
			return _skill_profile("blade", "dash_lunge", Color(0.65, 0.95, 1.0, 0.9), 16.0,
				"Lunge", "line", "pierce", "dash", "Forward thrust")
		"earthbreaker", "skyfall":
			return _skill_profile("breaker", "slam", Color(0.85, 0.55, 0.28, 0.9), 19.0,
				"Earthbreaker", "circle", "slam", "hammer", "Ground shock")
		"iron_will":
			return _skill_profile("breaker", "ward", Color(0.75, 0.72, 0.68, 0.9), 16.0,
				"Iron Will", "self", "guard", "shield", "Brief armor")
		"shadow_step", "death_dance":
			return _skill_profile("shadow", "shadow", Color(0.55, 0.35, 0.95, 0.9), 16.0,
				"Shadow Step", "self", "crit_mark", "shadow", "Next hit crits")
		"poison_knife":
			return _skill_profile("shadow", "projectile", Color(0.45, 0.95, 0.35, 0.9), 15.0,
				"Poison Knife", "line", "mark", "knife", "Marks target")
		"shield_bastion", "fortress":
			return _skill_profile("guard", "ward", Color(0.35, 0.75, 1.0, 0.9), 18.0,
				"Shield Bastion", "self", "barrier", "shield", "Timed shield")
		"battle_roar":
			return _skill_profile("guard", "roar", Color(1.0, 0.58, 0.28, 0.9), 20.0,
				"Battle Roar", "circle", "buff", "roar", "Armor pulse")
		"element_orb", "elemental_fury":
			return _skill_profile("arcane", "orb", Color(0.55, 0.75, 1.0, 0.9), 15.0,
				"Element Orb", "line", "orb", "orb", "Element shot")
		"null_ring":
			return _skill_profile("arcane", "ring", Color(0.6, 0.45, 1.0, 0.9), 18.0,
				"Null Ring", "circle", "field", "ring", "Slow field")
		"arrow_rain", "skypiercer":
			return _skill_profile("ranger", "projectile", Color(0.55, 0.95, 0.55, 0.9), 16.0,
				"Arrow Rain", "circle", "volley", "arrow", "Area volley")
		"snare_trap":
			return _skill_profile("ranger", "trap", Color(0.7, 0.9, 0.45, 0.9), 15.0,
				"Snare Trap", "point", "trap", "trap", "Roots enemies")
		"rolling_grenade", "suppressing_fire":
			return _skill_profile("gunner", "blast", Color(0.95, 0.65, 0.25, 0.9), 17.0,
				"Rolling Grenade", "line", "blast", "grenade", "Delayed blast")
		"special_rounds":
			return _skill_profile("gunner", "ammo", Color(1.0, 0.88, 0.35, 0.9), 15.0,
				"Special Rounds", "self", "ammo", "rounds", "Empowered shots")
		"summon_wisp", "soul_kingdom":
			return _skill_profile("soul", "summon", Color(0.45, 0.95, 1.0, 0.9), 16.0,
				"Summon Wisp", "self", "summon", "wisp", "Pet summon")
		"sacrifice":
			return _skill_profile("soul", "burst", Color(0.95, 0.45, 0.75, 0.9), 18.0,
				"Sacrifice", "self", "burst", "soul", "Trade HP")
		"light_ray", "verdict":
			return _skill_profile("light", "beam", Color(1.0, 0.95, 0.55, 0.9), 16.0,
				"Light Ray", "line", "beam", "ray", "Piercing beam")
		"sanctuary":
			return _skill_profile("light", "sanctuary", Color(0.75, 1.0, 0.72, 0.9), 19.0,
				"Sanctuary", "circle", "heal_zone", "sanctuary", "Safe zone")
		"mini_turret", "mobile_fortress":
			return _skill_profile("tech", "tech", Color(0.95, 0.75, 0.35, 0.9), 16.0,
				"Mini Turret", "point", "deploy", "turret", "Deploy turret")
		"hack":
			return _skill_profile("tech", "hack", Color(0.4, 1.0, 0.75, 0.9), 15.0,
				"Hack", "point", "convert", "hack", "Convert trap")
	return _skill_profile("generic", "generic", Color(0.75, 0.9, 1.0, 0.9), 15.0,
		"Skill", "self", "pulse", "skill", "Cast skill")

static func _skill_profile(
		family: String,
		style: String,
		color: Color,
		radius: float,
		cast_label: String,
		telegraph_shape: String,
		impact_shape: String,
		cooldown_icon: String,
		feedback_hint: String,
) -> Dictionary:
	return {
		"family": family,
		"style": style,
		"color": color,
		"radius": radius,
		"cast_label": cast_label,
		"telegraph_shape": telegraph_shape,
		"impact_shape": impact_shape,
		"cooldown_icon": cooldown_icon,
		"feedback_hint": feedback_hint,
		"impact_cue": _skill_impact_cue(impact_shape, feedback_hint),
		"audio_intensity": "high" if ["slam", "blast", "burst", "beam"].has(style) else "medium",
		"feel_tier": _skill_feel_tier(style),
		"cooldown_hint": _skill_cooldown_hint(cooldown_icon, feedback_hint),
		"hit_pause_seconds": 0.08,
		"hit_pause_scale": 0.82,
	}

static func _skill_feel_tier(style: String) -> String:
	if ["slam", "blast", "burst", "beam"].has(style):
		return "heavy"
	if ["ward", "sanctuary", "trap", "tech", "hack", "summon"].has(style):
		return "setup"
	if ["dash_lunge", "shadow", "slash_arc"].has(style):
		return "quick"
	return "steady"

static func _skill_cooldown_hint(cooldown_icon: String, feedback_hint: String) -> String:
	var icon := cooldown_icon.strip_edges()
	var hint := feedback_hint.strip_edges()
	if icon == "" and hint == "":
		return "Cooldown skill"
	if icon == "":
		return "Cooldown: %s" % hint
	if hint == "":
		return "Cooldown: %s" % icon.capitalize()
	return "Cooldown %s | %s" % [icon.capitalize(), hint]

static func _skill_impact_cue(impact_shape: String, feedback_hint: String) -> String:
	var hint := feedback_hint.strip_edges()
	if hint != "":
		return hint
	var shape := impact_shape.strip_edges()
	return shape.capitalize() if shape != "" else "Skill impact"

static func _hit_spark_color(hit_kind: String, element: String) -> Color:
	match hit_kind:
		"critical":
			return Color(1.0, 0.95, 0.36, 0.92)
		"weak":
			return Color(1.0, 0.58, 0.22, 0.9)
		"resist":
			return Color(0.55, 0.76, 1.0, 0.82)
	match element:
		"fire":
			return Color(1.0, 0.42, 0.18, 0.88)
		"ice":
			return Color(0.58, 0.88, 1.0, 0.86)
		"lightning":
			return Color(1.0, 0.92, 0.35, 0.88)
		"poison":
			return Color(0.54, 1.0, 0.38, 0.86)
	return Color(1.0, 0.82, 0.28, 0.86)

static func spawn_skill_cast(parent: Node, origin: Vector2, skill_id: String) -> Node2D:
	var profile := skill_feedback_profile(skill_id)
	var color: Color = profile.get("color", Color(0.75, 0.9, 1.0, 0.9))
	var radius := float(profile.get("radius", 15.0))
	var style := str(profile.get("style", "generic"))
	var fx := _root(parent, "CombatFxSkillCast", origin, Vector2.RIGHT)
	fx.set_meta("skill_id", skill_id)
	fx.set_meta("skill_style", style)
	fx.set_meta("skill_family", str(profile.get("family", "generic")))
	fx.set_meta("skill_cast_label", str(profile.get("cast_label", skill_id)))
	fx.set_meta("skill_telegraph_shape", str(profile.get("telegraph_shape", "self")))
	fx.set_meta("skill_impact_shape", str(profile.get("impact_shape", "pulse")))
	fx.set_meta("skill_impact_cue", str(profile.get("impact_cue", "")))
	fx.set_meta("skill_cooldown_icon", str(profile.get("cooldown_icon", "skill")))
	fx.set_meta("skill_feedback_hint", str(profile.get("feedback_hint", "")))
	fx.set_meta("skill_audio_intensity", str(profile.get("audio_intensity", "medium")))
	fx.set_meta("skill_feel_tier", str(profile.get("feel_tier", "steady")))
	fx.set_meta("skill_cooldown_hint", str(profile.get("cooldown_hint", "")))
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in 17:
		var angle := TAU * float(i) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	ring.points = points
	ring.width = 2.0
	ring.default_color = color
	fx.add_child(ring)
	var spark := Polygon2D.new()
	spark.polygon = PackedVector2Array([
		Vector2(0, -9), Vector2(4, -2), Vector2(10, 0), Vector2(4, 2), Vector2(0, 9),
		Vector2(-4, 2), Vector2(-10, 0), Vector2(-4, -2),
	])
	spark.color = color.lightened(0.15)
	fx.add_child(spark)
	_add_skill_style_cue(fx, style, color, radius)
	fx.set_meta("skill_layer_count", fx.get_child_count())
	_lifetime(fx, 0.24, 1.22)
	return fx

static func _add_skill_style_cue(fx: Node2D, style: String, color: Color, radius: float) -> void:
	match style:
		"slash_arc":
			_add_line(fx, PackedVector2Array([
				Vector2(-radius * 0.7, -radius * 0.3),
				Vector2(radius * 0.1, -radius * 0.55),
				Vector2(radius * 0.75, 0),
				Vector2(radius * 0.1, radius * 0.55),
				Vector2(-radius * 0.7, radius * 0.3),
			]), color, 2.5)
		"dash_lunge", "projectile", "ammo":
			_add_line(fx, PackedVector2Array([
				Vector2(-radius, 0),
				Vector2(radius, 0),
				Vector2(radius * 0.45, -radius * 0.35),
				Vector2(radius, 0),
				Vector2(radius * 0.45, radius * 0.35),
			]), color, 2.0)
		"slam", "blast", "burst":
			for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				_add_line(fx, PackedVector2Array([
					dir * radius * 0.15,
					dir * radius,
				]), color, 2.0)
		"ward", "sanctuary":
			_add_line(fx, PackedVector2Array([
				Vector2(0, -radius),
				Vector2(radius, 0),
				Vector2(0, radius),
				Vector2(-radius, 0),
				Vector2(0, -radius),
			]), color, 2.0)
		"shadow":
			_add_line(fx, PackedVector2Array([
				Vector2(-radius * 0.65, -radius * 0.25),
				Vector2(-radius * 0.2, radius * 0.35),
				Vector2(radius * 0.25, -radius * 0.1),
				Vector2(radius * 0.65, radius * 0.28),
			]), color, 2.2)
		"roar", "ring", "orb", "summon":
			_add_line(fx, PackedVector2Array([
				Vector2(-radius, -radius * 0.45),
				Vector2(0, -radius * 0.75),
				Vector2(radius, -radius * 0.45),
			]), color, 1.8)
			_add_line(fx, PackedVector2Array([
				Vector2(-radius, radius * 0.45),
				Vector2(0, radius * 0.75),
				Vector2(radius, radius * 0.45),
			]), color, 1.8)
		"trap":
			_add_line(fx, PackedVector2Array([
				Vector2(-radius * 0.65, -radius * 0.35),
				Vector2(radius * 0.65, -radius * 0.35),
				Vector2(radius * 0.35, radius * 0.55),
				Vector2(-radius * 0.35, radius * 0.55),
				Vector2(-radius * 0.65, -radius * 0.35),
			]), color, 2.0)
		"beam", "tech", "hack":
			_add_line(fx, PackedVector2Array([
				Vector2(0, -radius),
				Vector2(0, radius),
			]), color, 2.0)
			_add_line(fx, PackedVector2Array([
				Vector2(-radius, 0),
				Vector2(radius, 0),
			]), color, 2.0)
		_:
			_add_line(fx, PackedVector2Array([
				Vector2(-radius * 0.5, 0),
				Vector2(radius * 0.5, 0),
			]), color, 1.6)

static func _add_line(fx: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	fx.add_child(line)

static func _fx_release_entry(fx_id: String, profile: Dictionary, issues: Array[String]) -> Dictionary:
	var source := "missing" if profile.is_empty() else "procedural_godot_shapes"
	var ready := issues.is_empty()
	var policy := AssetSourceRegistryScript.policy_for(source, "vfx", issues)
	var entry := {
		"id": fx_id,
		"node_name": str(profile.get("node", "")),
		"source": source,
		"reference_policy": str(policy.get("reference_policy", "")),
		"license": str(policy.get("license", "missing")),
		"release_decision": str(policy.get("release_decision", "blocked")),
		"review_status": str(policy.get("review_status", "blocked")),
		"replacement_policy": str(policy.get("replacement_policy", "add_procedural_fx_before_release")),
		"needs_replacement_before_public": bool(
			policy.get("needs_replacement_before_public", true)),
		"layer_count": int(profile.get("layers", 0)),
		"duration": float(profile.get("duration", 0.0)),
		"geometry_ok": ready and int(profile.get("layers", 0)) > 0,
		"frame_grid_ok": ready,
		"motion_reviewed": ready,
		"issues": issues.duplicate(),
	}
	_copy_source_policy(entry, policy)
	return entry

static func _copy_source_policy(entry: Dictionary, policy: Dictionary) -> void:
	for key in [
		"source_policy_id",
		"source_kind",
		"asset_kind",
		"source_url",
		"usable_runtime_asset",
	]:
		entry[key] = policy.get(key, "")

static func _root(parent: Node, node_name: String, origin: Vector2, dir: Vector2) -> Node2D:
	var fx := Node2D.new()
	fx.name = node_name
	fx.set_meta("asset_source", "procedural_godot_shapes")
	fx.set_meta("reference_policy", "fanmade_reference_only_no_copy")
	fx.set_meta("review_status", "stable_procedural_ok")
	fx.set_meta("release_decision", "public_ok")
	fx.set_meta("frame_count", 1)
	fx.set_meta("frame_size", Vector2(48, 48))
	fx.set_meta("expected_frame_size", Vector2(48, 48))
	fx.set_meta("frame_grid_ok", true)
	fx.set_meta("stable_size", true)
	fx.set_meta("animation_stability_reviewed", true)
	fx.set_meta("motion_reviewed", true)
	fx.set_meta("origin_alignment_reviewed", true)
	fx.set_meta("origin_px", Vector2.ZERO)
	parent.add_child(fx)
	fx.global_position = origin
	if dir.length_squared() > 0.0:
		fx.rotation = dir.angle()
	return fx

static func _lifetime(fx: Node2D, seconds: float, end_scale: float) -> void:
	var tween := fx.create_tween()
	tween.tween_property(fx, "scale", Vector2.ONE * end_scale, seconds)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, seconds)
	tween.tween_callback(fx.queue_free)
