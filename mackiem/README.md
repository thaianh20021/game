# Mặc Kiếm Lục

Roguelike kiếm hiệp góc nhìn từ trên xuống, tranh thủy mặc. Unity 2021.3.31f1 (Built-in pipeline, 2D chính giao).
Không liên quan tới `duvang/` hay `rebirth/` ở thư mục cha.

## Chơi

- Bản Windows: `Build/MacKiemLuc.exe` (tạo bằng lệnh build bên dưới).
- Trong Unity Editor: mở thư mục này, mở `Assets/Main.unity` (scene rỗng), bấm Play. Game tự dựng mọi thứ lúc chạy.

| Phím | Việc |
| --- | --- |
| WASD | di chuyển |
| Chuột trái (giữ) / J | đánh liên hoàn (cung: giữ để giương, thả để bắn) |
| Chuột phải / I | phóng phi kiếm; hết kiếm thì bấm lần nữa để thu |
| R / chuột giữa / O | thu phi kiếm về (chém mọi thứ trên đường bay) |
| Shift / K | đỡ đòn; bấm sát lúc đòn chạm là ĐỠ CHUẨN |
| Space | khinh công (né xuyên đòn) |
| Q / L | tuyệt chiêu của binh khí (50 nội lực) |
| F | TUYỆT KỸ đang dùng (hồi chiêu) |
| E | nhận thưởng, mua, trò chuyện |
| Esc | tạm dừng |

Tay cầm (kiểu Xbox, chưa thử trên máy thật): cần trái đi, X đánh, A khinh công, LB đỡ, RB phi kiếm, Y tuyệt chiêu, B dùng.

## Thiết kế

- **Đỡ và THẾ**: mọi địch có thanh THẾ. Đòn đánh và nhất là đỡ chuẩn làm đầy thanh; đầy là PHÁ THẾ (choáng, nhận +60% sát thương). Vùng đỏ tròn không đỡ được, phải né.
- **Ngũ hành**: bí kíp gắn một hành vào bốn ô (đòn đánh, khinh công, đỡ đòn, tuyệt chiêu). Trúng địch để lại ẤN; đánh tiếp bằng hành khác thì
  TƯƠNG SINH (Kim-Thủy, Thủy-Mộc, Mộc-Hỏa, Hỏa-Thổ, Thổ-Kim: nổ lan, hồi nội lực) hoặc TƯƠNG KHẮC (các cặp còn lại: sập THẾ).
- **Thế giới liền mạch**: cả chuyến đi là một bản đồ đi từ dưới lên, không chuyển phòng (`GameStage.BuildWorld`, chỉ phụ thuộc `seed`).
  Mỗi chương: 4 bãi chiến (bước vào là bị phong ấn hai đầu, 2 đến 4 đợt phục kích), 1 trạm dừng (thương nhân và trà quán), rồi đấu trường trùm là bức tranh của chương đặt thẳng vào bản đồ.
  Dọn xong một bãi thì hai phần thưởng hiện ở đầu trên: nhận một cái là phong ấn mở.
- **Phi kiếm**: 4 thanh (kiếm: 6). Phóng ra cắm vào địch hoặc đất, thu về chém dọc đường. Lúc đi mang hành của ĐÒN ĐÁNH, lúc về mang hành của TUYỆT CHIÊU, nên một lần phóng-thu tự gây phản ứng.
- **Đông và nhanh**: nhiều địch yếu thay vì ít địch trâu; tối đa 4 + số chương kẻ cùng lấy đà một lúc để đám đông vẫn đọc được.
- **6 binh khí, mỗi cái một cơ chế** (`WeaponDef.mech`): kiếm (thêm phi kiếm), thương (mũi thương +60%), quạt (ám khí nảy), song đao (cuồng đao tăng tốc), chùy (bất động, phá thế), cung (giương rồi thả).
- **4 môn phái** (`D.SECTS`, chọn sau binh khí): Vân Kiếm Tông, Thiết Y Môn, Huyết Nguyệt Đường, Ngũ Hành Cốc; mỗi phái đổi cách chơi.
- **Tinh anh có thuộc tính** (`Foe.afx`): BẠO LIỆT nổ khi chết, THẦN TỐC, THIẾT GIÁP (phải phá thế). **LIÊN TRẢM**: chuỗi hạ địch, mỗi mốc 10 hồi máu và nội lực.
- **4 tuyệt kỹ có cây nâng cấp** (`D.SKILLS`, `GameSkill.cs`, mục TUYỆT KỸ ở màn hình chính): Thiên Kiếm Vũ, Phá Vân Chỉ, Kim Chung Tráo, Tàn Ảnh Trảm; mỗi chiêu 3 tầng mua vĩnh viễn bằng NGỘ TÍNH.
- **Tu luyện**: NGỘ TÍNH kiếm được mỗi chuyến mua nâng cấp vĩnh viễn. Hạ trùm mở dần 5 binh khí còn lại. Thắng thì KIẾP NẠN tăng.

## Tệp

- `Assets/Scripts/Data.cs`: toàn bộ số liệu (binh khí, địch, trùm, bí kíp, tu luyện).
- `Assets/Scripts/Game.cs`: khởi động, điều khiển, người chơi, chuyến đi.
- `Assets/Scripts/GameStage.cs`: dựng thế giới, tường (`Confine`), bãi chiến và phần thưởng, phi kiếm.
- `Assets/Scripts/GameSkill.cs`: tuyệt kỹ, cây nâng cấp, cung và cuồng đao.
- `Assets/Scripts/GameFoes.cs`: địch, trùm, phản ứng ngũ hành, đạn, bot tự chơi.
- `Assets/Scripts/GameDraw.cs`: sprite, nét mực, HUD và menu (IMGUI).
- `Assets/Scripts/Ink.cs`: lưới vẽ tức thời (vùng báo đòn, vệt kiếm, giọt mực). `Sfx.cs`: âm thanh và nhạc tổng hợp lúc khởi động.
- `Assets/Editor/Builder.cs`: thiết lập project, build, và quy tắc nhập ảnh trong `Resources/Art`.
- `Assets/Resources/Art/`: sprite đã cắt. `gen/raw_*.png`: tranh gốc do model ảnh vẽ.
- `tools/art.sh`, `tools/gen.sh`: gọi model ảnh (khóa lấy từ biến môi trường `MK_KEYS`, không lưu vào tệp). `tools/cut.py`: cắt tranh nền hồng hoặc nền trắng thành sprite.
- `tools/anim.sh`: tấm khung hình chuyển động (nhân vật chính: chạy 8 khung, chém 6 khung, thủ/trúng đòn/lướt/xoay; mỗi địch: 4 khung đi, lấy đà, ra đòn).
  `tools/animfix.sh` vẽ lại những tấm thiếu hoặc bị nền tối; `tools/cutfoes.sh` cắt tất cả tấm của địch.

## Hoạt ảnh

- Tên tệp quyết định tất cả. Nhân vật chính có 36 khung do `tools/hero2.sh` vẽ: `hero_run_0..7`, `hero_idle_0..3` (thở), `hero_atk_0..11` (ba nhát, mỗi nhát lấy đà/chém/dứt đòn/thu thế), `hero_act_0..11` (thủ, chịu đòn, trúng đòn, quỵ, nhún, lướt, phanh, phóng kiếm, gọi kiếm, bắt kiếm, vận công, xuất chiêu);
  địch: `<id>_walk_0..3`, `<id>_wind`, `<id>_hit`. Thiếu bộ khung thì game tự dùng hình đơn cũ (`<id>.png`) và lắc lư bằng code.
- Khung hình cắt ở kích thước gấp đôi (200 px một đơn vị) nên vẽ đúng cỡ gốc, không co giãn theo từng khung.
- `Game.HeroPose()` chọn khung cho nhân vật chính; đoạn vẽ địch trong `GameDraw.Render` chọn khung cho địch. Bóng mờ khi lướt là `AddGhost`.
- Gemini vẽ đúng nền hồng; các model GPT image chỉ chịu nền trắng (và đôi lúc vẫn ra nền tối, khi đó phải vẽ lại).

## Khung chuyển tiếp và phản ứng

- Nhân vật (kiếm): `hero_trans_0..11` từ `tools/more.sh hero`: bắt đầu chạy, phanh, quay người, thu kiếm sau nhát chém, đáp sau khi lướt, gượng dậy sau đòn. Chọn trong `GameDraw.TrackTransitions` / `HeroPose`.
- Mọi địch và trùm: `<id>_react_0..3` (trúng đòn, choáng khi PHÁ THẾ, đang ngã, nằm). Xác nằm lại khoảng một giây rồi mờ dần. Cắt bằng `tools/cutmore.sh`.

## Nhân vật ghép xương

Với kiếm, nhân vật chính là con rối ghép từ bộ phận (`GameRig.cs`): đầu, thân, vạt áo, hai cánh tay hai đoạn, hai chân hai đoạn và thanh kiếm,
mỗi bộ phận xoay quanh khớp, tư thế được nội suy mượt giữa các trạng thái (đứng thở, chạy, ba nhát chém, ném kiếm, gọi và bắt kiếm, thủ, trúng đòn, lướt, vận công).
Khăn đỏ là dải vải mô phỏng vật lý; vạt áo đung đưa có độ trễ.
- `tools/parts.sh` vẽ tấm bộ phận (model vẽ lỗ chốt ở mỗi khớp), `tools/parts.py` cắt từng mảnh, lấy lỗ chốt làm điểm xoay, ghi `Assets/Resources/rig.json`.
- Tư thế là bảng góc trong `GameRig.RigTarget` / `SLASH` (độ, ngược chiều kim đồng hồ; tay buông thõng là 0, +90 là chỉ thẳng về trước).
- Mặc định là KHUNG VẼ: chủ game thấy bản ghép xương bị rời rạc (2026-11-17). ESC → `HÌNH NHÂN VẬT` bật GHÉP XƯƠNG để thử; có cho cả 6 vũ khí (`tools/parts.sh weapons`, `rigw.json`).
- Hoạt ảnh ném riêng (`hero_throw_0..11`, `tools/parts.sh throw`): lấy đà, vung, buông, dứt đòn; gọi kiếm và bắt kiếm; dùng ở chế độ khung vẽ.

## Unity MCP

Mở project trong Unity Editor là `Assets/Editor/McpBoot.cs` tự bật cầu nối MCP (stdio). Server nằm ở `C:/Users/ADMIN/.mcp-unity`, cấu hình ở `.mcp.json` gốc repo.
Qua MCP có thể vào Play, chạy mã trong Editor, đọc Console và build (`manage_build`).

## Build và thử

```bash
"D:/Unity/Editor/2021.3.31f1/Editor/Unity.exe" -batchmode -quit -projectPath . -executeMethod Builder.Build -logFile gen/build.log
```

Bot tự chơi hết một chuyến và chụp ảnh vào `shots/run` (`-cheat` để không chết, `-speed 3` chạy nhanh gấp ba):

```bash
./Build/MacKiemLuc.exe -screen-width 1280 -screen-height 720 -screen-fullscreen 0 -bot -cheat -speed 3 -shots "E:/AI/game/mackiem/shots/run" -end 260 -logFile gen/run.log
```

Dòng `BOT END ...` trong `gen/run.log` cho biết bot dừng ở đâu.

## Chưa làm

Cân bằng chưa qua tay người chơi thật (độ khó vừa được đẩy lên mạnh, chưa ai thử); bot chỉ thử kiếm, chưa thử 5 binh khí kia, 3 tuyệt kỹ sau và màn hình TUYỆT KỸ; mọi binh khí dùng chung bộ khung cầm kiếm; mọi địch và trùm đã có khung đi/lấy đà/ra đòn, NPC và đạo cụ vẫn là hình tĩnh; chưa có điều khiển cảm ứng; chữ chỉ có tiếng Việt.
