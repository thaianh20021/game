# Dư Vang: thiết kế class và kỹ năng

Tài liệu này là Phần II của GDD, viết lại cho khớp với game đang chạy trong `duvang/`.
Phần 28 class kết hợp và cây giao thoa của chúng nằm ở [HYBRIDS.md](HYBRIDS.md).

Ký hiệu: **[CHỐT]** quyết định thiết kế, **[GIẢ ĐỊNH]** số cần chơi thử, **[ĐÃ CÓ]** đã chạy trong game.

## 1. Khung chung

### 1.1 Luật điểm [ĐÃ CÓ, trừ cấp tối đa]

| Hạng mục | Giá trị |
|---|---|
| Cấp tối đa | 60 [CHỐT], mỗi cấp 1 điểm, tổng 60 điểm |
| Chi phí | Mỗi bậc của mọi node tốn 1 điểm |
| Mở hàng | Hàng 2 của một nhánh cần 2 điểm trong nhánh; then chốt (hàng 3) cần 5 |
| Tuyệt kỹ | Cần 8 điểm đã dùng ở bất kỳ đâu trong mastery đó |
| Cây giao thoa | Node thường cần 3 điểm ở mỗi mastery; then chốt giao thoa cần 6 ở mỗi bên |
| Thanh kỹ năng | 5 kỹ năng chủ động và 1 tuyệt kỹ. Hai mastery vẫn chỉ có 1 ô tuyệt kỹ: phải chọn |
| Hoàn điểm | Miễn phí, bất cứ lúc nào ngoài chiến đấu |
| Mastery thứ hai | Mở cuối chương 1 (Ngải mở mặt trong của Mảnh Chuông) |

Mỗi mastery có **19 node, 34 bậc**: 3 nhánh, mỗi nhánh 2 kỹ năng chủ động (1 bậc), 3 nội tại (3, 3 và 2 bậc), 1 then chốt (1 bậc); cộng 1 tuyệt kỹ.
Hai mastery đầy đủ là 68 bậc, cây giao thoa 8 bậc: tổng 76 bậc cho 60 điểm. Không build nào lấy được tất cả, và build thuần một mastery (34 bậc) còn dư 26 điểm không có chỗ tiêu, nên mục 1.4 bổ sung phần thưởng chuyên sâu.

### 1.2 Một thanh lực, tám nhịp riêng [CHỐT]

Mọi kỹ năng chủ động tốn chung một thanh **Lực** (trong game đang gọi là Nộ): đầy 100, tăng khi chém trúng, gạt đạn, né sát nút; tự giảm sau 5 giây không giao chiến. Giữ một thanh chung để hai mastery không đẻ ra hai thanh tài nguyên trên màn hình.

Khác biệt giữa các mastery nằm ở **nhịp riêng**: một cơ chế phụ hiện bằng vài chấm hoặc một vạch nhỏ cạnh thanh Lực. Khi ghép hai mastery, người chơi có hai nhịp, và cây giao thoa là nơi nhịp này nuôi nhịp kia.

| Mã | Mastery | Nhịp riêng | Dấu để lại trên kẻ địch |
|---|---|---|---|
| CB | Chiến Binh | Chuỗi chém: đòn cuối chuỗi là đòn nặng; Thủ Thế đỡ đúng lúc | Choáng |
| HV | Hộ Vệ | **Khiên** 0–100: hấp thụ sát thương trước máu; tự mất 5 mỗi giây sau 4 giây không trúng đòn | Bị Khiêu Khích |
| ST | Sát Thủ | **Điểm Hiểm** 0–5: +1 khi đánh từ sau lưng, đánh kẻ đang Choáng hoặc Lạnh, hoặc né sát nút; đòn kết liễu tiêu hết | Độc (cộng dồn 5) |
| TS | Thợ Săn | **Tập Trung**: đứng cách kẻ địch gần nhất trên 80 trong 2 giây thì đòn hoặc kỹ năng kế tiếp +40%; một thú đồng hành | Dấu Săn (1 mục tiêu), Trói |
| NT | Nguyên Tố Sư | **Cộng Hưởng**: dùng phép khác hệ với phép vừa dùng thì phép đó +20% | Cháy, Lạnh, Giật |
| TL | Thuật Sĩ Linh Hồn | **Hồn** 0–5: mỗi kẻ chết trong 120 cho 1 Hồn; boss nhả 1 Hồn mỗi 10% máu | Nguyền |
| TT | Tư Tế | **Thành Kính** 0–100: tăng khi hồi máu cho ai đó hoặc đứng trong Đất Thiêng | Soi (bị thánh quang chiếu) |
| KS | Kỹ Sư Cổ Vật | **Nhiệt** 0–100: mỗi cổ vật cộng Nhiệt; trên 70 thiết bị mạnh +20%; chạm 100 thì Quá Nhiệt 4 giây, không dùng được cổ vật; tối đa 3 thiết bị | Bị thiết bị ngắm |

### 1.3 Tag và luật chống vòng lặp [CHỐT]

Tag dùng chung: Cận chiến, Đạn, Phép, Vùng, Triệu hồi, Thiết bị, Bẫy, Di chuyển, Hồi máu, Khiên, Dấu, Kết liễu, Lửa, Băng, Sét, Thánh, Hồn, Độc.

- **Dấu không tự kích hoạt gì.** Đặt một dấu lên kẻ địch không bao giờ là "đòn đánh" [ĐÃ CÓ].
- **Sát thương phụ không sinh sát thương phụ.** Nổ (Giàn Thiêu), phản đòn (Gai Khiên), sét nhảy từ node giao thoa, sát thương của thú, dư ảnh và thiết bị đều mang cờ "phụ": không tích Lực, không tích Điểm Hiểm, không kích node giao thoa nào khác [ĐÃ CÓ với Giàn Thiêu].
- **Mọi node "khi X thì Y" có thời gian chờ nội bộ** ghi ngay trong mô tả; nếu không ghi thì mặc định 1 giây.
- **Hưởng chỉ số khác với kích hoạt.** Thú, dư ảnh, thiết bị hưởng Tấn công và các node ghi rõ "đồng minh"; chúng không dùng unique và không kích node của chủ.
- **Giảm hồi chiêu trần 40%** [ĐÃ CÓ]. Không kỹ năng nào hồi dưới 1 giây, trừ khi mô tả nói rõ.
- **Giới hạn số lượng:** thú 1 (2 với then chốt), dư ảnh 3 (6), thiết bị 3, bẫy 3. Then chốt có nâng trần thì luôn kèm cái giá chia chỉ số.
- **Không khóa cứng boss.** Trói, đóng băng, kéo, khiêu khích không tác dụng lên boss; thay vào đó boss nhận Choáng 0,5 giây, tối đa một lần mỗi 6 giây từ các nguồn này.

### 1.4 Chơi thuần một mastery [CHỐT]

Người không lấy mastery thứ hai nhận **Độc Tấu**: một cây 8 node riêng cho từng mastery, cùng luật mở như cây giao thoa (3 điểm, then chốt 6 điểm, tính trong chính mastery đó).
Nguyên tắc: Độc Tấu đào sâu nhịp riêng thay vì thêm công cụ mới. Ví dụ Chiến Binh thuần có "Chuỗi Dài" (đòn cuối chuỗi lần thứ ba liên tiếp không bị ngắt gây gấp đôi), Thuật Sĩ thuần giữ được 8 Hồn.
Đặt mastery thứ hai, dù chỉ 1 điểm, sẽ khóa Độc Tấu. Thuần đổi độ rộng lấy độ sâu: 34 + 8 = 42 bậc có chỗ tiêu, 18 điểm còn lại đi vào **bậc tinh thông**: mỗi kỹ năng chủ động của mastery thuần nhận thêm tối đa 3 bậc, mỗi bậc +6% hiệu lực [GIẢ ĐỊNH].

### 1.5 Đòn thường theo vũ khí [CHỐT, chưa có]

Đòn thường do vũ khí quyết định, không do mastery: kiếm, dao, búa, giáo dùng chuỗi chém; cung bắn tên (chuỗi 3 phát, phát thứ ba xuyên). Mọi mastery cầm được mọi vũ khí. Kỹ năng tự mang hoạt ảnh của nó, nên Sát Thủ cầm búa vẫn dùng được Bước Bóng.

## 2. Tám mastery

Mỗi bảng: hai kỹ năng chủ động, ba nội tại (số bậc trong ngoặc), một then chốt kèm cái giá. Số hồi chiêu và Lực là [GIẢ ĐỊNH].

### 2.1 Chiến Binh (CB) [ĐÃ CÓ]

Người đứng giữa đám đông và ra đòn nặng. Mạnh nhất khi giữ được chuỗi chém không bị ngắt.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Thủ** | **Thủ Thế** (hồi 6s): giữ thế 1,2s; đòn bị đỡ chỉ gây 1/5; nhát kế tiếp gấp đôi. **Xô Khiên** (7s, 20 Lực): lao 90, 150%, choáng cả kẻ nặng | Da Sắt (3): +3 giáp. Vững Chãi (3): +12 máu. Phản Lực (2): đỡ được đòn cho 15 Lực | **Bất Khuất:** Thủ Thế hồi nhanh gấp đôi, đỡ đòn hồi 5% máu. Giá: chỉ còn 1 lần né |
| **Nộ** | **Xoáy** (40 Lực): 240% quanh người. **Hét Trận** (14s): +30 Lực; 6s gây +30%, chịu +20% | Khát Máu (3): +1,5% hút máu. Máu Nóng (3): +15% Lực nhận. Tử Thủ (2): dưới 35% máu +12% | **Giá Máu:** Lực không bị tiêu, Lực đầy cộng 30% sát thương. Giá: kỹ năng tốn Lực nay tốn 8% máu |
| **Binh Khí** | **Đâm Xuyên** (5s, 15 Lực): lướt 90, 160% mọi kẻ trên đường. **Dập Đất** (8s, 30 Lực): 180% vòng rộng, phá thế gấp đôi | Tầm Dài (3): +3 tầm. Tay Nặng (3): đòn cuối chuỗi +12%. Bổ Giáp (2): +10% lên kẻ Choáng | **Đòn Thứ Tư:** chuỗi thêm đòn thứ tư 240%. Giá: mọi nhát lấy đà chậm 1 nhịp |

**Tuyệt kỹ, Hồi Chuông** (45s): 400% vùng rộng, choáng 1,5s.

Phân biệt với Hộ Vệ: Chiến Binh đỡ **đúng lúc** để phản công; Hộ Vệ dựng lớp Khiên bền và kéo đòn về mình.

### 2.2 Hộ Vệ (HV)

Bức tường biết đi. Biến sát thương nhận vào thành tài nguyên, và là mastery duy nhất bảo vệ được người khác.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Thành Lũy** | **Dựng Khiên** (8s): +40 Khiên ngay. **Tường Chắn** (14s, 20 Lực): cắm một bức tường rộng 3 ô trong 5s, chặn đạn và chặn đường quái nhẹ | Dày Dạn (3): Khiên tối đa +10. Bền Bỉ (3): Khiên tự mất chậm hơn 20%. Đứng Vững (2): còn Khiên thì không bị đẩy lùi; bậc 2: không bị làm chậm | **Pháo Đài:** Khiên tối đa gấp đôi và không tự mất. Giá: tốc chạy −15% |
| **Trừng Phạt** | **Đập Khiên** (4s, 10 Lực): 140%, choáng 0,6s; nếu có từ 50 Khiên thì tiêu 25 Khiên để gây thêm 100%. **Phán Quyết** (12s): tiêu hết Khiên, gây sát thương vùng bằng 3% Tấn công cho mỗi điểm Khiên đã tiêu | Gai Khiên (3): kẻ đánh vào Khiên nhận 10% Tấn công (sát thương phụ). Nợ Máu (3): sau khi Khiên hấp thụ một đòn, đòn kế của bạn +8%. Búa Tạ (2): Đập Khiên phá thế +20% | **Ăn Miếng Trả Miếng:** 30% sát thương Khiên hấp thụ dội lại kẻ đánh. Giá: Khiên tối đa −30% |
| **Hộ Tống** | **Khiêu Khích** (10s): kẻ địch trong 90 phải đánh bạn 4s; +20 Khiên cho mỗi kẻ, tối đa 3 kẻ. **Vòng Che** (16s, 25 Lực): vòng tròn 5s, bạn và đồng minh bên trong nhận −30% sát thương | Chia Khiên (3): 10% Khiên bạn nhận được trao cho đồng minh trong 80. Canh Gác (3): +4 giáp khi có đồng minh gần, +2 khi một mình. Kiên Định (2): thời gian bị Choáng, Trói, Chậm −25% | **Thế Thân:** bạn nhận thay 40% sát thương của đồng minh trong 100. Giá: mọi nguồn hồi máu cho bạn −30% |

**Tuyệt kỹ, Thành Đồng** (60s): 5s Khiên đầy và không giảm; khi kết thúc nổ 300% quanh người.

Đi một mình: "đồng minh" gồm cả thú, dư ảnh và thiết bị, nên nhánh Hộ Tống không vô dụng khi solo, nhưng yếu nếu không ghép với TS, TL hoặc KS.

### 2.3 Sát Thủ (ST)

Vào nhanh, tích điểm, kết liễu, ra. Giấy mỏng: không có công cụ phòng thủ nào ngoài việc không đứng đó.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Bóng** | **Bước Bóng** (6s, 10 Lực): hiện ra sau lưng một kẻ trong 120; đòn kế chắc chắn +1 Điểm Hiểm. **Màn Khói** (14s): 3s quái mất dấu bạn, +30% tốc chạy; đòn đầu tiên ra khỏi khói chí mạng | Nhẹ Chân (3): +3% tốc chạy. Đánh Lén (3): đòn từ sau lưng +8%. Thoát Hiểm (2): né hồi nhanh hơn 15% | **Vô Hình:** sau mỗi đòn kết liễu, tàng hình 1,5s. Giá: máu tối đa −20% |
| **Độc** | **Tẩm Độc** (12s): 8s, mỗi đòn chém gây 1 cộng dồn Độc (20% Tấn công mỗi giây, 4s, tối đa 5). **Phi Tiêu Độc** (4s, 10 Lực): quạt 3 phi tiêu, mỗi cái 60% và 1 cộng dồn Độc | Độc Đậm (3): Độc +10%. Ngấm Sâu (3): Độc dài thêm 1s. Nhiễm Trùng (2): kẻ trúng Độc gây ít hơn 5% | **Bùng Độc:** đòn kết liễu kích nổ toàn bộ Độc còn lại thành sát thương tức thì. Giá: Độc chỉ cộng dồn tới 3 |
| **Kết Liễu** | **Rạch** (kết liễu, 3s): 60% nhân với (1 + số Điểm Hiểm). **Hành Quyết** (kết liễu, 10s): 100% mỗi điểm; kẻ thường còn dưới 6% máu mỗi điểm thì chết ngay; boss và elite chỉ nhận sát thương | Sắc Lẹm (3): +3% chí mạng. Chỗ Hiểm (3): chí mạng gây thêm 10%. Tàn Nhẫn (2): +5% lên kẻ dưới 35% máu | **Sáu Điểm:** giữ được 6 Điểm Hiểm; kết liễu ở 6 điểm chắc chắn chí mạng. Giá: đòn thường −15% |

**Tuyệt kỹ, Ngàn Vết Cắt** (50s): lướt qua tối đa 6 kẻ, mỗi kẻ 180% và cho 1 Điểm Hiểm; bất khả xâm phạm khi đang lướt.

### 2.4 Thợ Săn (TS)

Giữ khoảng cách, dọn sẵn bãi chiến, để con thú giữ chân. Mạnh khi được chuẩn bị, yếu khi bị áp sát bất ngờ.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Thiện Xạ** | **Phát Ngắm** (5s, 15 Lực): đứng ngắm 0,6s rồi bắn xuyên 220%. **Mưa Tên** (10s, 25 Lực): vùng tròn 3s, 40% mỗi nửa giây | Mắt Ưng (3): +4% lên kẻ cách trên 100. Tay Vững (3): Tập Trung tích nhanh hơn 20%. Xuyên Giáp (2): đòn tầm xa phá thế +15% | **Một Phát:** Phát Ngắm lên kẻ còn đầy máu +100%. Giá: Tập Trung mất ngay khi bạn trúng đòn, và phải tích lại từ đầu |
| **Bẫy** | **Bẫy Kẹp** (6s): đặt bẫy (tối đa 3); kẻ dẫm phải bị Trói 2s và nhận 120%. **Bẫy Nổ** (10s, 15 Lực): nổ 200% vùng nhỏ khi có kẻ tới gần | Thợ Bẫy (3): bẫy hồi nhanh hơn 10%; bậc 3: tối đa 4 bẫy. Sập Bẫy (3): kẻ đang bị Trói nhận +6%. Giăng Xa (2): ném bẫy tới điểm ngắm thay vì đặt dưới chân | **Liên Hoàn:** một bẫy sập thì mọi bẫy khác trong 100 sập theo. Giá: bẫy tự biến mất sau 8s |
| **Thú** | **Xua Thú** (7s): thú vồ mục tiêu ngắm, 160%, giữ chân 1,5s. **Dấu Săn** (8s): đánh dấu một kẻ 10s; nó nhận +15% từ bạn và thú; thú ưu tiên nó | Thú Khỏe (3): máu thú +15%. Nanh Vuốt (3): sát thương thú +10%. Gắn Bó (2): thú gục thì đứng dậy nhanh hơn 25% | **Bầy Đôi:** hai thú. Giá: mỗi con chỉ có 60% chỉ số |

**Tuyệt kỹ, Cuộc Săn** (60s): 8s mọi kẻ địch trên màn hình mang Dấu Săn và Tập Trung luôn đầy.

Thú đồng hành: một con chó săn Vọng, 40% máu của chủ, đòn 30% Tấn công; gục thì 12s sau đứng dậy. Thú là sát thương phụ.

### 2.5 Nguyên Tố Sư (NT) [ĐÃ CÓ 9/19 node]

Ba hệ, ba dấu. Luân phiên hệ để hưởng Cộng Hưởng; chồng dấu để mở node giao thoa. Node đánh dấu ★ là node mới so với game.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Lửa** | **Tia Than** (1,5s, 10 Lực): 120%, gây Cháy 4s (30% mỗi giây). ★**Tường Lửa** (9s, 20 Lực): vệt lửa 4s; kẻ bước qua bị Cháy | Mồi Lửa (3): Cháy +20%. ★Hơi Nóng (3): +4% lên kẻ đang Cháy. ★Tro Tàn (2): kẻ chết khi đang Cháy trả 3 Lực | **Giàn Thiêu:** kẻ chết khi Cháy nổ 150% (không nổ dây chuyền). Giá: Cháy chỉ dài một nửa |
| **Băng** | **Vòng Sương** (8s, 20 Lực): 100% quanh người, Lạnh 4s (chậm một nửa). ★**Mũi Băng** (6s, 15 Lực): xuyên thẳng 130%; kẻ đang Lạnh bị đóng băng 1s | Rét Sâu (3): Lạnh +1s. ★Giá Buốt (3): kẻ Lạnh gây ít hơn 5%. ★Băng Giáp (2): dùng phép Băng cho +3 giáp trong 4s | **Giòn:** kẻ Lạnh nhận +25% từ đòn của bạn. Giá: né hồi chậm gấp đôi |
| **Sét** | **Sét Chuyền** (5s, 25 Lực): 140% kẻ gần nhất, nhảy 3 kẻ nữa 100%; Giật 5s (+15% sát thương nhận). ★**Lồng Sét** (12s, 25 Lực): vùng 4s; kẻ bên trong bị Giật liên tục và nhận 30% mỗi giây | Tĩnh Điện (3): kẻ Giật nhận thêm +5%. ★Dẫn Truyền (3): sét nhảy xa hơn 15. ★Quá Áp (2): 5% cơ hội phép Sét không tốn Lực | **Quá Tải:** Sét Chuyền nhảy 6 kẻ. Giá: tốn thêm 10 Lực |

★**Tuyệt kỹ, Tam Tai** (55s): tại điểm ngắm, ba nhịp cách nhau nửa giây: lửa rơi, vòng băng, sét dội; mỗi nhịp 200% và để lại dấu của hệ đó.

### 2.6 Thuật Sĩ Linh Hồn (TL)

Cái chết của kẻ địch là nguyên liệu. Khởi đầu chậm (chưa có Hồn), càng đánh càng đông quân.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Triệu Hồi** | **Gọi Dư Ảnh** (3s, 1 Hồn): gọi một chiến binh dư ảnh, tồn tại 20s, tối đa 3; đòn 35% Tấn công. **Hiến Tế** (6s): cho một dư ảnh nổ, 220% vùng | Đông Quân (3): máu dư ảnh +10%; bậc 3: tối đa 4. Sắc Bóng (3): sát thương dư ảnh +10%. Dai Dẳng (2): tồn tại thêm 4s | **Quân Đoàn:** tối đa gấp đôi. Giá: mỗi dư ảnh gây một nửa sát thương |
| **Nguyền** | **Lời Nguyền Yếu** (10s, 15 Lực): vùng; kẻ địch gây −25% trong 8s. **Xiềng Hồn** (12s, 20 Lực): nối 3 kẻ trong 6s; sát thương lên một kẻ chia 30% sang hai kẻ kia (sát thương phụ) | Nguyền Sâu (3): Nguyền +1,5s. Mục Rữa (3): kẻ bị Nguyền nhận +4%. Lây Lan (2): kẻ bị Nguyền chết truyền Nguyền sang 1 kẻ gần; bậc 2: 2 kẻ | **Một Lời:** chỉ một kẻ mang Nguyền, nhưng hiệu lực gấp đôi và không hết hạn. Giá: Nguyền không còn tác dụng vùng |
| **Gặt** | **Lưỡi Hái** (5s, 15 Lực): quét 150%; mỗi kẻ trúng hồi 2% máu; giết bằng đòn này cho 2 Hồn. **Hóa Hồn** (15s): tiêu hết Hồn; mỗi Hồn cho +12% sát thương và +8% tốc chạy trong 8s | Gặt Hái (3): 10% cơ hội kẻ chết rơi 2 Hồn. Hồn Nuôi (3): mỗi Hồn đang giữ hồi 0,3 máu mỗi giây. Bình Hồn (2): giữ thêm 1 Hồn | **Đói Hồn:** mỗi Hồn đang giữ +6% sát thương. Giá: cứ 4s mất 1 Hồn |

**Tuyệt kỹ, Đêm Rạn Nhỏ** (70s): 8s, mọi kẻ địch chết trong 150 đứng dậy làm dư ảnh cho bạn, không tính vào giới hạn, tan khi hết giờ.

Dư ảnh là sát thương phụ, không tích Lực, không kích node của chủ. Lore: đây chính là thứ Hội Giữ Lặng sợ nhất.

### 2.7 Tư Tế (TT)

Người giữ mõ. Hồi máu, ban phước, và thanh tẩy Dư Ảnh. Sát thương thấp nhất trong tám mastery nếu đi thuần, nhưng là mastery duy nhất gỡ được hiệu ứng có lợi của quái.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Chữa Lành** | **Tiếng Mõ** (10s, 20 Lực): hồi 25% máu cho bạn và đồng minh trong 80. **Đất Thiêng** (14s, 20 Lực): vòng 6s; đồng minh bên trong hồi 3% máu mỗi giây; bạn tích Thành Kính khi đứng trong đó | Tay Ấm (3): hồi máu +8%. Dư Âm (3): máu hồi thừa thành Khiên, tối đa 5% máu. Kiên Nhẫn (2): Thành Kính tích nhanh hơn 20% | **Một Mạch:** mọi hồi máu của bạn trải ra 4s nhưng +60%. Giá: không còn hồi máu tức thời |
| **Thanh Tẩy** | **Ấn Trừng** (3s, 10 Lực): 130% thánh lên một kẻ, để dấu Soi 6s. **Trừ Tà** (12s, 25 Lực): vùng 100%; gỡ khiên và hào quang của quái, tắt dấu elite trong 4s | Lửa Thiêng (3): sát thương thánh +5%. Sáng Soi (3): kẻ bị Soi nhận +3%. Phán Xét (2): Ấn Trừng ngắt đòn niệm của kẻ nhẹ; bậc 2: cả kẻ nặng | **Cuồng Tín:** khi Thành Kính đầy, Ấn Trừng không hồi chiêu trong 5s rồi Thành Kính về 0. Giá: dưới 50 Thành Kính bạn không hồi máu được cho chính mình |
| **Ban Phước** | **Chúc Lành** (16s, 20 Lực): 8s, bạn và đồng minh +15% sát thương và tốc chạy. **Lời Nguyện** (40s): 3s, một đồng minh (hoặc bạn) không thể xuống dưới 1 máu | Lan Tỏa (3): tầm phước +20. Bền Lâu (3): phước dài thêm 1s. Chở Che (2): người đang mang phước nhận −5% sát thương | **Hiến Dâng:** phước bạn ban cho người khác mạnh gấp rưỡi. Giá: bạn không nhận phước của chính mình |

**Tuyệt kỹ, Canh Ba** (90s): gọi dậy một đồng minh đã gục; nếu không có ai gục, trong 6s tới nếu bạn chết thì sống lại với 40% máu.

### 2.8 Kỹ Sư Cổ Vật (KS)

Người mang hòm máy nhặt từ Hầm Vọng. Đặt thiết bị rồi quản lý Nhiệt: càng nóng càng mạnh, quá tay thì đứng hình.

| Nhánh | Chủ động | Nội tại | Then chốt |
|---|---|---|---|
| **Cơ Quan** | **Trụ Nỏ** (8s, +25 Nhiệt): trụ bắn 30% mỗi nửa giây, 12s. **Mìn Chuông** (5s, +15 Nhiệt): mìn nổ 180%, choáng 0,5s | Thợ Giỏi (3): sát thương thiết bị +10%. Bền Máy (3): thiết bị tồn tại thêm 3s. Tháo Lắp (2): thu hồi thiết bị trả lại 25% hồi chiêu | **Xưởng Di Động:** thiết bị bay theo bạn. Giá: tối đa 2 thiết bị |
| **Hơi Nước** | **Xả Hơi** (6s): xả hết Nhiệt thành hình nón, 3% Tấn công mỗi điểm Nhiệt, đẩy lùi. **Tăng Áp** (12s): +40 Nhiệt ngay; 5s tốc đánh +25% | Van An Toàn (3): Quá Nhiệt ngắn hơn 0,5s. Lõi Nóng (3): trên 70 Nhiệt +4% sát thương. Tản Nhiệt (2): Nhiệt giảm nhanh hơn 20% khi không giao chiến | **Chạy Quá Tải:** không bao giờ Quá Nhiệt. Giá: trên 100 Nhiệt mất 3% máu mỗi giây cho tới khi xả |
| **Cổ Vật** | **Móc Kéo** (7s, +10 Nhiệt): kéo bạn tới điểm ngắm, hoặc kéo một kẻ nhẹ về phía bạn. **Chuông Câm** (16s, +30 Nhiệt): vùng im lặng 4s; quái bên trong không niệm được, đạn bay chậm một nửa | Kính Soi (3): +5% lên kẻ đang lấy đà. Pin Vọng (3): kỹ năng tốn ít Lực hơn 5%. Túi Đồ Nghề (2): bình máu hồi nhanh hơn 15% | **Nguyên Mẫu:** thêm ô kỹ năng thứ sáu, chỉ nhận kỹ năng KS. Giá: tuyệt kỹ hồi chậm gấp đôi |

**Tuyệt kỹ, Cỗ Máy Chuông** (70s): gọi một cỗ máy 10s; nó phát sóng âm 100% mỗi giây quanh mình và kéo quái lại gần.

Thiết bị là sát thương phụ. Kỹ năng KS không tốn Lực mà cộng Nhiệt, nên KS là mastery ghép "rẻ Lực" cho mọi mastery khác.

## 3. So sánh nhanh [GIẢ ĐỊNH, thang 1–5]

| Mastery | Sát thương | Sống sót | Cơ động | Hỗ trợ | Độ khó vận hành | Phụ thuộc đồ |
|---|---|---|---|---|---|---|
| Chiến Binh | 4 | 4 | 3 | 1 | 2 | 3 |
| Hộ Vệ | 2 | 5 | 2 | 4 | 2 | 2 |
| Sát Thủ | 5 | 2 | 5 | 1 | 4 | 4 |
| Thợ Săn | 4 | 2 | 3 | 2 | 3 | 3 |
| Nguyên Tố Sư | 4 | 2 | 2 | 2 | 3 | 3 |
| Thuật Sĩ Linh Hồn | 3 | 3 | 2 | 3 | 3 | 2 |
| Tư Tế | 2 | 4 | 2 | 5 | 2 | 2 |
| Kỹ Sư Cổ Vật | 3 | 3 | 4 | 3 | 5 | 3 |

Không mastery nào được 5 ở cả sát thương lẫn sống sót. Ghép hai mastery lấp điểm yếu nhưng chia điểm: build lai 60 điểm thường có khoảng 26 + 26 + 8.

## 4. Kiểm tra ngân sách điểm

Ba mốc của một Kiếm Bão (CB + NT), dùng node đã có trong game:

| Mốc | Phân bổ | Tổng | Hợp lệ |
|---|---|---|---|
| Cấp 12 | CB Nộ: Xoáy, Khát Máu 3, Hét Trận (5). CB Binh Khí: Đâm Xuyên, Tầm Dài 1 (2). NT Lửa: Tia Than, Mồi Lửa 2 (3). Giao thoa: Thổi Lửa (1). Dư 1 | 11/12 | Hét Trận cần 2 điểm Nộ: có 4. Thổi Lửa cần 3 CB và 3 NT: có 7 và 3 |
| Cấp 30 | Thêm: Máu Nóng 1, Giá Máu (Nộ đủ 6 trước đó), Hồi Chuông, Vòng Sương, Rét Sâu 3, Sét Chuyền, Tĩnh Điện 2, Vỡ Băng, Tim Lò, Dư Quang, Kiếm Bão, Tay Nặng 3, Tầm Dài thêm 2 (17 + 2 = 19 bậc mới, cộng 11 cũ) | 30/30 | Giá Máu cần 5 điểm Nộ: Xoáy 1 + Khát Máu 3 + Hét Trận 1 + Máu Nóng 1 = 6. Hồi Chuông cần 8 điểm CB. Kiếm Bão cần 6 ở mỗi bên: CB 15, NT 10, giao thoa 5 |
| Cấp 60 | CB 26, NT 26, giao thoa 8 | 60/60 | Không lấy đủ cả hai cây (68 bậc): phải bỏ 16 bậc, thường là một nhánh của mỗi bên |

## 5. So với game hiện tại

| Hạng mục | Game | Tài liệu này | Việc cần làm |
|---|---|---|---|
| Chiến Binh | Đủ 19 node | Giữ nguyên | Không |
| Nguyên Tố Sư | Đủ 19 node, Tam Tai, Cộng Hưởng (2026-11-12) | Giữ nguyên | Không |
| Kiếm Bão | Đủ 8 node | Giữ nguyên | Không |
| Sáu mastery còn lại | Chưa có | Thiết kế xong | Mỗi mastery cần cơ chế nhịp riêng trong code |
| 27 cây giao thoa còn lại | Chưa có | Thiết kế xong ở HYBRIDS.md | Làm theo từng cặp |
| Tên tài nguyên | Nộ | Lực | Đổi chữ hiển thị |
| Chọn mastery | Chọn CB hoặc NT lúc tạo nhân vật; mastery thứ hai tự là cái còn lại | Chọn 1 trong 8, rồi chọn mastery thứ hai | Màn hình chọn mastery thứ hai khi có mastery thứ ba |
| Độc Tấu, bậc tinh thông | Chưa có | Mục 1.4 | Sau khi có ít nhất 4 mastery |
| Đòn thường theo vũ khí | Chỉ có chuỗi chém | Thêm cung | Cần trước khi làm Thợ Săn |

Thứ tự đề xuất: hoàn thiện Nguyên Tố Sư, rồi Sát Thủ (nhịp Điểm Hiểm dễ thấy khác biệt nhất), rồi Thuật Sĩ Linh Hồn (kiểm chứng triệu hồi), sau đó mới tới bốn mastery còn lại. Mỗi mastery mới kéo theo các cây giao thoa với những mastery đã có.
