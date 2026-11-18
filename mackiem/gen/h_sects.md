### VÂN KIẾM TÔNG (`kiem`)

`B("k_phan", -1, "pas", "HOÀN KIẾM CHẤN CẢNH", "Đỡ chuẩn lập tức thu hồi mọi phi kiếm; mỗi thanh rút ra gây {15} phá THẾ lên mục tiêu bị găm."),`
- Tông môn: `kiem`
- Hook (`Parried(src)`):
```csharp
if (Lv("k_phan") > 0) {
	foreach (var s in swords) if (s.st == 1 && s.host != null) AddPosture(s.host, 15 * Lv("k_phan"));
	RecallSwords();
}
```

`B("k_truy", -1, "pas", "ĐOẠT HỒN TRUY KIẾM", "Hạ địch đang bị phi kiếm găm: kiếm tự phóng tiếp vào địch khác và hồi {4} nội lực."),`
- Tông môn: `kiem`
- Hook (`Kill(f)`):
```csharp
if (Lv("k_truy") > 0) foreach (var s in swords) if (s.st == 1 && s.host == f) {
	s.host = null; s.st = 0; ThrowSword(); qi += 4 * Lv("k_truy");
}
```

`B("k_no", -1, "pas", "BẠT KIẾM KINH LÔI", "Thu hồi phi kiếm đang găm sẽ kích nổ quanh mục tiêu, gây {18} sát thương diện rộng."),`
- Tông môn: `kiem`
- Hook (`RecallSwords()`):
```csharp
if (Lv("k_no") > 0) foreach (var s in swords)
	if (s.st == 1 && s.host != null) Burst(s.host.pos, 95, 18 * Lv("k_no"), -1, 1, false);
```

---

### THIẾT Y MÔN (`thiet`)

`B("t_huyet", -1, "pas", "HUYẾT DƯ BỘC PHÁT", "Mọi lượng hồi sinh lực vượt mức tối đa biến thành xung kích quanh mình, gây {4} lần sát thương lượng dư."),`
- Tông môn: `thiet`
- Hook (`Heal(v)`):
```csharp
int over = Mathf.Max(0, hp + v - maxHp);
if (over > 0 && Lv("t_huyet") > 0)
	Burst(player.pos, 150, over * 4 * Lv("t_huyet"), -1, 1, false);
```

`B("t_tinh", -1, "pas", "TĨNH THỦ HOÁN KHÍ", "Mỗi lần đỡ chuẩn giảm {2} giây hồi Tuyệt chiêu và thu {6} nội lực."),`
- Tông môn: `thiet`
- Hook (`Parried(src)`):
```csharp
if (Lv("t_tinh") > 0) { tkCd = Mathf.Max(0, tkCd - 2 * Lv("t_tinh")); qi += 6 * Lv("t_tinh"); }
```

`B("t_xuyen", -1, "pas", "CÁCH KHÔNG PHẢN THẾ", "Đỡ chuẩn phản ngược {20} phá THẾ thẳng vào kẻ ra đòn bất kể cự ly; nếu làm vỡ thế địch, hồi {5} sinh lực."),`
- Tông môn: `thiet`
- Hook (`Parried(src)`):
```csharp
if (Lv("t_xuyen") > 0 && src != null) {
	AddPosture(src, 20 * Lv("t_xuyen"));
	if (src.broken) Heal(5 * Lv("t_xuyen"));
}
```

---

### HUYẾT NGUYỆT ĐƯỜNG (`cuong`)

`B("c_hien", -1, "pas", "KHƯỚC DƯỢC THÍCH HUYẾT", "Khi sinh lực dưới nửa, mọi lần hồi máu bị triệt tiêu và chuyển thành sóng máu quanh mình gây {5} lần lượng hồi."),`
- Tông môn: `cuong`
- Hook (`Heal(v)`):
```csharp
if (Lv("c_hien") > 0 && hp < maxHp * 0.5f && v > 0) {
	Burst(player.pos, 145, v * 5 * Lv("c_hien"), -1, 1, false);
	return;
}
```

`B("c_lien", -1, "pas", "LIÊN TRẢM CUỒNG TRIỀU", "Mỗi đòn đánh trúng khi đang có chuỗi hạ địch tạo xung chấn tại mục tiêu, gây {4} sát thương nhân số chuỗi."),`
- Tông môn: `cuong`
- Hook (`HurtFoe(f,dmg,el,lvl,posMul,dir)`):
```csharp
if (Lv("c_lien") > 0 && chain > 0)
	Burst(f.pos, 80 + chain * 12, 4 * chain * Lv("c_lien"), -1, 1, false);
```

`B("c_tuyet", -1, "pas", "TUYỆT CẢNH HỒI KHÍ", "Khi sinh lực từ 35% trở xuống, mỗi đòn đánh trúng hồi {3} nội lực và giảm {1} giây hồi Tuyệt chiêu."),`
- Tông môn: `cuong`
- Hook (`HurtFoe(f,dmg,el,lvl,posMul,dir)`):
```csharp
if (Lv("c_tuyet") > 0 && hp <= maxHp * 0.35f) {
	qi += 3 * Lv("c_tuyet"); tkCd = Mathf.Max(0, tkCd - 1 * Lv("c_tuyet"));
}
```

---

### NGŨ HÀNH CỐC (`hanh`)

`B("h_luu", -1, "pas", "LƯU CHUYỂN SINH KHẮC", "Khi kích hoạt TƯƠNG SINH, tự động truyền một Ấn hành khác lên mọi địch trong bán kính {110} px."),`
- Tông môn: `hanh`
- Hook (`ApplyEl(f,el,lvl,react)`):
```csharp
if (Lv("h_luu") > 0 && react && f.mark >= 0 && D.Relation(f.mark, el) == 1) {
	int nxt = (el + 1) % 5;
	foreach (var e in FoesIn(f.pos, 110 * Lv("h_luu"))) ApplyEl(e, nxt, 1, false);
}
```

`B("h_dong", -1, "pas", "CỘNG HƯỞNG ĐỒNG NGUYÊN", "Đánh hành trùng với Ấn đang có trên địch kích nổ cộng hưởng gây {12} sát thương và {15} phá THẾ."),`
- Tông môn: `hanh`
- Hook (`ApplyEl(f,el,lvl,react)`):
```csharp
if (Lv("h_dong") > 0 && react && f.mark == el) {
	Burst(f.pos, 90, 12 * Lv("h_dong"), el, lvl, false);
	AddPosture(f, 15 * Lv("h_dong"));
}
```

`B("h_truyen", -1, "pas", "ẤN TÀN LƯU CHUYỂN", "Hạ địch đang mang Ấn sẽ truyền Ấn đó sang tối đa {2} địch gần nhất và hồi {5} nội lực."),`
- Tông môn: `hanh`
- Hook (`Kill(f)`):
```csharp
if (Lv("h_truyen") > 0 && f.mark >= 0) {
	foreach (var e in NearestFoes(f.pos, 2 * Lv("h_truyen"))) ApplyEl(e, f.mark, 1, true);
	qi += 5 * Lv("h_truyen");
}
```

---
→ Bỏ qua: file `Sect` filter trên `Boon` (xử lý qua bảng map ID hoặc field `sect` nếu cần sau).
