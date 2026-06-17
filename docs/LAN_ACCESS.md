Hướng dẫn truy cập Flutter Web trong mạng LAN
Chạy bằng một lệnh (Khuyến nghị)
Windows (PowerShell)
cd D:\Mobiapp
.\scripts\run_web_lan.ps1
macOS / Linux
chmod +x scripts/run_web_lan.sh
./scripts/run_web_lan.sh

Script sẽ tự động:

Phát hiện địa chỉ IPv4 trong mạng LAN (không phải 127.0.0.1)
Đọc cổng ưu tiên từ config/lan_web.json, nếu cổng đang bận sẽ tự tìm cổng trống tiếp theo
Khởi động Flutter Web bằng địa chỉ 0.0.0.0 (không phải localhost)
Hiển thị URL truy cập trên máy tính và URL truy cập từ điện thoại
Hiển thị cảnh báo liên quan đến tường lửa
Tự xử lý CORS thông qua web_dev_config.yaml (điện thoại chỉ cần mở 1 cổng)

Ví dụ sau khi chạy:

http://192.168.1.42:8080

Nếu cổng 8080 đang được sử dụng:

http://192.168.1.42:8081
Debug trong ứng dụng

Khi chạy bản Debug trên Web sẽ xuất hiện bảng thông tin LAN:

Hiển thị:

Port hiện tại
URL localhost
URL truy cập từ điện thoại
Chế độ CORS

Ngoài ra các thông tin này cũng được ghi ra terminal.

Cấu hình cổng
Nguồn cấu hình	Mô tả
config/lan_web.json	preferredWebPort, portScanRange
web_dev_config.yaml	Cổng mặc định dự phòng
LAN_WEB_PORT	Ghi đè cổng web
LAN_PORT_SCAN_RANGE	Số lượng cổng quét
Truy cập từ điện thoại
Bước 1

Đảm bảo:

Máy tính và điện thoại cùng kết nối một Wi-Fi
Không dùng mạng khách (Guest Network)
Bước 2

Chạy:

.\scripts\run_web_lan.ps1
Bước 3

Đợi Flutter build xong.

Bước 4

Mở trình duyệt trên điện thoại.

Nhập URL LAN mà terminal hiển thị.

Ví dụ:

http://192.168.1.42:8080
Kiến trúc hoạt động
Thành phần	Địa chỉ	CORS
Flutter Web	0.0.0.0 + cổng động	Không
Proxy tích hợp	Cùng cổng với Web	Chuyển tiếp nominatim, osrm...
Proxy ngoài (tuỳ chọn)	Cổng riêng	Có

Mặc định chỉ cần một cổng.

Điện thoại chỉ truy cập URL Web là dùng được.

Proxy CORS bên ngoài (Tuỳ chọn)
Windows
.\scripts\run_web_lan.ps1 -ExternalProxy
macOS/Linux
EXTERNAL_PROXY=1 ./scripts/run_web_lan.sh
Tường lửa
Windows

Lần đầu chạy:

Cho phép Dart
Cho phép Flutter

truy cập mạng riêng (Private Network)

Hoặc mở thủ công cổng mà script thông báo.

macOS

Vào:

System Settings
→ Network
→ Firewall

Cho phép công cụ phát triển truy cập mạng.

Linux
ufw allow <port>/tcp

hoặc tắt firewall để kiểm tra.

Khắc phục sự cố
Hiện tượng	Nguyên nhân	Cách xử lý
Không mở được trang	Không cùng Wi-Fi	Kết nối cùng mạng
Không mở được trang	Firewall chặn	Mở cổng
Không mở được trang	Dùng localhost hoặc 127.0.0.1	Dùng IP LAN
Không mở được trang	IP máy tính thay đổi	Chạy lại script
Trang trắng	Build chưa xong	Đợi Flutter compile xong
Có giao diện nhưng không có bản đồ	Chưa dùng run_web_lan	Chạy đúng script
Có giao diện nhưng tìm kiếm không hoạt động	Lỗi CORS	Kiểm tra web_dev_config.yaml
GPS không hoạt động	Trình duyệt chặn	Dùng HTTPS hoặc app Android
Chỉ xem URL LAN

Không khởi động server:

.\scripts\print_lan_urls.ps1
Các file liên quan
scripts/run_web_lan.ps1
scripts/run_web_lan.sh

scripts/port_utils.ps1
scripts/port_utils.sh

scripts/get_lan_ip.ps1

config/lan_web.json

web_dev_config.yaml

lib/core/web_lan_runtime.dart

lib/widgets/web_lan_debug_overlay.dart

lib/core/lan_dev_config.dart

Tóm lại: chỉ cần chạy

cd D:\Mobiapp
.\scripts\run_web_lan.ps1

sau đó lấy địa chỉ kiểu:

http://192.168.x.x:8080

nhập vào điện thoại cùng Wi-Fi là có thể xem Flutter Web trên điện thoại.