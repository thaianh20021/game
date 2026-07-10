extends Node2D

static func release_geometry_contract(_runtime_id: String) -> Dictionary:
	return {
		"shape_size": Vector2.ZERO,
		"fallback_polygon": PackedVector2Array([Vector2.ZERO, Vector2(4, 0)]),
	}
