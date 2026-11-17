using System.Collections.Generic;
using UnityEngine;

// An immediate-mode mesh: cleared and refilled every frame with coloured shapes (telegraphs, slashes,
// ink drops, bars). Coordinates are logic pixels; the mesh is scaled to Unity units.
public class Ink {
	readonly Mesh mesh;
	readonly List<Vector3> v = new List<Vector3>(4096);
	readonly List<Color32> c = new List<Color32>(4096);
	readonly List<int> t = new List<int>(8192);
	public readonly GameObject go;

	public Ink(string name, int order) {
		go = new GameObject(name);
		mesh = new Mesh();
		mesh.MarkDynamic();
		go.AddComponent<MeshFilter>().mesh = mesh;
		var mr = go.AddComponent<MeshRenderer>();
		mr.material = new Material(Shader.Find("Sprites/Default"));
		mr.sortingOrder = order;
		go.transform.localScale = new Vector3(0.01f, 0.01f, 1);
	}

	public void Clear() { v.Clear(); c.Clear(); t.Clear(); }

	public void Apply() {
		mesh.Clear();
		mesh.SetVertices(v);
		mesh.SetColors(c);
		mesh.SetTriangles(t, 0);
		mesh.bounds = new Bounds(new Vector3(2000, 2000, 0), new Vector3(30000, 30000, 10));
	}

	int V(Vector2 p, Color col) { v.Add(new Vector3(p.x, p.y, 0)); c.Add(col); return v.Count - 1; }

	public void Tri(Vector2 a, Vector2 b, Vector2 d, Color col) {
		int i = V(a, col); V(b, col); V(d, col);
		t.Add(i); t.Add(i + 1); t.Add(i + 2);
	}

	public void Quad(Vector2 a, Vector2 b, Vector2 d, Vector2 e, Color col) { Quad(a, b, d, e, col, col); }
	public void Quad(Vector2 a, Vector2 b, Vector2 d, Vector2 e, Color c1, Color c2) {
		int i = V(a, c1); V(b, c1); V(d, c2); V(e, c2);
		t.Add(i); t.Add(i + 1); t.Add(i + 2); t.Add(i); t.Add(i + 2); t.Add(i + 3);
	}

	public void Rect(float x, float y, float w, float h, Color col) {
		Quad(new Vector2(x, y), new Vector2(x + w, y), new Vector2(x + w, y + h), new Vector2(x, y + h), col);
	}

	public void Line(Vector2 a, Vector2 b, float w, Color col) {
		Vector2 d = b - a;
		if (d.sqrMagnitude < 0.0001f) return;
		Vector2 n = new Vector2(-d.y, d.x).normalized * (w * 0.5f);
		Quad(a - n, a + n, b + n, b - n, col);
	}

	// a stroke that is thick in the middle and thin at the ends, like a brush
	public void Brush(Vector2 a, Vector2 b, float w, Color col) {
		Vector2 d = b - a;
		if (d.sqrMagnitude < 0.0001f) return;
		Vector2 n = new Vector2(-d.y, d.x).normalized * (w * 0.5f);
		Vector2 m = (a + b) * 0.5f;
		Tri(a, m + n, m - n, col);
		Tri(b, m - n, m + n, col);
	}

	public void Ellipse(Vector2 p, float rx, float ry, Color col, int seg = 20) {
		int i0 = V(p, col);
		for (int i = 0; i <= seg; i++) {
			float a = i * Mathf.PI * 2 / seg;
			V(p + new Vector2(Mathf.Cos(a) * rx, Mathf.Sin(a) * ry), col);
		}
		for (int i = 0; i < seg; i++) { t.Add(i0); t.Add(i0 + 1 + i); t.Add(i0 + 2 + i); }
	}

	public void Circle(Vector2 p, float r, Color col, int seg = 20) { Ellipse(p, r, r, col, seg); }

	public void Ring(Vector2 p, float r, float w, Color col, int seg = 48, float a0 = 0, float a1 = Mathf.PI * 2) {
		float r0 = Mathf.Max(0, r - w * 0.5f), r1 = r + w * 0.5f;
		int i0 = v.Count;
		for (int i = 0; i <= seg; i++) {
			float a = Mathf.Lerp(a0, a1, i / (float)seg);
			Vector2 d = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
			V(p + d * r0, col); V(p + d * r1, col);
		}
		for (int i = 0; i < seg; i++) {
			int k = i0 + i * 2;
			t.Add(k); t.Add(k + 1); t.Add(k + 3); t.Add(k); t.Add(k + 3); t.Add(k + 2);
		}
	}

	public void Sector(Vector2 p, float r, float a0, float a1, Color col, int seg = 24) {
		int i0 = V(p, col);
		for (int i = 0; i <= seg; i++) {
			float a = Mathf.Lerp(a0, a1, i / (float)seg);
			V(p + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * r, col);
		}
		for (int i = 0; i < seg; i++) { t.Add(i0); t.Add(i0 + 1 + i); t.Add(i0 + 2 + i); }
	}

	// a sword stroke: an arc that swells in the middle and tapers to points
	public void Crescent(Vector2 p, float r, float a0, float a1, float thick, Color col, int seg = 22) {
		int i0 = v.Count;
		for (int i = 0; i <= seg; i++) {
			float u = i / (float)seg;
			float a = Mathf.Lerp(a0, a1, u);
			float th = thick * Mathf.Sin(u * Mathf.PI);
			Vector2 d = new Vector2(Mathf.Cos(a), Mathf.Sin(a));
			V(p + d * (r - th), col); V(p + d * r, col);
		}
		for (int i = 0; i < seg; i++) {
			int k = i0 + i * 2;
			t.Add(k); t.Add(k + 1); t.Add(k + 3); t.Add(k); t.Add(k + 3); t.Add(k + 2);
		}
	}

	// an irregular blot of ink
	public void Blot(Vector2 p, float r, Color col, int seed) {
		var st = Random.state;
		Random.InitState(seed);
		Circle(p, r * 0.7f, col, 14);
		for (int i = 0; i < 6; i++) {
			Vector2 o = Random.insideUnitCircle * r;
			Circle(p + o, r * Random.Range(0.15f, 0.4f), col, 8);
		}
		Random.state = st;
	}
}
