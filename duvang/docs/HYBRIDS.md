# Dư Vang: 28 class kết hợp (Hợp Âm)

Đọc [CLASSES.md](CLASSES.md) trước: tài liệu này dùng tên kỹ năng, nhịp riêng và luật chống vòng lặp ở đó.
Phần này gồm bảng tổng và 13 cặp có Chiến Binh hoặc Hộ Vệ. 15 cặp còn lại ở [HYBRIDS_2.md](HYBRIDS_2.md).

## Luật chung của cây giao thoa [CHỐT]

- Hai mastery đối xứng: chọn cái nào trước cũng ra cùng một class.
- Mỗi cặp có **8 node, mỗi node 1 bậc**: 7 node giao thoa và 1 then chốt.
- Node giao thoa cần 3 điểm ở mỗi mastery; then chốt cần 6 ở mỗi bên.
- Mỗi node phải có kỹ năng của cả hai bên trong mô tả. Không có node "+10% sát thương".
- **Dòng đầu của mỗi bảng luôn là node tài nguyên**: nó nối nhịp riêng của hai mastery.
- Node chỉ hoạt động khi bạn đã học kỹ năng nó nhắc tới.
- Sát thương sinh ra từ node giao thoa là sát thương phụ: không tích Lực, không tích nhịp riêng, không kích node khác.
- "ICD" là thời gian chờ nội bộ. Không ghi thì là 1 giây.
- Mọi con số là [GIẢ ĐỊNH].

## Bảng 28 Hợp Âm

Mã: CB Chiến Binh, HV Hộ Vệ, ST Sát Thủ, TS Thợ Săn, NT Nguyên Tố Sư, TL Thuật Sĩ Linh Hồn, TT Tư Tế, KS Kỹ Sư Cổ Vật.

| # | Cặp | Tên | Hình dung | Vai trò | Cơ chế lõi | Điểm yếu |
|---|---|---|---|---|---|---|
| 1 | CB+HV | Trấn Thủ | Người giữ cổng: Khiên dày, đòn nặng | Chống chịu tuyến đầu | Khiên đang có biến thành sát thương của Xô Khiên và Đập Khiên | Chậm, không có đòn tầm xa |
| 2 | CB+ST | Lưỡi Bóng | Đấu sĩ hai tay, đỡ để mở kết liễu | Cận chiến cơ động | Đòn cuối chuỗi và đỡ đòn sinh Điểm Hiểm | Mỏng hơn Chiến Binh, cần đỡ đúng lúc |
| 3 | CB+TS | Tiên Phong | Thợ săn lao vào trước con thú | Cận chiến có thú | Giữ chuỗi chém cũng tích Tập Trung | Bẫy cần chuẩn bị, yếu khi bị dồn |
| 4 | CB+NT | Kiếm Bão | Lưỡi kiếm mang dấu phép | Cận chiến combo dấu | Phép đặt dấu, chuỗi chém khai thác dấu | Nhiều nút, đói Lực |
| 5 | CB+TL | Kiếm Tang | Kẻ chém để gặt Hồn | Cận chiến có quân | Đòn cuối chuỗi cho Hồn, Hồn trả thay Lực | Khởi đầu chậm, yếu với boss không có quái phụ |
| 6 | CB+TT | Kiếm Nguyện | Chiến binh giữ lời thề | Cận chiến tự hồi | Đòn cuối chuỗi tích Thành Kính | Sát thương dồn kém |
| 7 | CB+KS | Thiết Thủ | Giáp hơi nước, búa và trụ nỏ | Cận chiến kiểm soát vùng | Chém để xả Nhiệt | Quá Nhiệt giữa trận là chết |
| 8 | HV+ST | Dạ Vệ | Vệ sĩ đêm: Khiên vỡ là biến mất | Chống chịu lừa đòn | Né sát nút cho Khiên, Khiên vỡ cho Điểm Hiểm | Khiên thấp, phải chủ động |
| 9 | HV+TS | Biên Vệ | Lính gác chốt sau bức tường | Đánh xa cố thủ | Đứng yên sau Tường Chắn tích Tập Trung | Cơ động kém nhất |
| 10 | HV+NT | Lũy Sấm | Pháp sư đứng giữa tâm bão | Pháp sư chống chịu | Cộng Hưởng cho Khiên; Khiên trả dấu | Phép có ngắm yếu đi |
| 11 | HV+TL | Mộ Vệ | Người gác mộ và những kẻ nằm dưới | Chống chịu có quân | Hồn thành Khiên, dư ảnh chết thay | Sát thương thấp |
| 12 | HV+TT | Thánh Vệ | Người che cho cả đội | Hỗ trợ chống chịu | Khiên hấp thụ tích Thành Kính | Solo chậm |
| 13 | HV+KS | Pháo Lũy | Thợ dựng lô cốt | Kiểm soát vùng cố định | Khiên hấp thụ xả Nhiệt | Phải chọn chỗ đứng trước |
| 14 | ST+TS | Truy Ảnh | Kẻ săn người | Ám sát mục tiêu đơn | Tập Trung đổi thành Điểm Hiểm | Yếu trước đám đông |
| 15 | ST+NT | Dạ Lôi | Lưỡi dao tẩm ba hệ | Dồn sát thương theo dấu | Đặt dấu mới cho Điểm Hiểm | Giấy mỏng nhất trong 28 |
| 16 | ST+TL | Gặt Hồn | Đao phủ nhặt Hồn | Ám sát có quân | Kết liễu đổi Điểm Hiểm lấy Hồn | Cần mạng hạ gục liên tục |
| 17 | ST+TT | Phán Quan | Kẻ thi hành án | Ám sát tự hồi | Kết liễu tích Thành Kính | Hồi máu nhỏ giọt, không cứu được đồng đội nhanh |
| 18 | ST+KS | Thợ Bóng | Kẻ phá hoại giăng máy trong tối | Phục kích | Kết liễu xả Nhiệt | Thiết bị tồn tại ngắn |
| 19 | TS+NT | Thiên Tiễn | Mũi tên mang phép | Đánh xa combo dấu | Phát Ngắm hưởng Cộng Hưởng | Đứng yên nhiều |
| 20 | TS+TL | Hồn Lạp | Chủ của bầy sói ma | Triệu hồi cơ động | Thú giết và thú gục đều cho Hồn | Quân chết nhanh |
| 21 | TS+TT | Tuần Lâm | Người giữ rừng và con thần thú | Hỗ trợ đi solo tốt | Thú đánh trúng tích Thành Kính | Mất thú là mất nửa sức |
| 22 | TS+KS | Cơ Lạp | Thợ bẫy với bãi mìn | Kiểm soát vùng | Bẫy sập xả Nhiệt | Bãi mìn hại cả mình |
| 23 | NT+TL | Tro Hồn | Phù thủy đốt Hồn làm phép | Pháp sư dồn phép | Kẻ chết mang dấu cho thêm Hồn | Không quân hoặc không hồi chiêu, phải chọn |
| 24 | NT+TT | Nhật Quang | Người mang lửa thiêng | Pháp sư hỗ trợ | Dấu trên kẻ bị Soi tích Thành Kính | Thành Kính khó tích khi solo |
| 25 | NT+KS | Lôi Công | Thợ máy nạp sét | Pháp sư không tốn Lực | Ba hệ đẩy Nhiệt theo ba hướng | Vận hành khó nhất |
| 26 | TL+TT | Chiêu Hồn | Người đưa tang | Triệu hồi hỗ trợ | Hồi máu cho dư ảnh tích Thành Kính | Sát thương trực tiếp thấp |
| 27 | TL+KS | Khôi Lỗi Sư | Thợ rối nhét Hồn vào máy | Triệu hồi bền | Nhiệt trả thay Hồn | Trần quân thấp |
| 28 | TT+KS | Thợ Chuông | Người dựng mõ máy | Hỗ trợ đặt trạm | Hồi máu xả Nhiệt | Gần như không có sát thương riêng |

---

## 1. Trấn Thủ (CB + HV)

Hai hướng build: **Tường Sống** (Bất Khuất + Pháo Đài, đứng yên chịu đòn) và **Búa Khiên** (Đập Khiên, Xô Khiên, Phán Quyết: tích Khiên rồi tiêu hết thành sát thương).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Khiên Nộ | Khiên + Lực | Cứ 10 Khiên bị đánh mất cho 4 Lực |
| Đỡ Dày | Thủ Thế + Khiên | Đỡ được đòn bằng Thủ Thế cho +25 Khiên |
| Đà Khiên | Xô Khiên + Khiên | Xô Khiên gây thêm 1% cho mỗi điểm Khiên đang có, tối đa +100% |
| Kéo Vào | Xoáy + Khiêu Khích | Xoáy trúng kẻ đang bị Khiêu Khích kéo nó sát bạn và choáng 0,5s |
| Xô Tường | Dập Đất + Tường Chắn | Dập Đất cạnh Tường Chắn làm tường đổ về phía trước: 200% theo vệt, tường mất |
| Hiệu Lệnh | Hét Trận + Vòng Che | Hét Trận khi đứng trong Vòng Che trao phần +30% sát thương cho đồng minh trong vòng (không trao phần chịu thêm) |
| Nhịp Khiên | Chuỗi chém + Đập Khiên | Đập Khiên tính là đòn cuối chuỗi (hưởng Tay Nặng) và không ngắt chuỗi |
| **Then chốt: Chân Thành** | | Khi còn Khiên, chuỗi chém không bị đòn trúng làm ngắt. Giá: khi hết Khiên bạn chịu thêm 15% |

## 2. Lưỡi Bóng (CB + ST)

Hai hướng build: **Đấu Sĩ** (Thủ Thế rồi Rạch, đứng đối mặt) và **Song Thủ** (bỏ Thủ Thế, chuỗi nhanh tẩm Độc).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Nhát Kết | Chuỗi chém + Điểm Hiểm | Đòn cuối chuỗi cho +1 Điểm Hiểm |
| Mở Sơ Hở | Thủ Thế + Điểm Hiểm | Đỡ được đòn cho +2 Điểm Hiểm |
| Theo Bóng | Đâm Xuyên + Bước Bóng | Sau Đâm Xuyên, Bước Bóng kế tiếp trong 3s không tốn Lực |
| Vòng Độc | Xoáy + Độc | Xoáy đưa mọi kẻ trúng đòn lên bằng số cộng dồn Độc cao nhất trong số chúng |
| Chém Kẻ Ngã | Rạch + Choáng | Rạch lên kẻ đang Choáng không tiêu Điểm Hiểm. ICD 4s |
| Máu Sôi | Hành Quyết + Lực | Hành Quyết giết được trả 30 Lực |
| Tiếng Hét Trong Khói | Hét Trận + Màn Khói | Dùng Hét Trận khi đang trong Màn Khói kéo dài khói thêm 2s |
| **Then chốt: Song Thủ** | | Chuỗi chém nhanh hơn 20% và mỗi nhát thứ hai gây 1 cộng dồn Độc. Giá: không dùng được Thủ Thế |

## 3. Tiên Phong (CB + TS)

Hai hướng build: **Thợ Săn Lớn** (Dấu Săn lên boss, thú giữ chân, chuỗi chém) và **Dồn Bẫy** (Xô Khiên và Dập Đất đẩy quái vào bãi bẫy).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Giữ Nhịp | Chuỗi chém + Tập Trung | Tập Trung cũng đầy khi bạn chém 3s liên tục không bị ngắt, không cần khoảng cách |
| Ra Hiệu | Chuỗi chém + Dấu Săn | Đòn cuối chuỗi lên kẻ mang Dấu Săn làm mới Dấu và gọi thú vồ nó. ICD 3s |
| Rung Bẫy | Dập Đất + Bẫy | Dập Đất làm mọi bẫy trong vùng sập ngay, bẫy gây +50% |
| Hất Vào Bẫy | Xô Khiên + Bẫy Kẹp | Kẻ bị Xô Khiên trúng văng 40; nếu văng vào bẫy, Trói dài gấp đôi |
| Thú Trận | Hét Trận + Thú | Thú hưởng Hét Trận và khiến kẻ quanh nó phải đánh nó 3s |
| Bắn Kẻ Ngã | Phát Ngắm + Choáng | Phát Ngắm lên kẻ đang Choáng không cần đứng ngắm |
| Hất Tên | Xoáy + Mưa Tên | Xoáy trong vùng Mưa Tên làm vùng đó rộng thêm 40% cho tới khi hết |
| **Then chốt: Đi Săn Lớn** | | Bạn và thú gây +25% lên elite và boss mang Dấu Săn. Giá: Dấu Săn hồi chậm gấp đôi |

## 4. Kiếm Bão (CB + NT) [ĐÃ CÓ trong game]

Hai hướng build: **Băng Kiếm** (Vòng Sương rồi đòn cuối chuỗi Vỡ Băng) và **Lò Lửa** (Tia Than, Thổi Lửa, Tim Lò nuôi Lực cho Xoáy).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Tim Lò | Lực + Cháy | Mỗi kẻ đang Cháy cho 2 Lực mỗi giây, tính tối đa 3 kẻ |
| Thủ Tích Điện | Thủ Thế + Sét | Đỡ được đòn thì 3 nhát chém kế tiếp gây Giật |
| Sắt Lạnh | Thủ Thế + Băng | Đỡ được đòn làm mọi kẻ đứng gần bị Lạnh |
| Thổi Lửa | Xoáy + Lửa | Xoáy trúng một kẻ đang Cháy thì mọi kẻ khác trúng đòn cũng Cháy |
| Dư Quang | Hồi Chuông + cả ba hệ | Mọi thứ trúng Hồi Chuông bị Cháy, Lạnh và Giật |
| Vỡ Băng | Chuỗi chém + Băng | Đòn cuối chuỗi phá Lạnh: +80% lên kẻ đó và choáng, kể cả kẻ nặng |
| Dẫn Điện | Đâm Xuyên, Xô Khiên + Sét | Lướt qua kẻ đang Giật phóng Sét Chuyền từ nó. ICD 2s |
| **Then chốt: Kiếm Bão** | | 6s sau một phép, mỗi nhát chém để lại dấu của phép đó. Giá: phép hồi chậm hơn 30% |

## 5. Kiếm Tang (CB + TL)

Hai hướng build: **Tướng Ma** (dư ảnh đông, Hét Trận tăng tốc cả đội quân) và **Áo Tang** (không gọi quân, giữ Hồn để lấy giáp và hút máu).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Nhát Gặt | Chuỗi chém + Hồn | Kẻ chết vì đòn cuối chuỗi cho 2 Hồn |
| Xoáy Hồn | Xoáy + Hồn | Khi thiếu Lực, Xoáy tiêu 1 Hồn thay cho 40 Lực |
| Thúc Quân | Hét Trận + Dư Ảnh | Hét Trận khiến dư ảnh đánh nhanh hơn 30% trong 6s |
| Thế Mạng | Thủ Thế + Hiến Tế | Đỡ được đòn làm dư ảnh gần nhất tự nổ như Hiến Tế. ICD 6s |
| Hái Theo Nhịp | Chuỗi chém + Lưỡi Hái | Lưỡi Hái tính là đòn cuối chuỗi |
| Rải Nguyền | Dập Đất + Nguyền | Dập Đất trúng một kẻ bị Nguyền thì mọi kẻ trúng đòn đều bị Nguyền |
| Chuông Gọi Hồn | Hồi Chuông + Hồn | Hồi Chuông cho 1 Hồn mỗi kẻ trúng, tối đa 3 |
| **Then chốt: Áo Tang** | | Mỗi Hồn đang giữ cho +3 giáp và +2% hút máu. Giá: Gọi Dư Ảnh tốn 2 Hồn |

## 6. Kiếm Nguyện (CB + TT)

Hai hướng build: **Lời Thề** (đánh ở nửa máu dưới, hồi gấp rưỡi) và **Cờ Trận** (Hét Trận nối Chúc Lành, buff cả đội).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Nhát Nguyện | Chuỗi chém + Thành Kính | Đòn cuối chuỗi cho 8 Thành Kính |
| Đỡ Thay | Thủ Thế + hồi máu | Đỡ được đòn hồi 4% máu cho đồng minh trong 80 |
| Chém Kẻ Bị Soi | Chuỗi chém + Ấn Trừng | Đòn cuối chuỗi lên kẻ bị Soi nổ thánh quang 80% vùng nhỏ và tiêu dấu Soi |
| Nối Phước | Hét Trận + Chúc Lành | Dùng cái này khi cái kia còn hiệu lực kéo dài cả hai thêm 3s. Mỗi lần dùng chỉ kéo một lần |
| Xoáy Thiêng | Xoáy + Đất Thiêng | Xoáy khi đứng trong Đất Thiêng hồi 2% máu mỗi kẻ trúng, tối đa 10% |
| Dập Tà | Dập Đất + Trừ Tà | Dập Đất gỡ khiên của quái (không tắt dấu elite) |
| Sống Lại Để Chém | Lời Nguyện + Tử Thủ | Khi Lời Nguyện giữ bạn ở 1 máu, 4s kế tiếp bạn gây +30% |
| **Then chốt: Lời Thề** | | Dưới 50% máu: hồi máu nhận được gấp rưỡi và +15% sát thương. Giá: trên 50% máu bạn không hồi được máu |

## 7. Thiết Thủ (CB + KS)

Hai hướng build: **Giáp Hơi** (giữ Nhiệt trên 70, chém không bị ngắt) và **Chốt Trụ** (Trụ Nỏ và Mìn giữ vùng, Móc Kéo lôi quái vào).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Chém Xả | Chuỗi chém + Nhiệt | Mỗi nhát chém trúng xả 3 Nhiệt, đòn cuối chuỗi xả 8 |
| Hơi Búa | Chuỗi chém + Xả Hơi | Xả Hơi tính là đòn cuối chuỗi và phá thế gấp đôi |
| Kéo Rồi Dập | Móc Kéo + Dập Đất | Trong 2s sau Móc Kéo, Dập Đất không tốn Lực |
| Bắn Kẻ Ngã | Trụ Nỏ + Choáng | Trụ ưu tiên kẻ đang Choáng và gây +50% lên chúng |
| Mìn Phản | Thủ Thế + Mìn Chuông | Đỡ được đòn thả một Mìn Chuông dưới chân kẻ đánh, không cộng Nhiệt. ICD 5s |
| Xoáy Hơi | Tăng Áp + Xoáy | Khi Tăng Áp đang bật, Xoáy cộng 20 Nhiệt thay vì tốn Lực |
| Chuông Trong Lặng | Hồi Chuông + Chuông Câm | Hồi Chuông đánh trong vùng Chuông Câm làm choáng dài gấp đôi |
| **Then chốt: Giáp Hơi** | | Trên 70 Nhiệt: không bị đẩy lùi, chuỗi chém không bị ngắt, tốc đánh +20%. Giá: Quá Nhiệt dài thêm 2s |

## 8. Dạ Vệ (HV + ST)

Hai hướng build: **Mồi Nhử** (Khiêu Khích, để quái đánh vào Khiên rồi kết liễu) và **Khiên Giả** (cố ý để Khiên vỡ để tàng hình).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Né Thành Khiên | Né + Khiên + Điểm Hiểm | Né sát nút cho +15 Khiên. Khiên bị đánh vỡ hết cho +2 Điểm Hiểm. ICD 8s |
| Hở Sườn | Khiên + Điểm Hiểm | Kẻ vừa đánh vào Khiên của bạn trong 2s bị coi là hở lưng: đòn của bạn lên nó tích Điểm Hiểm |
| Đập Rồi Rạch | Đập Khiên + Rạch | Rạch trong 1,5s sau Đập Khiên được tính thêm 1 Điểm Hiểm |
| Khói Che Đội | Màn Khói + Vòng Che | Màn Khói dùng trong Vòng Che làm đồng minh trong vòng cũng mất dấu 2s |
| Án Độc | Phán Quyết + Độc | Phán Quyết gây 1 cộng dồn Độc cho mỗi 25 Khiên đã tiêu |
| Bước Có Khiên | Bước Bóng + Khiên | Bước Bóng cho +15 Khiên |
| Gai Độc | Gai Khiên + Độc | Gai Khiên gây thêm 1 cộng dồn Độc. ICD 1s mỗi kẻ |
| **Then chốt: Khiên Giả** | | Khi Khiên vỡ, để lại một hình nhân hút đòn 2s và bạn tàng hình 2s. ICD 12s. Giá: Khiên tối đa −25% |

## 9. Biên Vệ (HV + TS)

Hai hướng build: **Chốt Gác** (đứng yên sau tường, Phát Ngắm) và **Người Dắt Thú** (thú mang Khiên làm tuyến đầu).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Sau Tường | Tường Chắn + Tập Trung | Đứng trong 40 quanh Tường Chắn của mình tích Tập Trung nhanh gấp đôi, không cần khoảng cách |
| Khiên Cho Thú | Chia Khiên + Thú | Thú luôn nhận 30% lượng Khiên bạn nhận được, bất kể khoảng cách |
| Dụ Vào Bẫy | Khiêu Khích + Bẫy | Kẻ đang bị Khiêu Khích dẫm bẫy nhận +40% |
| Lỗ Châu Mai | Phát Ngắm + Tường Chắn | Phát Ngắm bắn xuyên qua Tường Chắn của bạn gây +30% |
| Mưa Trên Vòng | Mưa Tên + Vòng Che | Mưa Tên đặt chồng lên Vòng Che làm kẻ địch trong đó chậm 30% |
| Thú Giữ Cửa | Xua Thú + Khiêu Khích | Mục tiêu của Xua Thú phải đánh thú trong 3s |
| Đập Con Mồi | Đập Khiên + Dấu Săn | Đập Khiên lên kẻ mang Dấu Săn Trói nó 1,5s |
| **Then chốt: Chốt Gác** | | Đứng yên 2s: đòn tầm xa +30% và Khiên không tự mất. Giá: di chuyển xóa hiệu ứng và mất 10 Khiên |

## 10. Lũy Sấm (HV + NT)

Hai hướng build: **Tâm Bão** (phép lấy mình làm tâm, đứng giữa đám đông) và **Tường Lửa** (Tường Chắn chồng Tường Lửa chia cắt bãi).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Vỏ Cộng Hưởng | Cộng Hưởng + Khiên | Phép dùng lúc có Cộng Hưởng cho +12 Khiên |
| Khiên Điện | Khiên + Sét | Kẻ đánh vào Khiên bị Giật 3s. ICD 2s mỗi kẻ |
| Tường Cháy | Tường Chắn + Tường Lửa | Đặt chồng nhau: tường vừa chặn đường vừa gây Cháy, tồn tại thêm 3s |
| Án Theo Hệ | Phán Quyết + dấu | Phán Quyết để lại dấu của phép cuối bạn dùng |
| Gọi Kẻ Lạnh | Khiêu Khích + Băng | Khiêu Khích trúng kẻ đang Lạnh đóng băng nó 1s |
| Lồng Trong Vòng | Lồng Sét + Vòng Che | Lồng Sét đặt lên Vòng Che rộng bằng vòng và tồn tại lâu bằng vòng |
| Đập Vỡ | Đập Khiên + Băng | Đập Khiên lên kẻ Lạnh tiêu Lạnh: +60% và choáng 1,2s |
| **Then chốt: Tâm Bão** | | Phép lấy bạn làm tâm (Vòng Sương, Lồng Sét đặt dưới chân, Tam Tai) rộng thêm 40% và +20%. Giá: Tia Than và Mũi Băng chỉ còn nửa tầm |

## 11. Mộ Vệ (HV + TL)

Hai hướng build: **Lăng Mộ** (Thành Đồng gọi cả đội quân) và **Người Canh** (dư ảnh mang Khiên, chết thay chủ).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Hồn Hóa Khiên | Hồn + Khiên | Mỗi Hồn nhận được cho +8 Khiên |
| Áo Cho Bóng | Gọi Dư Ảnh + Khiên | Dư ảnh mới gọi nhận Khiên bằng 30% Khiên bạn đang có |
| Xiềng Kẻ Bị Gọi | Khiêu Khích + Xiềng Hồn | Kẻ bị Khiêu Khích tự bị nối Xiềng Hồn, tối đa 3 kẻ |
| Tế Lấy Khiên | Hiến Tế + Khiên | Hiến Tế trả cho bạn +20 Khiên |
| Án Kẻ Bị Nguyền | Phán Quyết + Nguyền | Phán Quyết lên kẻ bị Nguyền +40% và làm mới Nguyền |
| Chết Thay | Dư Ảnh + máu | Khi một đòn sắp lấy hơn 20% máu của bạn, một dư ảnh tan thay và bạn không mất máu. ICD 10s |
| Vòng Nguyền | Vòng Che + Lời Nguyền Yếu | Kẻ địch bước vào Vòng Che bị Nguyền 4s |
| **Then chốt: Lăng Mộ** | | Thành Đồng đồng thời gọi đủ số dư ảnh tối đa, không tốn Hồn. Giá: Thành Đồng hồi chậm thêm 30s |

## 12. Thánh Vệ (HV + TT)

Hai hướng build: **Tử Vì Đạo** (Thế Thân, nhận thay cả đội) và **Vòng Thiêng** (Vòng Che gộp Đất Thiêng, giữ một điểm).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Chịu Đòn Là Cầu Nguyện | Khiên + Thành Kính | Cứ 10 sát thương Khiên hấp thụ cho 3 Thành Kính |
| Máu Thừa Thành Khiên | Dư Âm + Khiên | Máu hồi thừa thành Khiên thật, tới trần Khiên tối đa thay vì 5% máu |
| Mõ Gọi | Tiếng Mõ + Khiêu Khích | Tiếng Mõ khiến kẻ địch trong vùng phải đánh bạn 2s |
| Một Vòng | Vòng Che + Đất Thiêng | Đặt chồng nhau thì gộp thành một vòng có cả hai hiệu ứng, tồn tại thêm 3s |
| Án Soi | Phán Quyết + Soi | Phán Quyết để dấu Soi lên mọi kẻ trúng |
| Nguyện Chung | Lời Nguyện + Thế Thân | Lời Nguyện ban cho đồng minh cũng che cho bạn 1,5s |
| Đập Tan Khiên Tà | Đập Khiên + Trừ Tà | Đập Khiên gỡ khiên của quái |
| **Then chốt: Tử Vì Đạo** | | Sát thương bạn nhận thay đồng minh giảm 30% và tích Thành Kính gấp đôi. Giá: bạn gây −20% sát thương |

## 13. Pháo Lũy (HV + KS)

Hai hướng build: **Lô Cốt** (tường có trụ gắn sẵn, giữ một hành lang) và **Lò Khiên** (Xả Hơi lấy Khiên, đánh gần).

| Node | Ghép | Hiệu ứng |
|---|---|---|
| Khiên Tản Nhiệt | Khiên + Nhiệt | Mỗi đòn Khiên hấp thụ xả 5 Nhiệt. ICD 0,5s |
| Trụ Sau Tường | Tường Chắn + Trụ Nỏ | Trụ đặt sát Tường Chắn không bị quái đánh và tồn tại thêm 3s |
| Khiên Cho Máy | Chia Khiên + thiết bị | Thiết bị nhận Khiên bằng 20% Khiên bạn nhận được |
| Hơi Thành Khiên | Xả Hơi + Khiên | Xả Hơi cho Khiên bằng nửa số Nhiệt đã xả |
| Dụ Qua Mìn | Khiêu Khích + Mìn Chuông | Kẻ đang bị Khiêu Khích dẫm mìn nhận +50% |
| Kéo Tới Đập | Móc Kéo + Đập Khiên | Đập Khiên trong 1,5s sau khi Móc Kéo tới một kẻ địch làm choáng dài gấp đôi |
| Vòng Lặng | Vòng Che + Chuông Câm | Đặt chồng nhau thì gộp: đạn của địch bay vào vòng biến mất |
| **Then chốt: Lô Cốt** | | Tường Chắn có sẵn một Trụ Nỏ gắn trên, không tính vào giới hạn thiết bị. Giá: Tường Chắn hồi chậm thêm 8s và cộng 30 Nhiệt |
