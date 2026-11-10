# Lộ trình phát triển — Dungeon Core: Elemental Rebirth

Cập nhật: 2026-11-10. Trạng thái hiện tại nằm trong `CLAUDE.md` (gốc repo) và `README.md`.

Thứ tự dưới đây là thứ tự nên làm. Lý do chung: game đã có rất nhiều tính năng nhưng **chưa
ai chơi tay đủ lâu**, nên việc đáng giá nhất lúc này là kiểm chứng và làm cho chắc, không phải
thêm tính năng.

## Giai đoạn 0 — Kiểm chứng những gì đã có (làm trước tiên)

Mọi thứ ở đây mới chỉ được bot kiểm thử. Bạn cần tự chơi, ghi lại, rồi mới sửa.

| Việc | Cách làm | Xong khi |
|---|---|---|
| Chơi tay 10 lượt, mỗi hero ít nhất 1 lượt | Ghi: chết ở tầng nào, vì cái gì, lượt dài bao lâu | Có bảng ghi chép 10 lượt |
| Thử tay cầm thật (1 và 2 tay) | Kiểm tra từng nút theo bảng trong README | Mọi nút đúng, menu điều khiển được |
| Thử phím người chơi 2 trên bàn phím | Chơi co-op 1 tầng với 2 người thật | Không kẹt phím, không tranh phím với người 1 |
| Thử LAN trên 2 máy thật | 1 PC host, 1 PC khác join qua Wi-Fi | Tự tìm thấy host, chơi hết 1 tầng không giật |
| Build APK Android | Cài Android SDK, khai báo trong Godot, export | APK cài được, cần ảo dùng được trên máy thật |

## Giai đoạn 1 — Cân bằng và cảm giác chơi

Phụ thuộc vào ghi chép của giai đoạn 0. Mục tiêu đề xuất (từ GDD cũ):

- Một lượt thắng dài 20–35 phút; người mới thắng khoảng 15–25% sau 10 lượt.
- Quái thường chết trong 1–3 giây; boss 2–4 phút.

Việc cụ thể:

1. **Chỉnh số** trong `src/data.gd`: máu quái, sát thương vũ khí, giá shop, giá gems ở sảnh.
2. **Đường cong gems**: hiện một lượt thắng cho khoảng 200 gems, trong khi cây kỹ năng đầy đủ
   tốn 465 gems mỗi hero. Quyết định muốn người chơi mất bao nhiêu lượt để mở hết.
3. **Hệ "Cunning"** (quái tự học): kiểm tra xem nó có làm người chơi yếu bị nản không; nếu có,
   hạ trần từ 0.9 xuống.
4. **Hướng dẫn tân thủ**: ĐÃ CÓ 4 gợi ý lần đầu (đổi vũ khí, phản ứng, Burst, giáp). Còn cần
   kiểm tra với người chơi mới xem có đủ không.
5. **Cảm giác đánh**: âm thanh và rung cho từng loại vũ khí, hiệu ứng khi quái chết.

## Giai đoạn 2 — Hoàn thiện những chỗ còn dở

| Hạng mục | Hiện trạng | Cần làm |
|---|---|---|
| Tiếng Việt | Font pixel chỉ có chữ in hoa tiếng Anh | Vẽ thêm glyph có dấu, tách chuỗi ra bảng dịch |
| Cài đặt | ĐÃ CÓ: âm lượng, toàn màn hình, tắt rung | Còn thiếu: đổi phím |
| LAN | Rung màn hình, vệt lướt chưa đồng bộ; khách không dùng được NPC; khách không tính nhiệm vụ | Bổ sung vào `Net.snapshot`, gửi tiến độ nhiệm vụ cho khách |
| Co-op | Tối đa 2 người | Cân nhắc 3–4 người (cần làm lại HUD và camera) |
| Hero dệt | Chỉ giữ được 1 hero | Cho lưu 3 ô |
| Người chơi 2 | Dùng chung pet, thú cưỡi, thuốc nhuộm với người 1 | Cho chọn riêng |
| Hoạt ảnh | Hero và quái chỉ có 3 khung đi bộ | Thêm khung tấn công, trúng đòn, chết |
| Lưu giữa lượt | ĐÃ CÓ cho chơi đơn (lưu đầu mỗi tầng, "Continue" ở Run Board) | Chưa lưu lượt co-op |

## Giai đoạn 3 — Nội dung mới

Chỉ nên làm sau khi giai đoạn 1 ổn, vì mỗi nội dung mới lại cần cân bằng.

1. **Khu thứ 4 và boss cuối riêng** — hiện game kết thúc ở khu 3 với boss chọn ngẫu nhiên.
2. **Thêm vũ khí** (hiện 17): ưu tiên loại có cách chơi khác hẳn — boomerang, khiên, vũ khí nạp lực,
   triệu hồi.
3. **Thêm quái có cơ chế riêng** (hiện 15): quái cầm khiên phải đánh từ sau, quái hồi máu cho
   đồng đội, quái tự nổ theo dây chuyền.
4. **Sự kiện giữa phòng**: phòng đánh cược, phòng thử thách giới hạn thời gian, NPC cần cứu.
5. **Chế độ chơi**: Boss Rush, Vô tận, thử thách tuần với luật riêng.
6. **Nguyên tố thứ 5** (ví dụ ánh sáng hoặc bóng tối) — thêm 4 phản ứng mới; ảnh hưởng lớn tới
   cân bằng nên làm sau cùng.

## Giai đoạn 4 — Phát hành

| Việc | Ghi chú |
|---|---|
| Trang cửa hàng (itch.io trước, Steam sau) | Cần 5–8 ảnh chụp, 1 trailer 30–60 giây, mô tả ngắn |
| Biểu tượng và màn hình tải | Vẽ bằng chính bộ sinh pixel trong `src/art.gd` |
| Build Windows + Android + Web | Web cần kiểm tra âm thanh và hiệu năng shader ánh sáng |
| Chơi thử kín | 5–10 người lạ, xem họ chơi mà không giải thích |
| Kiểm tra pháp lý tên gọi | Tra xem "Dungeon Core" có trùng nhãn hiệu game khác không |
| Nếu lên mobile | Quyết định mô hình: trả phí một lần, hay miễn phí kèm quảng cáo/mua trong game |

## Rủi ro cần biết

- **Phạm vi quá rộng.** Game có nhiều hệ thống hơn mức một người kiểm thử nổi. Nếu thiếu thời
  gian, cắt bớt còn hơn giữ lại tính năng chưa cân bằng (ứng viên cắt: thú cưỡi, vườn, máy viên nang).
- **`src/game.gd` đã hơn 2.700 dòng.** Trước khi thêm nội dung lớn nên tách phần vẽ và phần quái
  ra file riêng.
- **Mã mạng tin tưởng host hoàn toàn.** Đủ cho chơi với bạn bè qua LAN; không đủ nếu sau này làm
  chơi qua Internet với người lạ.
- **Bot kiểm thử chạy ở chế độ bất tử**, nên nó chỉ bắt lỗi kẹt và lỗi script, không nói gì về
  độ khó.

## Đề xuất 3 việc tiếp theo

1. Chơi tay 10 lượt và ghi chép (giai đoạn 0, dòng đầu).
2. Chỉnh số theo ghi chép đó (giai đoạn 1, mục 1–2).
3. Tiếng Việt trong game (giai đoạn 2) — cần vẽ thêm glyph có dấu cho font pixel.
