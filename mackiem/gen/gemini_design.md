```csharp
// Assets/Scripts/Data.cs — diff tối thiểu cho tiến trình và chiều sâu build
public class WeaponDef {
	public string id, name, desc, skill, skillName, skillDesc, mech = "", unlock = "";
	public string altName = "", altDesc = ""; // ponytail: 1 biến thể mỗi vũ khí, mở bằng Kiếm Hồn; tách class khi >2 biến thể
	public AtkStep[] combo;
}

public class Boon {
	public string id, name, desc, slot, sect = ""; // sect: khóa theo môn phái
	public int el = -1, reqEl = -1;                // reqEl: yêu cầu hành thứ 2 để mở Hợp Kích (Duo)
}

// Thêm vào D:
// ponytail: dùng hành kích hoạt (b) quyết định hiệu ứng Sinh/Khắc thay vì bảng 25 cặp; tách bảng khi cần hiệu ứng riêng từng cặp
public static readonly string[] SINH_FX = {
	"KIM sinh: bắn 3 kiếm khí xuyên thấu (18 sát thương)",
	"MỘC sinh: nổ độc lan, hút 2 sinh lực mỗi địch trúng",
	"THỦY sinh: giảm 1.5s hồi Tuyệt Kỹ, hồi 15 nội lực",
	"HỎA sinh: cột lửa 45 sát thương nổ chậm sau 0.6s",
	"THỔ sinh: tạo khiên chặn 1 đòn trong 4s"
};

// Ví dụ mở rộng trong D.BOONS (thay thế số đồng phục + thêm bí kíp phái/hợp kích):
// B("h_kiem1", -1, "pas", "VẠN KIẾM QUY TÔNG", "Thu phi kiếm kéo địch về phía mình, +{25}% sát thương mỗi thanh.", sect: "kiem"),
// B("duo_km", 0, "pas", "KIM MỘC TƯƠNG TRUYỀN", "Địch trúng RÁCH nhận sát thương ĐỘC nhanh gấp {2} lần.", reqEl: 1),

// Thêm vào D.META (kiểm soát RNG thay vì cộng chỉ số thuần):
// new MetaUp { id = "reroll", name = "NGHỊCH MỆNH", desc = "+1 lần đổi danh sách Bí Kíp/Bảo Vật mỗi chuyến", cost = new[] { 15, 30, 50 } },
// new MetaUp { id = "banish", name = "ĐOẠN TUYỆT", desc = "Khóa 1 Bí Kíp mỗi chuyến (không xuất hiện lại)", cost = new[] { 20, 40 } },
// new MetaUp { id = "start", name = "TIÊN THIÊN KHÍ", desc = "Khởi hành chọn 1 trong 3 Bảo Vật đã mở", cost = new[] { 45 } },

#if UNITY_EDITOR
public static void SelfCheck() {
	Debug.Assert(Relation(KIM, THUY) == 1 && Relation(KIM, MOC) == 2, "Sai quan hệ ngũ hành");
	foreach (var b in BOONS) Debug.Assert(b.reqEl < 0 || b.el != b.reqEl, "Duo boon trùng hành: " + b.id);
}
#endif
```
→ skipped: Cây kỹ năng riêng từng phái, hệ thống rèn trang bị, bảng 25 phản ứng đôi. Add when: Đã cân bằng xong 6 vũ khí gốc và có dữ liệu người chơi thật.

---

### 1 & 2. Năm điểm yếu tiến trình & Cách sửa cụ thể

1. **Bí kíp Ngũ hành đồng phục (Clone Boons):**
   - **Vấn đề:** 20 bí kíp `a0..s4` chỉ đổi màu và trạng thái, giữ nguyên số (`+{15}%` đánh, `{16}` lướt, `{26}` đỡ, `+{30}%` chiêu). Không đổi hành vi đòn đánh, thiếu Bí kíp Hợp Kích (Duo Boon) để định hình mục tiêu giữa trận.
   - **Sửa:** Thêm `int reqEl = -1` vào `Boon`. Thêm 5 bí kíp Hợp Kích (yêu cầu đang giữ 2 hành tương ứng, VD: `el = 0, reqEl = 2` Kim-Thủy: Đỡ chuẩn tự phóng 3 phi kiếm băng `{20}` sát thương). Sửa số `a0..a4` lệch nhau theo tính chất hành (Kim `+{10}%` nhưng xuyên giáp, Hỏa `+{25}%`, Thủy `+{10}%` hồi 3 nội lực).

2. **Môn phái nông (Flat Sects):**
   - **Vấn đề:** `D.SECTS` chỉ là nội tại cố định đầu trận. Vào chuyến đi, cả 4 phái bốc chung một bể `BOONS`, làm các lượt chơi lặp lại (khác với *Warm Snow* nơi Tông phái quyết định bể bí kíp).
   - **Sửa:** Thêm `string sect = ""` vào `Boon`. Thêm 12 bí kíp độc quyền (3 mỗi phái, tỷ lệ xuất hiện x2 khi đúng phái):
     - `kiem`: Phi kiếm cắm trên đất tự chém vòng tròn bán kính `90` mỗi `1s` (`{12}` sát thương).
     - `thiet`: Đỡ chuẩn gây nổ THẾ diện rộng bán kính `160` (`{40}` sát thương THẾ).
     - `cuong`: Tiêu hao `5%` máu hiện tại khi dùng Tuyệt chiêu để tăng `{60}%` sát thương chiêu đó.
     - `hanh`: Mỗi ẤN khác nhau trên người địch tăng `{18}%` sát thương nó nhận.

3. **Binh khí tĩnh, hết mục tiêu sau Chương III:**
   - **Vấn đề:** Hạ trùm mở xong 6 vũ khí là hết động lực cày `KIẾM HỒN`. Vũ khí không có biến thể (Aspects) đổi lối chơi.
   - **Sửa:** Thêm `altName`, `altDesc` vào `WeaponDef`, mở bằng `5 KIẾM HỒN` mỗi món. Dùng chung animation, chỉ đổi thông số `combo` hoặc `mech`:
     - Kiếm biến thể (*Vô Hình Kiếm*): Sát thương tay giảm `40%`, mang `10` phi kiếm, phi kiếm tự phóng theo mỗi nhát chém thường.
     - Chùy biến thể (*Lôi Công Chùy*): Bỏ giảm sát thương khi vung, tốc độ đánh `+35%`, mỗi nhát vung hút địch vào tâm.

4. **Phản ứng Ngũ hành thiếu bản sắc:**
   - **Vấn đề:** Mọi cặp Tương Sinh đều "nổ lan + hồi nội lực", mọi cặp Tương Khắc đều "sập THẾ". Chọn cặp Kim-Thủy hay Mộc-Hỏa cho cảm giác bấm nút giống hệt nhau.
   - **Sửa:** Dùng mảng `SINH_FX[b]` (theo hành kích hoạt `b` trong `Relation(a, b)`). Tương Sinh vẫn nổ nhưng kèm hiệu ứng riêng của hành `b` (Kim: bắn kiếm khí; Mộc: hút máu; Thủy: giảm hồi chiêu `F` `1.5s`; Hỏa: cột lửa nổ chậm `45` sát thương; Thổ: tạo khiên chặn `1` đòn).

5. **Tu luyện (`D.META`) toàn chỉ số cộng thẳng, thiếu kiểm soát RNG:**
   - **Vấn đề:** 5/6 nâng cấp trong `META` là cộng máu, sát thương, tiền. Với 12 cửa thưởng mỗi chuyến (3 chương x 4 bãi), người chơi dễ bị lệch build do RNG mà không có quyền can thiệp.
   - **Sửa:** Thêm 3 mục vào `D.META`: `reroll` (Đổi 3 lựa chọn Bí kíp/Bảo vật, giá `15/30/50`), `banish` (Cấm 1 Bí kíp xuất hiện trong chuyến đi, giá `20/40`), `start` (Chọn 1 trong 3 Bảo vật ngay khi khởi hành, giá `45`).

---

### 3. Năm Bảo Vật mới tạo Build (Thêm vào `GameJourney.cs`)

1. **NGHỊCH HÀNH ẤN (Ngũ hành):**
   - **Hiệu ứng:** Đảo ngược quan hệ Ngũ hành: các cặp TƯƠNG KHẮC kích hoạt nổ TƯƠNG SINH (tăng `40%` sát thương nổ), các cặp TƯƠNG SINH kích hoạt TƯƠNG KHẮC.
   - **Tạo build:** Cho phép ghép các cặp hành vốn khắc nhau (như Thủy + Hỏa hoặc Kim + Mộc) để lấy hiệu ứng hồi nội lực/nổ lan mà không bị ép đi theo vòng tròn Sinh cố định.

2. **TỬ MẪU KIẾM HẠP (Phi kiếm + Đỡ đòn):**
   - **Hiệu ứng:** Đỡ chuẩn lập tức phóng `2` phi kiếm vào kẻ vừa tấn công và gọi toàn bộ phi kiếm đang cắm trên sân bay về ngay lập tức, gây thêm `50%` sát thương đường về.
   - **Tạo build:** Biến lối chơi Phi kiếm từ "chạy xa bắn tỉa" thành "đứng sát đỡ đòn". Kết hợp *Thiết Y Môn* hoặc *Hồi Kiếm Quyết* để xả sát thương tức thời mỗi pha đỡ chuẩn.

3. **HUYẾT ĐẰNG CHÂU (Phi kiếm + Ngũ hành Độc/Hỏa):**
   - **Hiệu ứng:** Phi kiếm không thể thu hồi bằng nút `R` (chỉ tự về sau `5s`), nhưng mỗi thanh đang cắm trên người địch kích hoạt sát thương ĐỘC/THIÊU đang có trên mục tiêu đó mỗi `0.5s` (`+20%` sát thương mỗi thanh).
   - **Tạo build:** Đổi hoàn toàn nhịp chơi Phi kiếm: từ phóng-thu liên tục sang cắm ngập kiếm vào trùm để rút máu theo cấp số nhân với Mộc/Hỏa.

4. **THIÊN QUÂN XÍCH (Thế / Đỡ đòn):**
   - **Hiệu ứng:** Khi địch bị PHÁ THẾ, `80%` lượng sát thương THẾ của đòn đó truyền sang mọi địch trong bán kính `220` và kéo chúng lại gần mục tiêu.
   - **Tạo build:** Giải quyết điểm yếu dọn quái chậm của hướng build Phá Thế / Đỡ đòn (*Trấn Sơn Chùy*, *Phá Vân Chỉ*). Phá thế 1 con tinh anh làm sập thế cả đám đông xung quanh.

5. **THÁI CỰC NGỌC BỘI (Ngũ hành + Liên hoàn):**
   - **Hiệu ứng:** Đòn cuối trong chuỗi đánh thường (`combo` cuối) tự động mang hành TƯƠNG KHẮC với ẤN đang có trên mục tiêu (nếu mục tiêu chưa có ẤN, gắn ẤN ngẫu nhiên).
   - **Tạo build:** Cho phép kích hoạt phản ứng Ngũ hành chỉ bằng chuỗi đánh thường (rất mạnh với *Song Nguyệt Đao* 4 nhát nhanh hoặc *Lạc Nhạn Cung* 1 nhát là hết combo), giải phóng các ô Khinh công/Đỡ đòn cho mục đích phòng thủ.

---

### 4. Cảnh báo cân bằng (Balance Red Flags) trong `Data.cs`

1. **`khac` (Tương Khắc Quyết) cộng sát thương phẳng quá lớn (`+{35}` mỗi cấp):**
   - Sát thương cơ bản của *Song Nguyệt Đao* là `8`, *Thiết Phiến* là `9`. Cộng thẳng `35` sát thương mỗi cấp (cấp 3 = `+105` mỗi lần nổ) khi kết hợp với *Phi kiếm* (tự nổ khi đi-về) hoặc *Tàn Ảnh Trảm* nhánh `ẢNH ẤN` sẽ làm bốc hơi trùm Chương III (`hp = 1020` x `2.0` = `2040` HP) chỉ trong vài giây, làm phế mọi bí kíp tăng `%` sát thương.
   - **Sửa:** Đổi `{35}` sát thương máu thành `+{35}%` sát thương THẾ, hoặc giảm xuống `{15}` sát thương máu.

2. **`cung` (Lạc Nhạn Cung) Mãn Cung x7 sát thương + xuyên mọi địch:**
   - Sát thương cơ bản `10` x `7` = `70` sát thương xuyên táo ở tốc độ đạn `1200`. Máu quái Chương I: *Cung thủ/Thích khách* `30` HP, *Sơn tặc* `44` HP, *Thương binh* `52` HP. Ngay cả ở Chương II (`CH_HP = 1.45` -> Sơn tặc `63` HP), 1 mũi tên không cần bí kíp vẫn dọn sạch cả hàng quái từ ngoài tầm đánh của chúng.
   - **Sửa:** Giảm hệ số Mãn Cung xuống `x4` (`40` sát thương) hoặc giảm `25%` sát thương sau mỗi mục tiêu xuyên qua.

3. **Cộng dồn cửa sổ Đỡ chuẩn (`calm` + *Thiết Y Môn*) gây bất tử:**
   - *Thiết Y Môn* cho `+60%` thời gian đỡ chuẩn và hồi `4` HP mỗi lần. Bí kíp `calm` (*Tĩnh Tâm*) cho `+{30}%` mỗi cấp. Ở cấp 3 (`+90%`), tổng cộng cửa sổ đỡ chuẩn dài thêm `+150%`. Người chơi chỉ cần bấm giữ/nhấp `Shift` bừa bãi cũng đỡ chuẩn liên tục và hồi đầy máu trước các đòn đánh nhiều nhịp (như `boss2` bắn 3 vòng `ring` hoặc `boss3` chém 4 nhát).
   - **Sửa:** Giới hạn trần (hard cap) thời gian cửa sổ đỡ chuẩn ở mức tối đa `0.35s` và thêm hồi chiêu nội tại `1.5s` cho hiệu ứng hồi máu của *Thiết Y Môn*.

4. **`chuy` (Trấn Sơn Chùy) bị khắc chế cứng bởi `boss3` (Bạch Phát Kiếm Thánh):**
   - Chùy có `dur = 0.5f..0.7f` (vung cực chậm). `boss3` có chiêu chém gần `wind = 0.38f, 0.26f, 0.26f` và liên tục `Blink()`. Chùy không thể vung xong đòn 3 trước khi `boss3` dịch chuyển mất hoặc chém xong 3 nhát. Giảm `40%` sát thương khi vung không cứu được ở Kiếp Nạn cao.
   - **Sửa:** Cho phép hủy hoạt ảnh thu đòn của Chùy bằng Đỡ đòn (`Shift`) ngay lập tức, hoặc giảm `dur` đòn 1-2 xuống `0.38f`.

5. **`chung` (Kim Chung Tráo) nhánh `PHẢN CHẤN` phá hỏng `boss2` (Vô Minh Thiền Sư):**
   - `boss2` có chiêu `radial` bắn `14` viên x `3` đợt = `42` viên đạn (`10` sát thương/viên). Đứng sát người `boss2` bật *Kim Chung Tráo* (bất tử `4s` + phản mọi ám khí) sẽ phản toàn bộ `42` viên đạn trúng lại tâm boss ngay lập tức (`420+` sát thương miễn phí).
   - **Sửa:** Đạn phản lại từ `PHẢN CHẤN` giảm `50%` sát thương khi trúng cùng một mục tiêu trong vòng `0.2s`.
