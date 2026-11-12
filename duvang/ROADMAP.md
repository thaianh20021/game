# Dư Vang: hướng phát triển

Tài liệu này đối chiếu những gì chủ dự án đã yêu cầu trong hai bản brief và các lần chỉnh hướng
(2026-11-11 và 2026-11-12) với những gì đang có trong `duvang/`. Cập nhật mỗi khi xong một mốc.

## Chủ dự án muốn gì

- Một MMORPG pixel 2D có cảm giác phiêu lưu của RPG di động cổ điển (kiểu Inotia, Zenonia): thị trấn,
  NPC, nhiệm vụ, bãi săn quái, hầm ngục có boss, lên cấp, cày đồ. Không phải game sinh tồn theo đợt.
- Nội dung nguyên bản: không chép tên, nhân vật, bản đồ, cốt truyện hay hình ảnh của game khác.
- Thứ tự ưu tiên: combat đã tay, kết hợp hai mastery tạo build khác nhau, loot đổi cách chơi,
  boss khó mà công bằng, thế giới và cốt truyện có chiều sâu, multiplayer có giá trị.
- Hệ kết hợp hai mastery là trụ cột quan trọng nhất: 8 mastery, 28 cặp, mỗi cặp một cây giao thoa.
- Làm một người chơi trước. Online chỉ làm sau khi phần chơi đơn đã vui.
- Asset do AI sinh qua 9router; nhân vật phải chi tiết, không dùng kiểu khối đơn giản.
- Không bán sức mạnh, không nhiệm vụ hằng ngày bắt buộc, không nâng cấp làm vỡ đồ.

## Đang có (chương 1, một người chơi)

- Combat: chuỗi 3 đòn có lấy đà và thu đòn, lướt né 2 vạch, một kỹ năng dùng nộ, cảnh báo đỏ son.
- Ba khu: Trấn Mõ Gỗ, Đầm Lau Tro, Bến Phà Cũ. Ba loại quái và một boss ba đòn.
- Sáu nhiệm vụ chính, hai nhiệm vụ phụ, một lựa chọn có hậu quả, vật đọc được trong thế giới,
  cảnh Vãn đốt sổ, đoạn mở đầu có lời dẫn.
- Lên cấp, ba ô trang bị, ba độ hiếm, sáu thuộc tính ngẫu nhiên, một unique, cửa hàng, lưu game.
- Cây kỹ năng Chiến Binh: 6 kỹ năng chủ động, 9 nội tại, 3 keystone, 1 tuyệt kỹ; hoàn điểm miễn phí.
  So với brief (8 kỹ năng, 12 nội tại, 2 biến thể mỗi kỹ năng) còn thiếu 2 kỹ năng, 3 nội tại và toàn bộ biến thể.

## Còn thiếu so với vertical slice trong brief

| Hạng mục | Brief yêu cầu | Đang có | Ưu tiên |
|---|---|---|---|
| Mastery | 2 mastery đầy đủ và 1 cây giao thoa | Chiến Binh 19 node, Pháp Sư Nguyên Tố 9 node (mỏng hơn brief), cây giao thoa 8 node | 1 |
| Ô kỹ năng | 5 kỹ năng, 1 tuyệt kỹ | Đủ: 5 ô và 1 tuyệt kỹ | xong |
| Build | 3 build khác nhau chạy được khi chưa có unique | 3 nhánh với 3 keystone; chưa ai chơi thử để biết có khác nhau thật không | 1 |
| Loại quái | 6 loại | 6 loại và 1 boss giữa hầm | xong |
| Elite | 2 modifier đổi cách đánh | 2: Volatile (nổ sau khi chết), Warding (che cho quái quanh nó) | xong |
| Boss | 2 boss | 2: Toll Keeper (kiểm tra ngắt đòn) và Người Gác Phà | xong |
| Hầm ngục | Dài 15–20 phút | 6 đảo, 20 quái, 2 boss; chưa đo thời gian chơi thật | 2 |
| Trang bị | 20 base, 12 affix, 4 unique | Đủ: 20 base, 12 affix theo loại đồ, 4 unique | xong |
| Loot filter | Cơ bản | Có: 3 mức, bán nhanh đồ dưới mức lọc | xong |
| Chữ tiếng Việt | Tên riêng và hội thoại tiếng Việt | Xong: font pixel có đủ dấu, toàn bộ chữ trong game đã dịch (chữ in hoa) | xong |
| Hoạt ảnh | Chạy, đánh, niệm, trúng đòn, chết | Nhân vật: đi, chém, niệm (tư thế lấy đà 0,25 giây sau mỗi phép), kéo cung, giật lùi khi trúng đòn, ngã rồi tan khi chết; quái mỗi con 3 tư thế. Vẽ bằng biến đổi hình có sẵn, chưa có khung hình riêng | 3 |
| Hướng nhìn | 4 hướng | Xong: ngang (lật trái phải), từ trước, từ sau; mỗi hướng 6 khung hình | xong |
| Tay cầm | Dùng được mọi menu | Menu, túi đồ và cửa hàng đi được bằng cần gạt hoặc WASD (A hoặc Space để chọn; RB mua bình máu, bấm cần phải bán đồ thường). Cây kỹ năng: D-pad lên mở, cần gạt chọn node, A học, D-pad phải (G) đổi thẻ. Chưa thử trên tay cầm thật | xong |
| Nhạc | Mỗi vùng một bản sắc | 4 bản tổng hợp: trấn, đầm, hầm, boss | xong |
| Online | Co-op 2–4 người, server có thẩm quyền | Chưa có gì | sau cùng |

## Thứ tự làm tiếp theo

1. **Xong (2026-11-12): mastery thứ nhất (Chiến Binh):** cây 3 nhánh, 5 ô kỹ năng và 1 tuyệt kỹ, điểm kỹ năng
   theo cấp, hoàn điểm rẻ. Đây là thứ biến game từ "đánh quái" thành "dựng build".
2. **Xong bản đầu (2026-11-12): mastery thứ hai (Pháp Sư Nguyên Tố) và cây giao thoa (Tempest Blade):** mở ở cuối chương 1 đúng như truyện đã dẫn (mặt trong của
   Mảnh Chuông). Chọn mastery thứ hai theo bảng 28 Hợp Âm ở Phần II của GDD, phần này chưa viết.
3. **Xong (2026-11-12): mở rộng bãi săn và hầm ngục:** thêm 3 loại quái, 2 modifier elite, boss thứ hai, kéo dài Bến Phà Cũ.
4. **Xong (2026-11-12): loot:** đủ 20 base, 12 affix, 4 unique có tương tác với kỹ năng, loot filter.
5. **Xong (2026-11-12): chữ tiếng Việt, nhạc, bốn hướng nhìn; thêm 36 icon kỹ năng, 24 icon đồ và 3 icon dấu trạng thái thay cho chữ viết tắt.**
6. **Xong bản đầu (2026-11-12): chương 2 (Rừng Thở)** theo Hồi 2 của GDD: 2 khu, 3 quái, boss Mẹ Rễ Ngàn Tên, 5 nhiệm vụ chính, 1 phụ, lựa chọn Làng Thì Thầm. Chưa có: hậu quả của lựa chọn hiện ra trên bản đồ, hầm ngục chưa đo thời gian.
7. **Co-op 2–4 người** với server có thẩm quyền, rồi mới tới thị trấn chung.

Thiết kế class: xong 8 mastery và 28 cây giao thoa trong `docs/` (2026-11-12). Trong game mới có Chiến Binh, 9/19 node Nguyên Tố Sư và cây Kiếm Bão. Việc kế tiếp: hoàn thiện Nguyên Tố Sư, rồi Sát Thủ, rồi Thuật Sĩ Linh Hồn.

## Cập nhật 2026-11-12 (giao diện và class)

Xong: màn hình chính, tạo nhân vật chọn mastery đầu (Chiến Binh hoặc Nguyên Tố Sư), lời dẫn cốt truyện toàn màn,
pause (Esc), cài đặt (âm thanh, nhạc, rung, chớp trắng, số sát thương, toàn màn hình), nhật ký tóm tắt cốt truyện,
Nguyên Tố Sư đủ 19 node và tuyệt kỹ Tam Tai, cơ chế Cộng Hưởng.

Thứ tự mastery tiếp theo (chủ dự án chốt): **Sát Thủ**, rồi **Thuật Sĩ Linh Hồn**. Mỗi mastery mới cần:
nhịp riêng trong code (Điểm Hiểm, Hồn), 19 node, icon, và cây giao thoa với từng mastery đã có
(Sát Thủ: Lưỡi Bóng và Dạ Lôi; Thuật Sĩ: Kiếm Tang, Tro Hồn, Gặt Hồn). Thiết kế ở `docs/`.
Khi có mastery thứ ba, người chơi phải được chọn mastery thứ hai (hiện tại nó tự là cái còn lại).

## Cập nhật 2026-11-12 (Sát Thủ)

Xong: Sát Thủ đủ 19 node (Điểm Hiểm, Độc, hai đòn kết liễu, tuyệt kỹ Ngàn Vết Cắt), hai cây giao thoa Lưỡi Bóng và Dạ Lôi,
35 icon, màn hình chọn mastery thứ hai khi Mảnh Chuông thức. Tiếp theo: **Thuật Sĩ Linh Hồn** (Hồn, dư ảnh) cùng ba cây
giao thoa Kiếm Tang, Tro Hồn, Gặt Hồn.

## Cập nhật 2026-11-12 (Thuật Sĩ Linh Hồn, chưa có test)

Xong phần code: Thuật Sĩ Linh Hồn 19 node (Hồn, dư ảnh, nguyền, xiềng, Lưỡi Hái, Hóa Hồn, tuyệt kỹ Đêm Rạn Nhỏ) và ba cây
giao thoa Kiếm Tang, Tro Hồn, Gặt Hồn (mỗi cây 8 node). Chủ dự án yêu cầu không viết test ở bước này; việc test giao cho
model nhẹ hơn. Mới chỉ kiểm tra game khởi động và dùng từng kỹ năng một lần không báo lỗi.

Việc cho người viết test:
- `tests/skills.gd` đang đòi 81 node, 18 kỹ năng chủ động, 12 then chốt, 3 tuyệt kỹ. Số đúng giờ là 124, 24, 19, 4.
- `tests/menu.gd` đếm node theo mảng 6 phần tử `[19, 19, 8, 19, 8, 8]`; giờ cần 10 phần tử, thêm `19, 8, 8, 8`.
- Viết `tests/warlock.gd` theo mẫu `tests/rogue.gd`: mỗi node một kiểm tra. Hàm cần biết trong `src/game.gd`:
  `uses_souls`, `add_soul`, `soul_cap`, `add_ghost`, `sacrifice`, `curse`, `soul_kill`, `update_ghosts`, `chain_ids`, `ghosts`.
- Chỗ đáng nghi nhất: Xiềng Hồn chia sát thương (cờ `sharing`), Hồn Lửa (phép không hồi chiêu), Lừa Tử Thần, Đêm Rạn Nhỏ (trần 12 dư ảnh).

Mỗi mastery mới kéo theo một cây giao thoa với mỗi mastery đã có.

## Cập nhật 2026-11-12 (Hộ Vệ, chưa có test)

Xong phần code: Hộ Vệ 19 node (nhịp riêng **Khiên**: `p.shield`, đỡ sát thương trước máu, tự mất 5 mỗi giây sau 4 giây không
bị đánh) và bốn cây giao thoa Trấn Thủ (m 11, với Chiến Binh), Lũy Sấm (m 12, Nguyên Tố Sư), Dạ Vệ (m 13, Sát Thủ),
Mộ Vệ (m 14, Thuật Sĩ Linh Hồn). Hộ Vệ chọn được ở màn tạo nhân vật (m 10). Chỉ mới kiểm tra khởi động
(`gen/boot.gd`: học hết node với từng mastery thứ hai, dùng mỗi kỹ năng một lần, nhận đòn) không báo lỗi.

Khác với `docs/CLASSES.md` vì game chỉ có một người chơi và dư ảnh không bị đánh:
- Chia Khiên: 10% Khiên nhận được hồi thành máu (thay vì trao cho đồng minh).
- Đứng Vững: còn Khiên thì đòn trúng không ngắt đòn đánh; bậc 2 không bị làm chậm (người chơi không bị đẩy lùi).
- Thế Thân: mỗi dư ảnh trong 100 giảm 8% sát thương nhận (tối đa 32%); không có ai thì Khiêu Khích cho gấp đôi Khiên.
- Hiệu Lệnh (Trấn Thủ): trong Vòng Che, Hét Trận không làm chịu thêm sát thương.
- Chân Thành (Trấn Thủ): còn Khiên thì mọi nhát chém hưởng Tay Nặng (vì Đứng Vững đã lo việc không bị ngắt).
- Khói Che Đội (Dạ Vệ) thành Khói Trong Vòng: Màn Khói trong Vòng Che kéo dài gấp đôi. Khiên Giả không có hình nhân, chỉ tàng hình.
- Áo Cho Bóng (Mộ Vệ): dư ảnh mới sống thêm 1 giây mỗi 10 Khiên.

Việc cho người viết test:
- `tests/skills.gd`: số node giờ là 175, kỹ năng chủ động 30, then chốt 26, tuyệt kỹ 5.
- `tests/menu.gd`: mảng đếm node cần 15 phần tử, thêm `19, 8, 8, 8, 8`; Hộ Vệ giờ chọn được (m 10).
- Viết `tests/guard.gd` theo mẫu `tests/rogue.gd`. Hàm trong `src/game.gd`: `uses_shield`, `shield_cap`, `add_shield`,
  `shield_take`, `update_shield`, `in_cover`, `guard_taken`, `watch_def`, `guard_cast`, `burn_wall`, `cage_at`, `topple_walls`.
  Biến `hitter` là kẻ đang ra đòn trong lúc `hurt()` chạy (đặt ở cú cắn và `strike`); đạn không có `hitter` nên không ăn gai.
- Chỗ đáng nghi nhất: Tường Chắn thêm `Rect2` vào `blocks` (kẻ đứng đúng chỗ tường mọc bị kẹt tới khi tường mất), sát thương
  phản lại (gai, Ăn Miếng Trả Miếng) không giết ngay mà để `update_foes` giết ở khung sau, Thế Thân giảm hồi máu bằng cách so
  máu trước và sau `step()`.



## Cập nhật 2026-11-12 (Thợ Săn, chưa có test)

Xong phần code: Thợ Săn 19 node (nhịp riêng **Tập Trung**: `p.focus_t`, `p.focused`; đòn hay kỹ năng kế tiếp mạnh hơn 40% trong
1 giây, `p.focus_until`), chó săn Vọng (`pets`, vẽ bằng sprite sói tô màu ngọc, 0,7 cỡ), bẫy (`traps`: kẹp, nổ, bẫy hồn),
trạng thái đứng ngắm `p.state == "aim"` của Phát Ngắm, dấu Trói (`f.root`) và Dấu Săn (`f.hunt`). Năm cây giao thoa:
Tiên Phong (m 16, Chiến Binh), Thiên Tiễn (m 17, Nguyên Tố Sư), Truy Ảnh (m 18, Sát Thủ), Hồn Lạp (m 19, Thuật Sĩ Linh Hồn),
Biên Vệ (m 20, Hộ Vệ). Chỉ mới kiểm tra khởi động với cả năm tổ hợp.

Khác với `docs/` vì quái chỉ nhắm người chơi: chó săn chỉ mất máu khi đứng cạnh một con quái đang ra đòn (`pets_struck`).
Thú Trận chỉ cho Nộ (thú vốn đã hưởng Hét Trận qua `dmg_mult`). Thú Giữ Cửa thành "Xua Thú lên kẻ bị Khiêu Khích giữ chân gấp đôi".
Khiên Cho Thú: thú hồi máu bằng 30% Khiên bạn nhận. Trói lên boss chỉ còn một nửa thời gian.

Việc cho người viết test:
- `tests/skills.gd`: số node giờ là 234, kỹ năng chủ động 36, then chốt 34, tuyệt kỹ 6.
- `tests/menu.gd`: mảng đếm node cần 21 phần tử, thêm `19, 8, 8, 8, 8, 8`; Thợ Săn chọn được (m 15).
- Viết `tests/hunter.gd`. Hàm trong `src/game.gd`: `uses_focus`, `use_focus`, `update_hunter`, `update_pets`, `pet_up`,
  `pet_bite`, `pet_pounce`, `pets_struck`, `pet_down`, `pet_tithe`, `root`, `hunter_cast`, `fire_arrow`, `arrow_hit`,
  `rain_tick`, `place_trap`, `update_traps`, `spring_trap`, `hunter_kill`. Cờ `ranged` bật trong lúc tên, phép bay và Mưa Tên trúng;
  `pet_hit` bật trong lúc chó cắn (Thú Gặt dựa vào nó).
- Chỗ đáng nghi nhất: Liên Hoàn gọi `spring_trap` đệ quy (bẫy bị xóa trước khi gọi nên không lặp), Cuộc Săn làm Tập Trung đầy
  liên tục, Săn Đêm hạ trần Điểm Hiểm xuống 3 khi không có Dấu Săn.



## Cập nhật 2026-11-12 (Tư Tế, chưa có test)

Xong phần code: Tư Tế 19 node (nhịp riêng **Thành Kính** `p.devo` 0-100: tăng khi phép hồi của Tư Tế hồi được máu và khi đứng
trong Đất Thiêng; dấu **Soi** `f.lit`: nhận thêm 5% sát thương; sát thương thánh qua cờ `holy_hit`; Trừ Tà đặt `f.purge`
làm tinh anh mất dấu 4 giây: không che chở, chết không nổ). Sáu cây giao thoa: Kiếm Nguyện (m 22, Chiến Binh), Nhật Quang
(m 23, Nguyên Tố Sư), Phán Quan (m 24, Sát Thủ), Chiêu Hồn (m 25, Thuật Sĩ Linh Hồn), Thánh Vệ (m 26, Hộ Vệ), Tuần Lâm (m 27,
Thợ Săn). Chỉ mới kiểm tra khởi động với cả sáu tổ hợp.

Khác với `docs/` vì chơi một mình: "đồng minh" là thú và dư ảnh; dư ảnh không có máu nên Tiếng Mõ chỉ hồi cho bạn và thú.
Lời Nguyện chỉ che cho bạn; Nguyện Chung (Thánh Vệ) thành Nguyện Có Khiên (+40 Khiên); Tên Lành hồi cho bạn 3% mỗi kẻ xuyên qua;
Hái Chia Phần (Chiêu Hồn) thành Hái Trên Đất Thiêng; Soi Chỗ Hiểm coi kẻ bị Soi luôn hở lưng (không ICD); Tử Vì Đạo: bạn nhận
ít hơn 15%. Chính Ngọ chỉ gấp đôi sát thương phép (không gấp đôi cỡ vùng).

Việc cho người viết test:
- `tests/skills.gd`: số node giờ là 295, kỹ năng chủ động 42, then chốt 43, tuyệt kỹ 7.
- `tests/menu.gd`: mảng đếm node cần 28 phần tử, thêm `19, 8, 8, 8, 8, 8, 8`; Tư Tế chọn được (m 21).
- Viết `tests/priest.gd`. Hàm trong `src/game.gd`: `uses_devo`, `add_devo`, `heal`, `apply_heal`, `heal_pets`, `in_holy`,
  `blessed`, `lit`, `holy_burst`, `priest_cast`, `update_priest`, `priest_kill`, `join_rings`. `heal()` là hồi máu của Tư Tế
  (qua Lời Thề, Cuồng Tín, Một Mạch); bình máu, hút máu, Lưỡi Hái cộng thẳng vào `p.hp`.
- Chỗ đáng nghi nhất: Một Mạch (`p.hots`), Dư Âm và Máu Thừa Thành Khiên (`apply_heal`), Lời Nguyện và Canh Ba trong `hurt()`
  (Lời Nguyện xét trước), Hiến Dâng (phước không vào bạn mà mạnh gấp rưỡi trên thú và dư ảnh).



## Cập nhật 2026-11-12 (Kỹ Sư Cổ Vật, chưa có test)

Xong phần code: Kỹ Sư Cổ Vật 19 node (nhịp riêng **Nhiệt** `p.heat`: kỹ năng Kỹ Sư mang khóa `"heat"` trong `skills.gd`, không tốn
Nộ mà cộng Nhiệt; trên 70 thiết bị mạnh hơn 20%; chạm 100 thì Quá Nhiệt `p.over`, không dùng được kỹ năng Kỹ Sư), thiết bị
(`devices`: trụ nỏ, trụ mõ, mìn chuông, cỗ máy chuông), vùng Chuông Câm (`fields` loại `"mute"`), ô kỹ năng thứ sáu của Nguyên Mẫu
(`proto`, phím 6, được lưu). Bảy cây giao thoa: Thiết Thủ (m 29), Lôi Công (m 30), Thợ Bóng (m 31), Khôi Lỗi Sư (m 32),
Pháo Lũy (m 33), Cơ Lạp (m 34), Thợ Chuông (m 35). Tám mastery giờ đều chọn được. Chỉ mới kiểm tra khởi động.

Khác với `docs/` vì quái chỉ nhắm người chơi và thiết bị không có máu: Trụ Sau Tường cho trụ bắn xa hơn thay vì không bị đánh;
Khiên Cho Máy thành "mỗi lần nhận Khiên, thiết bị sống thêm 1 giây"; Lặng Và Tối thành "đứng trong Chuông Câm như đứng trong khói";
Phá Hoại không làm thiết bị tàng hình; Mõ Vọng hồi cho bạn 5% mỗi trụ; Kéo Người Về nhắm vào thú; Bãi Mìn trừ máu khi bẫy hay mìn
nổ trong 40 quanh bạn. Chuông Câm hủy đòn đang lấy đà của quái trong vùng (kể cả boss).

Việc cho người viết test:
- `tests/skills.gd`: số node giờ là 376 (đếm lại từ `skills.gd`; các con số ở những mục cập nhật trước đã cũ), kỹ năng chủ động 48, nội tại 268, then chốt 52, tuyệt kỹ 8.
- `tests/menu.gd`: mảng đếm node cần 36 phần tử, thêm `19, 8, 8, 8, 8, 8, 8, 8`; cả tám mastery chọn được.
- Viết `tests/artificer.gd`. Hàm trong `src/game.gd`: `uses_heat`, `add_heat`, `hot`, `dev_mult`, `place_device`, `device_gone`,
  `mine_blast`, `turret_target`, `update_devices`, `dev_bolt_hit`, `artificer_cast`, `vent`, `hook_cast`, `in_mute`, `artificer_block`.
- Chỗ đáng nghi nhất: Rối Sắt (dư ảnh và thiết bị chung giới hạn 3, `ghost_cap` và `place_device`), Chạy Quá Tải (Nhiệt tới 150,
  mất máu nhưng không chết vì nó), Nguyên Mẫu (`proto`, `learn`, `pressed_skill`, `ui.skill_bar` vẽ ô thứ 7), Lò Phản Ứng
  (giá Nộ tính trước khi cộng Nhiệt).

Cả tám mastery và 28 cây giao thoa đã có trong game (376 node). Việc còn lại: test cho năm mastery viết sau
(Thuật Sĩ Linh Hồn, Hộ Vệ, Thợ Săn, Tư Tế, Kỹ Sư Cổ Vật), cân bằng bằng tay, và cập nhật `tests/skills.gd`, `tests/menu.gd`.

Đã cập nhật số đếm trong `tests/skills.gd` (376 node, 48 chủ động, 52 then chốt, 8 tuyệt kỹ) và `tests/menu.gd` (36 phần tử;
thẻ thứ ba giờ là Hộ Vệ và cả tám thẻ chọn được). Hai file này chưa được chạy lại sau khi sửa.

## Cập nhật 2026-11-12 (cung, theo `docs/CLASSES.md` mục 1.5)

Ba loại cung mới trong bảng vũ khí (Cung Tre, Cung Sừng, Cung Đồng; tầng 0 tới 2, icon `it_w8` tới `it_w10`), rơi như mọi
vũ khí khác. Cầm cung thì chuỗi đòn thường thành chuỗi 3 mũi tên cùng nhịp, mũi thứ ba xuyên (`fire_basic`, `shot_hit`,
`D.is_bow`: mọi tên cung bắt đầu bằng CUNG). Mũi tên vẫn tích Nộ, Điểm Hiểm, Độc của Tẩm Độc, dấu của Kiếm Bão; không đỡ
được đạn như nhát chém. Kỹ năng vẫn dùng hoạt ảnh của chúng (cầm cung vẫn Xoáy được). Đã thử: 3 mũi trúng con trước, mũi
thứ ba trúng cả con sau (`gen/bow.gd`, không phải test chính thức).

## Cập nhật 2026-11-12 (Độc Tấu, theo `docs/CLASSES.md` mục 1.4, chưa có test)

Tám cây Độc Tấu (m 36 tới 43, `Sk.SOLO` nối mỗi cây với mastery của nó), mỗi cây 8 node, tổng 64 node: tab thứ tư trong màn kỹ năng.
Luật trong `Sk.blocked`: cây Độc Tấu chỉ mở khi Mảnh Chuông đã thức và mastery thứ hai không có điểm nào; cần 3 điểm ở mastery
chính (then chốt 6). Một khi đã có điểm Độc Tấu hay bậc tinh thông, mastery thứ hai và cây giao thoa bị khóa (`SOLO_TAKEN`)
cho tới khi hoàn điểm. Bậc tinh thông (`Sk.max_rank`, `MASTER_RANKS = 3`): đi thuần thì mỗi kỹ năng chủ động của mastery chính
học thêm 3 bậc, mỗi bậc hồi chiêu nhanh hơn 6% (`skill_cd`). Tài liệu ghi "+6% hiệu lực"; hồi chiêu được chọn vì áp được cho mọi kỹ năng.
Đã kiểm tra khởi động cả tám cây (`gen/solo.gd`) và lại cả 31 tổ hợp hai mastery (`gen/boot.gd`).

Việc cho người viết test: `tests/skills.gd` giờ đòi 440 node, 48 chủ động, 60 then chốt, 8 tuyệt kỹ; `tests/menu.gd` mảng 44 phần tử.
Viết `tests/solo.gd`: hai chiều của luật khóa, bậc tinh thông làm `skill_cd` giảm, và mỗi node một kiểm tra.

## Cập nhật 2026-11-12 (hậu quả của lựa chọn chương hai)

Sau Phán Quyết (m11 xong), lựa chọn ở cổng Làng Thì Thầm hiện ra trên bản đồ (`World.fate`, gọi trong `enter_zone`):
niêm làng thì sân làng tắt đèn, lũ trẻ và bà Mận biến mất, đá niêm nằm yên giữa cổng, và Trấn Mõ Gỗ dán cáo thị của Hội Giữ Lặng;
giữ làng thì sân làng đông thêm trẻ con, đá niêm nằm úp, và người ba làng hạ lưu kéo xe dời lên trấn. Bà Cả Sậy, Ngải,
thầy Khâm, Giám Lặng, lão Rêu và bà Mận có thoại riêng cho mỗi nhánh (`D.AFTER_CHAT`). Đá niêm cũ bị thay, nên không chọn lại được.
Đã thử cả hai nhánh (`gen/fate.gd`, không phải test chính thức). Thay đổi hiện ra ở lần vào khu kế tiếp, không phải ngay lúc chọn.

## Cập nhật 2026-11-12 (chương 3: Hạm đội không nước, theo Hồi 3 của brief)

Hai khu mới (`world.gd`): **Biển Muối Ngân** (`salt`, đáy biển cạn phía nam Đầm Lau, trại của Phường, bãi xác tàu, vũng nước mặn;
đi từ con đê ở bờ nam Đầm Lau, mở khi nhận m12) và **Hạm Đội Mắc Cạn** (`fleet`, dungeon năm thân tàu nối bằng ván cầu; mở khi nhận m15).
Bảng màu muối `Art.THEMES.salt`. Ba quái mới mượn cách đánh của quái cũ qua khóa `"ai"` trong `D.FOES` (`game.ai(f)`):
Cua Muối (như Phu Phà), Hải Âu Tro (như Đỉa Bùn), Thợ Lặn Chìm (như Kẻ Gieo Bào Tử, ném muối trắng). Boss **Đô Đốc Sảnh Muối**
dùng bộ đòn của Người Gác Phà, gọi Thợ Lặn Chìm ở 66% và 33% máu, rơi Muối Áo Đô Đốc (đồ độc nhất: đòn chí mạng làm Lạnh).
Nhiệm vụ m12 tới m16 và s4, NPC chị Vành (Phường) và Lạc (người mua của Lò Đúc), cảnh đọc sổ hàng trong hầm hai (`manifest`).
Kết chương: Thầy Khâm bỏ đi cùng hòm tiếng để bán cho Ô Kha (không còn ở trấn); Ngải vừa lên dây mảnh vừa bán đồ.
Kiểm tra nhanh: `gen/ch3.gd`.

## Cập nhật 2026-11-12 (chương 4: Phép tính của Người Đúc Chuông, theo Hồi 4 của brief)

Hai khu mới: **Dãy Mỏ Câm** (`mines`, núi tuyết phía đông Biển Muối, đi theo đường ván mới; làng thợ của bác Than, ba cửa hầm,
các đống xỉ, hai trại Hội Giữ Lặng và Dòng Vọng Thân trước cổng lò; mở khi nhận m17) và **Lò Tái Thanh** (`foundry`, dungeon:
nhà cổng nơi Ô Kha tiếp khách, xưởng đúc, giá làm nguội, hành lang ống bễ, hố đúc; mở khi nhận m20). Bảng màu `snow` và `forge`.
Ba quái mới mượn cách đánh qua `"ai"`: Người Xỉ (lao thẳng như Hươu Rỗng), Thợ Rèn Vọng (như Sói Ký Ức), Bướm Đồng (như Ma Đèn Lồng:
hồi máu cho quái khác, nên hạ trước). Hai boss chung một hố: **Tổng Thợ Cả Bạch Lô** (bộ đòn Người Thu Phí, gọi Thợ Rèn Vọng,
rơi Búa Bạch Lô: đòn cuối chuỗi để lại Cháy) và **Khuôn Sống** (bộ đòn Mẹ Rễ, đứng yên, rễ đồng và vũng đồng nóng chảy).
Boss gọi quân và màu vũng giờ lấy từ dữ liệu (`summon`, `call_text`, `heal_text`, `cloud` trong `D.FOES`).
Nhiệm vụ m17 tới m21 và s5 (than ấm cho lò sưởi của làng; xong thì lò sưởi sáng lại). Cảnh `standoff` và `ledger`.
Tố Diên rời trấn lên núi khi nhận m17. Kết chương: lò sập một nửa, Tố Diên bị tước chức, tiếng Vãn thêm ba chữ "ĐỪNG ĐI TÌM".

Sửa lỗi chương 3: cảnh báo đòn của quái mới không hiện (phần vẽ cảnh báo rẽ nhánh theo loại quái thay vì `ai`).
Kiểm tra nhanh: `gen/ch4.gd`.

## Cập nhật 2026-11-12 (chương 5: Tiếng đầu tiên, theo Hồi 5 của brief)

Ba khu mới: **Kinh Thành Kim Thượng** (`capital`, lên từ đèo phía bắc Dãy Mỏ Câm, mở khi nhận m22; Miệng Chuông là cái hố giữa
kinh, năm trại phe phái quanh vành hố), **Điện Chép Sử** (`archive`, dungeon; Bà Giữ Sử ở phòng đọc, Thầy Khâm ở phòng cuối)
và **Tầng Lưỡi Chuông** (`maw`, đấu trường cuối). Bảng màu `gold`. Quái mới: Thư Lại Chép (vẩy mực như Cò Tro), Cấm Vệ Kim
(như Phu Phà), Lư Hương Sống (khói làm chậm như Kẻ Thả Lưới). Boss: **Ô Kha, Người Đúc Chuông** (bộ đòn Người Gác Phà, gọi Thư Lại),
khi ông ngã thì **Tiếng Đầu Tiên** trồi lên (bộ đòn Mẹ Rễ; spawn có khóa mới `req`: chỉ xuất hiện khi cờ đó đã có).
Nhiệm vụ m22 tới m26. Hai lựa chọn: cách đối xử với Thầy Khâm (`kham_choice`, cờ `kham`, chỉ đổi lời) và lựa chọn cuối thả hay
giữ tiếng Vãn (`voice`, cờ `van`; m26 tự mở sau m25). Trả m26 cho Ngải thì hiện lời kết toàn màn (`D.EPILOGUE`) theo lựa chọn.
Kiểm tra nhanh: `gen/ch5.gd`. Chưa làm: lời của Ngải ở vành hố tùy mức gắn bó, endgame Triều Vọng.

## Cập nhật 2026-11-12 (chuỗi phụ Sổ Nợ Của Người Chết, theo brief mục 3.8)

Năm nhiệm vụ phụ s6 tới s10 do Bà Cả Sậy giao, mở dần theo chương (sau m2, m5, m7, m13, m15). Mỗi con nợ là một Dư Ảnh vẫn
đang cố trả: thợ gốm ở Đầm Lau, người mẹ đếm tiền ở chợ chìm Bến Phà, người lái đò ở Rừng Thở, thợ lặn ở Biển Muối,
và dòng cuối trong sổ trên bàn ở trấn (con nợ là Bà Cả Sậy, chủ nợ là Vãn). Mỗi bước chọn xóa nợ (nhiều kinh nghiệm hơn)
hay thu nợ (vàng); cờ `debt1` tới `debt5`. Dư Ảnh đặt bằng `World.debts`, gọi trong `World.build` cho mọi khu.
Kiểm tra nhanh: `gen/debts.gd`.

## Cập nhật 2026-11-12 (bí mật Ngọn Hải Đăng Đếm Ngược, theo brief mục 3.8)

Không NPC nào giao. Ngọn hải đăng ở bờ khô phía đông nam Biển Muối chớp một con số giảm một mỗi ngày thật
(`21000 - số ngày Unix`). Xem nó ở hai ngày khác nhau (`flags.lh_days`, lưu dạng chuỗi) thì người gác đèn hiện ra trên tháp:
nói thật (đèn tắt) hoặc thắp đèn theo nhịp ông chờ (đèn vẫn chớp); cờ `lamp`, thưởng kinh nghiệm qua khóa `xp` của THINGS.
Sprite tháp đèn còn đang sinh; trước khi có, chỉ có điểm xem. Kiểm tra nhanh: `gen/lh.gd`.

## Cập nhật 2026-11-12 (chuỗi Tám Chiếc Mõ Câm, theo brief mục 3.8)

Không NPC nào giao. Tám chiếc mõ gỗ ở tám khu (trấn, Đầm Lau, Bến Phà Cũ, Rừng Thở, Biển Muối, Hạm Đội, Dãy Mỏ Câm, Kinh Thành),
`World.mutes`. Chỉ chiếc kế tiếp trong chuỗi mới "nói" (`flags.mutes`); mỗi chiếc giữ lời cuối của một người thuộc một
Âm Gốc (ứng với tám mastery) và câu đố chỉ tới chiếc sau (`D.MUTES`). Chiếc thứ tám rơi Mõ Tám Tiếng (bùa độc nhất:
dùng tuyệt kỹ hồi 8% máu và 8 Nộ). Kiểm tra nhanh: `gen/mutes.gd`.

Ảnh: `tools/gen.sh` giờ thử lần lượt nhiều key (`DV_KEYS`) rồi nhiều model, mặc định Gemini 3.1 image trước (chủ dự án chọn);
`tools/pix.gd` đọc cả PNG lẫn JPEG.

## Cập nhật 2026-11-12 (endgame Triều Vọng, theo brief mục 3.11)

Sau m26, năm dungeon (Bến Phà Cũ, Lòng Cây, Hạm Đội, Lò Tái Thanh, Điện Chép Sử) có mức Triều Vọng 1 tới 5 đổi theo ngày thật
(chu kỳ 8 ngày, `tide_level`): quái mạnh thêm 15% mỗi mức, quái thường có `8% x mức` cơ hội thành tinh anh, đồ rơi nhiều hơn.
Ngải đứng ở vành Miệng Chuông báo mức triều mỗi ngày (`D.TIDE_TALK`). Kiểm tra nhanh: `gen/tide.gd`.
