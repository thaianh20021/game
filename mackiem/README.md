# Mặc Kiếm Lục

Roguelike kiếm hiệp góc nhìn từ trên xuống, tranh thủy mặc. Unity 2021.3.31f1 (Built-in pipeline, 2D chính giao).
Không liên quan tới `duvang/` hay `rebirth/` ở thư mục cha.

## Chơi

- Bản Windows: `Build/MacKiemLuc.exe` (tạo bằng lệnh build bên dưới).
- Trong Unity Editor: mở thư mục này, mở `Assets/Main.unity` (scene rỗng), bấm Play. Game tự dựng mọi thứ lúc chạy.

| Phím | Việc |
| --- | --- |
| WASD | di chuyển |
| Chuột trái (giữ) / J | đánh liên hoàn |
| Chuột phải / Shift / K | đỡ đòn; bấm sát lúc đòn chạm là ĐỠ CHUẨN |
| Space | khinh công (né xuyên đòn) |
| Q / L | tuyệt chiêu (50 nội lực) |
| E / F | vào cửa, mua, trò chuyện |
| Esc | tạm dừng |

Tay cầm (kiểu Xbox, chưa thử trên máy thật): cần trái đi, X đánh, A khinh công, LB/RB đỡ, Y tuyệt chiêu, B dùng.

## Thiết kế

- **Đỡ và THẾ**: mọi địch có thanh THẾ. Đòn đánh và nhất là đỡ chuẩn làm đầy thanh; đầy là PHÁ THẾ (choáng, nhận +60% sát thương). Vùng đỏ tròn không đỡ được, phải né.
- **Ngũ hành**: bí kíp gắn một hành vào bốn ô (đòn đánh, khinh công, đỡ đòn, tuyệt chiêu). Trúng địch để lại ẤN; đánh tiếp bằng hành khác thì
  TƯƠNG SINH (Kim-Thủy, Thủy-Mộc, Mộc-Hỏa, Hỏa-Thổ, Thổ-Kim: nổ lan, hồi nội lực) hoặc TƯƠNG KHẮC (các cặp còn lại: sập THẾ).
- **Chuyến đi**: 3 chương (Trúc Lâm, Cổ Tự, Tuyết Đỉnh), mỗi chương 4 ải chọn cửa theo phần thưởng, 1 trạm dừng (thương nhân hoặc trà quán), 1 trùm.
- **Tu luyện**: NGỘ TÍNH kiếm được mỗi chuyến mua nâng cấp vĩnh viễn. Hạ trùm chương I và II mở thương và quạt. Thắng thì KIẾP NẠN tăng.

## Tệp

- `Assets/Scripts/Data.cs`: toàn bộ số liệu (binh khí, địch, trùm, bí kíp, tu luyện).
- `Assets/Scripts/Game.cs`: khởi động, điều khiển, người chơi, ải và chuyến đi.
- `Assets/Scripts/GameFoes.cs`: địch, trùm, phản ứng ngũ hành, đạn, bot tự chơi.
- `Assets/Scripts/GameDraw.cs`: sprite, nét mực, HUD và menu (IMGUI).
- `Assets/Scripts/Ink.cs`: lưới vẽ tức thời (vùng báo đòn, vệt kiếm, giọt mực). `Sfx.cs`: âm thanh và nhạc tổng hợp lúc khởi động.
- `Assets/Editor/Builder.cs`: thiết lập project, build, và quy tắc nhập ảnh trong `Resources/Art`.
- `Assets/Resources/Art/`: sprite đã cắt. `gen/raw_*.png`: tranh gốc do model ảnh vẽ.
- `tools/art.sh`, `tools/gen.sh`: gọi model ảnh (khóa lấy từ biến môi trường `MK_KEYS`, không lưu vào tệp). `tools/cut.py`: cắt tranh nền hồng hoặc nền trắng thành sprite.
- `tools/anim.sh`: tấm khung hình chuyển động (nhân vật chính: chạy 8 khung, chém 6 khung, thủ/trúng đòn/lướt/xoay; mỗi địch: 4 khung đi, lấy đà, ra đòn).
  `tools/animfix.sh` vẽ lại những tấm thiếu hoặc bị nền tối; `tools/cutfoes.sh` cắt tất cả tấm của địch.

## Hoạt ảnh

- Tên tệp quyết định tất cả: `hero_run_0..7`, `hero_atk_0..5`, `hero_idle_0`, `hero_guard`, `hero_hurt`, `hero_dashb`, `hero_spin`;
  địch: `<id>_walk_0..3`, `<id>_wind`, `<id>_hit`. Thiếu bộ khung thì game tự dùng hình đơn cũ (`<id>.png`) và lắc lư bằng code.
- Khung hình cắt ở kích thước gấp đôi (200 px một đơn vị) nên vẽ đúng cỡ gốc, không co giãn theo từng khung.
- `Game.HeroPose()` chọn khung cho nhân vật chính; đoạn vẽ địch trong `GameDraw.Render` chọn khung cho địch. Bóng mờ khi lướt là `AddGhost`.
- Gemini vẽ đúng nền hồng; các model GPT image chỉ chịu nền trắng (và đôi lúc vẫn ra nền tối, khi đó phải vẽ lại).

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

Cân bằng chưa qua tay người chơi thật; thương và quạt dùng chung bộ khung cầm kiếm; NPC và đạo cụ vẫn là hình tĩnh; chưa có điều khiển cảm ứng; chữ chỉ có tiếng Việt.
