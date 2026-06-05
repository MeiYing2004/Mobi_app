# Truy cập Flutter Web qua Wi-Fi LAN

## Một lệnh (từ thư mục project)

```powershell
cd D:\Mobiapp
.\scripts\fix_lan_firewall.ps1 -SetWiFiPrivate
.\scripts\run_web_lan.ps1
```

Chỉ chạy Web (đã sửa firewall trước đó):

```powershell
cd D:\Mobiapp
.\scripts\run_web_lan.ps1
```

```bash
./scripts/run_web_lan.sh
```

## Trên điện thoại

1. Cùng Wi-Fi với máy tính.
2. Mở URL **màu xanh** in trong terminal, ví dụ `http://192.168.1.42:8081`.
3. Cổng có thể **khác** `8080` nếu cổng ưu tiên đã bị chiếm — luôn dùng URL script in ra.

## Cấu hình cổng

- `config/lan_web.json` — `preferredWebPort`, `portScanRange`
- `LAN_WEB_PORT` — ghi đè cổng ưu tiên

## Debug trong app

Bản debug Web hiển thị overlay **LAN debug**: Local URL, LAN URL, Port, CORS.

## Nếu điện thoại không vào được

Chạy chẩn đoán:

```powershell
.\scripts\diagnose_lan.ps1
```

**Thường gặp trên Windows:** Wi-Fi `UMT-LAB512` bị coi là **Mạng công cộng (Public)** → firewall chặn điện thoại.

```powershell
# Chạy PowerShell **Quản trị viên**:
.\scripts\fix_lan_firewall.ps1 -Port 8080 -SetWiFiPrivate
```

Hoặc: **Cài đặt → Mạng → Wi-Fi → UMT-LAB512 → Mạng riêng (Private)**.

| Nguyên nhân | Cách xử lý |
|-------------|------------|
| **Wi-Fi Public (chính)** | `fix_lan_firewall.ps1` hoặc đổi sang Private |
| Sai cổng | Dùng đúng URL script in (8080/8081/8082…) |
| Khác mạng / AP isolation | Cùng Wi-Fi; lab có thể cách ly máy — thử hotspot điện thoại |
| Firewall | `fix_lan_firewall.ps1` (Admin) |
| Dùng localhost | Chỉ `http://10.10.0.30:<cổng>`, không `127.0.0.1` |
| Trang trắng | Đợi `flutter run` compile xong |
| Không map/search | Chạy `run_web_lan.ps1`, không `flutter run -d chrome` |

Ví dụ mạng của bạn: PC `10.10.0.30`, điện thoại `10.10.0.31` → thử `http://10.10.0.30:8080` hoặc `:8081`.

Chi tiết: [LAN_ACCESS.md](LAN_ACCESS.md)
