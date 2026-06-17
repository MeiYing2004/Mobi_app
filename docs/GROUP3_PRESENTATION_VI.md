# Nhóm 3 — PageView · Bottom Sheets · Drawer

**Môn:** Mobile Applications Development  
**App demo:** Mobiapp → icon **Food Demo**  
**File code:** `lib/features/group3_demo/group3_food_demo_screen.dart`

---

## Slide 1 — Tiêu đề & Giới thiệu

**Tiêu đề slide:**
> Advanced Widgets — PageView, Bottom Sheets & Drawer trong Flutter

**Nói gì:**
- Xin chào thầy/cô và các bạn, nhóm em trình bày **Nhóm nội dung 3**.
- Chủ đề: ba widget nâng cao dùng để xây giao diện cuộn trang, panel phụ và menu điều hướng.
- Demo thực tế trên app Flutter **Mobiapp** — màn **Food Demo** (app đặt món ăn).

**Ghi chú demo:** Mở app → chạm icon **Food Demo** (cam, mục Học tập).

---

## Slide 2 — Đặt vấn đề

**Tiêu đề:** Vì sao cần PageView, Bottom Sheet và Drawer?

**Nói gì:**
- App mobile cần **vuốt qua nhiều màn** (onboarding, danh mục món).
- Cần **hiện thông tin phụ** mà không rời màn chính → Bottom Sheet.
- Cần **menu điều hướng** tiết kiệm không gian → Drawer.
- Nếu chỉ dùng `Navigator.push` cho mọi thứ → UX chậm, nhiều bước, khó quay lại.

**Ví dụ đời thường:** GrabFood, ShopeeFood — vuốt danh mục, sheet chi tiết món, menu tài khoản.

---

## Slide 3 — Mục tiêu bài thuyết trình

**Tiêu đề:** Mục tiêu

**Bullet slide:**
1. Giải thích **PageView** — vuốt phân trang ngang/dọc.
2. Phân biệt **Modal** vs **Persistent Bottom Sheet**.
3. Triển khai **Drawer** + quản lý state & cử chỉ.
4. **Demo** case study app đặt món ăn trên Flutter.

**Kết quả mong đợi:** Người nghe hiểu khi nào dùng widget nào và thấy chạy được trên thiết bị.

---

## Slide 4 — Khái niệm PageView

**Tiêu đề:** PageView là gì?

**Nói gì:**
- `PageView` là widget **cuộn theo từng trang** (snap từng page).
- Khác `ListView`: ListView cuộn liên tục; PageView dừng từng trang.
- Ứng dụng: onboarding, gallery ảnh, **danh mục món theo tab ngang**.

**Demo:** Food Demo → vuốt trái/phải giữa **Pizza | Burger | Đồ uống**.

**So sánh nhanh:**

| | ListView | PageView |
|---|----------|----------|
| Cuộn | Liên tục | Từng trang |
| Use case | Danh sách dài | Tab / onboarding |

---

## Slide 5 — Thuộc tính quan trọng & Code

**Tiêu đề:** PageView — API quan trọng

**Code (trích project):**

```dart
PageView.builder(
  controller: _pageController,
  onPageChanged: (i) => setState(() => _pageIndex = i),
  itemCount: _categories.length,
  itemBuilder: (context, pageIndex) {
    return GridView.builder(/* món theo danh mục */);
  },
)
```

**Giải thích từng phần:**

| Thuộc tính | Ý nghĩa |
|------------|---------|
| `controller` | Điều khiển trang programmatically (`animateToPage`) |
| `onPageChanged` | Callback khi đổi trang → cập nhật UI (dot, title) |
| `itemCount` | Số trang |
| `itemBuilder` | Nội dung mỗi trang |
| `scrollDirection` | `Axis.horizontal` (mặc định) hoặc `vertical` |

**File:** `lib/features/group3_demo/group3_food_demo_screen.dart` — hàm `_buildFoodSection()`

**Bonus trong app:** Home iOS cũng dùng PageView — `ios_home_screen.dart` dòng ~191.

---

## Slide 6 — UI Demo PageView

**Tiêu đề:** Demo PageView — App đặt món

**Thao tác live (30 giây):**
1. Mở **Food Demo**.
2. Vuốt ngang → 3 danh mục món.
3. Chỉ dot indicator / tên danh mục góc phải đổi theo.
4. (Tuỳ chọn) Drawer → **PageView demo** → `animateToPage(0)`.

**Điểm nhấn:** Mỗi trang là một `GridView.builder` — lưới món riêng theo category.

---

## Slide 7 — Phân loại Bottom Sheets

**Tiêu đề:** Hai loại Bottom Sheet

**Bảng so sánh (đặt lên slide):**

| | Modal Bottom Sheet | Persistent Bottom Sheet |
|---|-------------------|------------------------|
| API | `showModalBottomSheet` | `Scaffold.showBottomSheet` / `bottomSheet:` |
| Nền | Mờ (block UI) | Không block hoàn toàn |
| Use case | Chi tiết món, form | Giỏ hàng, nhạc đang phát |
| Đóng | Vuốt xuống / `Navigator.pop` | `Navigator.pop` hoặc ẩn widget |

**Nói gì:** Modal = hành động tạm thời, cần focus. Persistent = thông tin luôn hiện (cart bar).

---

## Slide 8 — Modal Bottom Sheet (Kỹ thuật & Code)

**Tiêu đề:** Modal Bottom Sheet

**Code (trích project):**

```dart
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (ctx) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        // +/- số lượng, nút Thêm vào giỏ
      },
    );
  },
);
```

**Giải thích:**
- `isScrollControlled: true` — sheet cao hơn mặc định (half screen).
- `StatefulBuilder` — đổi số lượng **trong sheet** không cần rebuild cả màn.
- `shape` — bo góc trên giống iOS/Material 3.

**Demo:** Chạm một món → sheet chi tiết → +/- → **Thêm vào giỏ**.

**File:** `group3_food_demo_screen.dart` — `_showFoodModal()`

**Trong app chính:** `home_shell.dart` — sheet trạm xăng (`showModalBottomSheet` + `CinematicSheet`).

---

## Slide 9 — Persistent Bottom Sheet & Demo

**Tiêu đề:** Persistent Bottom Sheet

**Hai cách trong demo:**

**Cách 1 — `Scaffold.bottomSheet` (giỏ hàng):**
```dart
bottomSheet: _cartCount > 0
    ? Material(/* thanh giỏ hàng */)
    : null,
```
→ Khi có món trong giỏ, thanh **dính dưới màn hình**.

**Cách 2 — `Scaffold.showBottomSheet`:**
```dart
Scaffold.of(context).showBottomSheet((ctx) {
  return Material(/* nội dung sheet */);
});
```
→ Bấm FAB **Persistent Sheet** hoặc Drawer → **Persistent Sheet**.

**Demo live:**
1. Thêm món → thanh giỏ xuất hiện (persistent).
2. Bấm FAB → sheet demo `showBottomSheet`.
3. So sánh: modal che nền mờ; persistent vẫn thấy lưới món phía sau.

---

## Slide 10 — Tổng quan về Drawer

**Tiêu đề:** Drawer — Menu trượt cạnh

**Nói gì:**
- Panel trượt từ **trái** (hoặc phải với `endDrawer`).
- Gắn vào `Scaffold(drawer: Drawer(...))`.
- Chứa: điều hướng, cài đặt, phím tắt demo.

**Demo:** Bấm ☰ → menu 3 section + Persistent Sheet + Đóng.

**Code khung:**
```dart
Scaffold(
  key: _scaffoldKey,
  drawer: Drawer(
    child: ListView(
      children: [
        DrawerHeader(/* ... */),
        ListTile(title: Text('Trang chủ'), onTap: ...),
      ],
    ),
  ),
)
```

---

## Slide 11 — Quản lý Trạng thái (State Management)

**Tiêu đề:** State trong Food Demo

**Nói gì:** Dùng `StatefulWidget` + `setState` — đủ cho demo môn học.

**State quản lý:**

| Biến | Mục đích |
|------|----------|
| `_pageIndex` | Trang PageView hiện tại |
| `_cartCount` / `_cartLines` | Giỏ hàng |
| `_section` | Tab Drawer: food / listGrid / slivers |
| `_scaffoldKey` | Mở Drawer từ code |

**Code:**
```dart
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

setState(() {
  _cartCount += qty;
  _cartLines.add(item.name);
});
```

**Lưu ý trình bày:** Production app lớn có thể dùng Provider/Riverpod — demo này cố ý giữ đơn giản để thấy luồng state rõ ràng.

---

## Slide 12 — Xử lý Cử chỉ & Code Demo

**Tiêu đề:** Cử chỉ Drawer & Sheet

**Cử chỉ hỗ trợ:**

| Cử chỉ | Widget | Demo |
|--------|--------|------|
| Vuốt ngang | PageView | Đổi danh mục món |
| Vuốt từ cạnh trái | Drawer | `drawerEnableOpenDragGesture: true` |
| Vuốt xuống | Modal sheet | Đóng sheet chi tiết |
| Chạm ☰ | `openDrawer()` | Mở menu bằng code |

**Code mở/đóng Drawer:**
```dart
void _openDrawer() => _scaffoldKey.currentState?.openDrawer();
void _closeDrawer() => Navigator.of(context).pop();
```

**Demo (1 phút):**
1. Vuốt mở Drawer.
2. Chọn section khác → body đổi (`switch (_section)`).
3. Đóng bằng nút hoặc vuốt ngược.

---

## Slide 13 — Case Study: App Đặt Món Ăn

**Tiêu đề:** Case Study — Food Demo

**Kiến trúc màn hình:**

```
Scaffold
├── AppBar (☰ Drawer)
├── Drawer (điều hướng 3 phần)
├── Body
│   └── PageView (3 danh mục)
│       └── GridView (món ăn)
├── bottomSheet (giỏ hàng persistent)
└── FAB (demo showBottomSheet)
```

**Luồng người dùng:**
1. Chọn danh mục (PageView).
2. Chọn món (Grid).
3. Xem chi tiết (Modal Sheet).
4. Thêm giỏ → Persistent bar.
5. Menu phụ (Drawer).

**Demo:** Chạy full flow 1 lần (~1 phút).

---

## Slide 14 — Tích hợp Bottom Sheet vào Case Study

**Tiêu đề:** Bottom Sheet trong đặt món

**Sơ đồ luồng (vẽ trên slide):**

```
[Grid món] --tap--> [Modal: chi tiết + số lượng]
                           |
                     [Thêm vào giỏ]
                           |
                           v
              [Persistent: thanh giỏ dưới cùng]
```

**Nói gì:**
- **Modal** = quyết định mua (focus, không phân tâm).
- **Persistent** = nhắc user đang có hàng trong giỏ.
- Tách đúng loại sheet → UX giống app thật (Grab, ShopeeFood).

**Demo:** Lặp lại flow, nhấn mạnh 2 loại sheet khác nhau.

---

## Slide 15 — Tổng kết & Q&A

**Tiêu đề:** Tổng kết

**Bullet:**
- **PageView** — phân trang, onboarding, danh mục ngang.
- **Modal Sheet** — chi tiết, form, hành động ngắn.
- **Persistent Sheet** — trạng thái liên tục (giỏ hàng).
- **Drawer** — menu, điều hướng phụ, tiết kiệm không gian.
- Demo hoàn chỉnh trong **Food Demo** (Mobiapp).

**Bài học rút ra:**
- Chọn widget đúng use case quan trọng hơn “dùng cho đủ”.
- `GlobalKey` + `setState` đủ cho prototype; scale lên dùng state management.

**Q&A — câu hỏi dự kiến:**

| Câu hỏi | Trả lời ngắn |
|---------|--------------|
| PageView vs TabBar? | PageView vuốt tự do; TabBar gắn tab cố định |
| Modal vs Dialog? | Sheet từ dưới lên; Dialog giữa màn |
| Drawer vs BottomNavigationBar? | Drawer ẩn nhiều mục; BottomNav 3–5 mục chính |
| `shrinkWrap` ListView? | Dùng khi lồng ListView trong Column/ListView khác |

**Kết:** Cảm ơn thầy/cô — sẵn sàng Q&A.

---

## Checklist trước khi báo cáo

- [ ] Hot restart app, thử **Food Demo** end-to-end
- [ ] Vuốt PageView 3 trang OK
- [ ] Modal sheet mở/đóng OK
- [ ] Thêm giỏ → persistent bar hiện
- [ ] Drawer mở bằng ☰ và vuốt
- [ ] FAB Persistent Sheet OK
- [ ] Copy slide từ file này sang PowerPoint/Google Slides
- [ ] Chụp screenshot demo cho slide 6, 9, 13

## File code tham khảo nhanh

| Slide | File |
|-------|------|
| PageView | `group3_food_demo_screen.dart` |
| Modal Sheet | `group3_food_demo_screen.dart` → `_showFoodModal` |
| Persistent | `group3_food_demo_screen.dart` → `_showPersistentSheetDemo`, `bottomSheet:` |
| Drawer | `group3_food_demo_screen.dart` → `drawer:` |
| PageView (app chính) | `ios_home_screen.dart` |
| Modal (app chính) | `home_shell.dart` → `_openStationSheet` |
