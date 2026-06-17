# Nhóm 3 — PageView · Bottom Sheets · Drawer

**Môn:** Flutter Advanced Widgets (A07)  
**Thời lượng gợi ý:** 12–15 phút  
**Demo app:** Mobiapp → icon **Food Demo** (category Học tập)

---

## MỞ ĐẦU & TỔNG QUAN

### Slide 1 — Tiêu đề & Giới thiệu

**Tiêu đề slide:**
> Flutter Advanced Widgets — Nhóm 3  
> PageView · Bottom Sheets · Drawer

**Nội dung:**
- Nhóm: [điền tên thành viên]
- Môn học: Lập trình Flutter
- Tài liệu tham khảo: A07. Advanced Widgets (Dung Nguyen)
- Demo: App **Food Demo** trong project Mobiapp

**Lời nói gợi ý:**
> Xin chào thầy/cô và các bạn. Nhóm 3 trình bày ba widget điều hướng và tương tác nâng cao trong Flutter: **PageView** để vuốt chuyển trang, **Bottom Sheet** để hiện nội dung phụ từ dưới lên, và **Drawer** để mở menu bên cạnh. Cuối buổi chúng em demo tất cả trong một app đặt món ăn.

---

### Slide 2 — Đặt vấn đề

**Tiêu đề slide:**
> Vì sao cần PageView, Bottom Sheet và Drawer?

**Nội dung:**
- App di động cần **nhiều màn hình** nhưng không thể nhồi hết vào một view
- Người dùng cần **thao tác nhanh** (chọn món, xem giỏ) mà không rời màn chính
- Menu điều hướng phải **tiết kiệm không gian** — không chiếm hết AppBar
- Ba widget này là **pattern chuẩn Material Design**, có sẵn trong Flutter SDK

**Lời nói gợi ý:**
> Khi làm app thực tế, ta thường gặp ba bài toán: vuốt xem nhiều danh mục, bật form chi tiết mà không chuyển route mới, và mở menu mà không mất context màn hiện tại. Flutter giải quyết bằng PageView, Bottom Sheet và Drawer.

---

### Slide 3 — Mục tiêu bài thuyết trình

**Tiêu đề slide:**
> Mục tiêu

**Nội dung:**
1. Giải thích **khái niệm** và **phân loại** từng widget
2. Nêu **thuộc tính quan trọng** và **đoạn code** minh họa
3. **Demo trực tiếp** trên app Food Demo
4. **Tổng hợp** trong case study app đặt món ăn

**Lời nói gợi ý:**
> Sau buổi trình bày, các bạn sẽ biết khi nào dùng PageView thay ListView, khi nào dùng Modal vs Persistent Bottom Sheet, và cách quản lý Drawer bằng ScaffoldState.

---

## PAGEVIEW

### Slide 4 — Khái niệm PageView

**Tiêu đề slide:**
> PageView là gì?

**Nội dung:**
- Widget cho phép **vuốt ngang hoặc dọc** giữa các "trang" con
- Mỗi trang là một child widget độc lập
- Dùng cho: onboarding, gallery ảnh, tab danh mục, carousel
- Khác **ListView**: ListView cuộn liên tục; PageView **snap** từng trang

**Sơ đồ (có thể vẽ trên slide):**
```
[ Trang 0 ] ← swipe → [ Trang 1 ] ← swipe → [ Trang 2 ]
     ● ○ ○                    (page indicator)
```

**Lời nói gợi ý:**
> PageView tạo cảm giác "lật trang". Trong app đặt món, mỗi trang là một danh mục: Pizza, Burger, Đồ uống.

---

### Slide 5 — Thuộc tính quan trọng & Code

**Tiêu đề slide:**
> PageView — Thuộc tính & Code

**Nội dung bảng:**

| Thuộc tính | Ý nghĩa |
|------------|---------|
| `controller` | `PageController` — điều khiển trang programmatically |
| `onPageChanged` | Callback khi trang đổi → cập nhật UI (dot, label) |
| `itemCount` | Số trang (dùng với `.builder`) |
| `physics` | `BouncingScrollPhysics`, `NeverScrollableScrollPhysics`… |
| `scrollDirection` | `Axis.horizontal` (mặc định) hoặc `vertical` |

**Code (từ Food Demo):**
```dart
final PageController _pageController = PageController();
int _pageIndex = 0;

PageView.builder(
  controller: _pageController,
  onPageChanged: (i) => setState(() => _pageIndex = i),
  itemCount: _categories.length,
  itemBuilder: (context, pageIndex) {
    return GridView.builder(
      // lưới món theo danh mục
    );
  },
)
```

**File:** `lib/features/group3_demo/group3_food_demo_screen.dart`

**Lời nói gợi ý:**
> `PageController` giúp nhảy tới trang cụ thể. `onPageChanged` đồng bộ dot indicator. `itemBuilder` lazy-build từng trang — hiệu năng tốt khi nhiều danh mục.

---

### Slide 6 — UI Demo PageView

**Tiêu đề slide:**
> Demo — PageView trong Food Demo

**Nội dung:**
- Mở app → **Food Demo**
- Vuốt ngang: **Pizza → Burger → Đồ uống**
- Quan sát: dot indicator + tên danh mục đổi theo trang
- Mỗi trang chứa `GridView.builder` hiển thị món

**Thao tác live:**
1. Vuốt trái/phải 3 lần
2. Chỉ vào dot indicator phía trên lưới
3. Mở code `group3_food_demo_screen.dart` dòng `_buildFoodSection`

**Lời nói gợi ý:**
> Đây là PageView bọc GridView — pattern phổ biến trong app e-commerce và food delivery.

---

## BOTTOM SHEETS

### Slide 7 — Phân loại Bottom Sheets

**Tiêu đề slide:**
> Hai loại Bottom Sheet

**Nội dung bảng so sánh:**

| | **Modal Bottom Sheet** | **Persistent Bottom Sheet** |
|---|------------------------|----------------------------|
| API | `showModalBottomSheet()` | `Scaffold.showBottomSheet()` hoặc `Scaffold.bottomSheet:` |
| Hành vi | Che màn hình, có barrier tối | Nằm **cùng** Scaffold, không chặn toàn màn |
| Đóng | Vuốt xuống / `Navigator.pop` | `Navigator.pop(ctx)` hoặc set `bottomSheet: null` |
| Dùng khi | Form chi tiết, xác nhận, chọn tùy chọn | Giỏ hàng, player nhạc, thanh trạng thái |

**Lời nói gợi ý:**
> Modal = popup tạm thời. Persistent = thành phần cố định của layout, user vẫn tương tác phần còn lại.

---

### Slide 8 — Modal Bottom Sheet (Kỹ thuật & Code)

**Tiêu đề slide:**
> Modal Bottom Sheet

**Nội dung:**
- Gọi `showModalBottomSheet<T>(context: context, builder: ...)`
- `isScrollControlled: true` — sheet cao hơn nửa màn (form dài)
- `shape` — bo góc trên
- `StatefulBuilder` — cập nhật state **bên trong** sheet (số lượng +/-)

**Code (từ Food Demo):**
```dart
void _showFoodModal(_FoodItem item) {
  var qty = 1;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          // +/- qty, nút "Thêm vào giỏ"
        },
      );
    },
  );
}
```

**Demo live:** Chạm một món → sheet hiện → tăng số lượng → **Thêm vào giỏ**

**Lời nói gợi ý:**
> Chạm món không push route mới — UX mượt hơn. `StatefulBuilder` tách state tạm của modal khỏi state màn chính.

---

### Slide 9 — Persistent Bottom Sheet & Demo

**Tiêu đề slide:**
> Persistent Bottom Sheet

**Nội dung — Hai cách trong Food Demo:**

**Cách 1 — `Scaffold.bottomSheet:` (giỏ hàng)**
```dart
bottomSheet: _cartCount > 0
    ? Material(
        child: Row(
          children: [
            Text('Giỏ hàng · $_cartCount món'),
            TextButton(onPressed: clearCart, child: Text('Xóa')),
          ],
        ),
      )
    : null,
```

**Cách 2 — `Scaffold.showBottomSheet()` (FAB)**
```dart
Scaffold.of(context).showBottomSheet((ctx) {
  return Material(
    child: Container(
      height: 140,
      child: Column(
        children: [
          Text('Persistent Bottom Sheet'),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Đóng'),
          ),
        ],
      ),
    ),
  );
});
```

**Demo live:**
1. Thêm món → thanh giỏ **persistent** xuất hiện dưới cùng
2. Bấm FAB **Persistent Sheet** → sheet demo `showBottomSheet`

**Lời nói gợi ý:**
> Giỏ hàng dùng `bottomSheet:` vì luôn hiện khi có món. Nút FAB demo cách gọi `showBottomSheet` động.

---

## DRAWER

### Slide 10 — Tổng quan về Drawer

**Tiêu đề slide:**
> Drawer — Menu trượt cạnh

**Nội dung:**
- Panel trượt từ **cạnh trái** (hoặc `endDrawer` bên phải)
- Gắn vào `Scaffold(drawer: Drawer(...))`
- Thường chứa: `DrawerHeader`, `ListTile` điều hướng
- Material Design: chiều rộng ~ 304dp (mobile)

**Cấu trúc:**
```
Scaffold
├── drawer: Drawer
│   ├── DrawerHeader (gradient, tiêu đề)
│   ├── ListTile (mục menu)
│   └── ...
├── appBar
└── body
```

**Lời nói gợi ý:**
> Drawer là navigation pattern cổ điển nhưng vẫn phổ biến cho menu phụ, cài đặt, chuyển section.

---

### Slide 11 — Quản lý Trạng thái (State Management)

**Tiêu đề slide:**
> Drawer & State Management

**Nội dung:**
- `GlobalKey<ScaffoldState>` — mở drawer từ bất kỳ đâu trong Scaffold
- `setState` — đổi section khi chọn menu (`_section`)
- `Navigator.pop(context)` — đóng drawer (pop overlay route)
- State đồng bộ: `ListTile(selected: _section == ...)` highlight mục active

**Code:**
```dart
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

void _openDrawer() => _scaffoldKey.currentState?.openDrawer();
void _closeDrawer() => Navigator.of(context).pop();

void _goSection(_DemoSection section) {
  setState(() => _section = section);
  _closeDrawer();
}

Scaffold(
  key: _scaffoldKey,
  drawer: Drawer(
    child: ListTile(
      selected: _section == _DemoSection.food,
      onTap: () => _goSection(_DemoSection.food),
    ),
  ),
  body: switch (_section) { ... },
)
```

**Lời nói gợi ý:**
> Không cần Provider cho demo đơn giản — `setState` + enum `_DemoSection` đủ. Production app có thể dùng Riverpod/Bloc.

---

### Slide 12 — Xử lý Cử chỉ & Code Demo

**Tiêu đề slide:**
> Drawer — Cử chỉ & Demo

**Nội dung:**
- `drawerEnableOpenDragGesture: true` — vuốt từ cạnh trái mở drawer
- Nút ☰ gọi `openDrawer()` — cho user không biết gesture
- Đóng: vuốt ngược, tap outside, hoặc `Navigator.pop`

**Demo live:**
1. Bấm ☰ → Drawer mở
2. Chọn **List · Grid · Card** → body đổi section
3. Chọn **CustomScrollView** → tab Slivers
4. Vuốt từ cạnh trái mở lại drawer
5. **Đóng Drawer**

**Lời nói gợi ý:**
> Food Demo có 3 tab trong Drawer — không chỉ navigation mà còn showcase widget A07 bonus (GridView, Slivers).

---

## THỰC HÀNH TỔNG HỢP & KẾT LUẬN

### Slide 13 — Case Study: App Đặt Món Ăn

**Tiêu đề slide:**
> Case Study — Food Demo App

**Nội dung — Kiến trúc màn hình:**
```
Food Demo (Scaffold)
├── Drawer          → chuyển 3 section demo
├── AppBar          → tiêu đề + nút menu
├── Body
│   └── PageView    → 3 danh mục món
│       └── GridView → thẻ món (Card + InkWell)
├── bottomSheet     → giỏ hàng persistent
└── FAB             → demo showBottomSheet
```

**Luồng người dùng:**
1. Xem danh mục (PageView)
2. Chọn món (tap card)
3. Xem chi tiết + số lượng (Modal Sheet)
4. Thêm giỏ → thanh dưới (Persistent)
5. Mở menu (Drawer) → chuyển section khác

**File chính:** `lib/features/group3_demo/group3_food_demo_screen.dart`

---

### Slide 14 — Tích hợp Bottom Sheet vào Case Study

**Tiêu đề slide:**
> Bottom Sheet trong luồng đặt món

**Nội dung — Hai vai trò:**

| Bước | Widget | Hành vi |
|------|--------|---------|
| Chọn món | **Modal Sheet** | Chi tiết, +/- qty, xác nhận thêm |
| Sau khi thêm | **Persistent `bottomSheet`** | Hiện tổng giỏ, không chặn lưới món |
| Demo thêm | **FAB → `showBottomSheet`** | Minh họa API persistent động |

**Điểm kỹ thuật:**
- Modal dùng `StatefulBuilder` — state qty cục bộ
- Thêm giỏ gọi `setState` parent + `Navigator.pop` đóng modal
- `bottomSheet:` rebuild khi `_cartCount` thay đổi

**Demo live (2 phút):** Chạy full flow từ vuốt danh mục → chọn món → thêm 2 món → xem giỏ persistent

---

### Slide 15 — Tổng kết & Q&A

**Tiêu đề slide:**
> Tổng kết & Q&A

**Nội dung tổng kết:**

| Widget | Khi nào dùng | API chính |
|--------|--------------|-----------|
| **PageView** | Nhiều trang full-screen, vuốt snap | `PageView.builder`, `PageController` |
| **Modal Sheet** | Hành động tạm, form, xác nhận | `showModalBottomSheet` |
| **Persistent Sheet** | UI cố định dưới cùng | `bottomSheet:`, `showBottomSheet` |
| **Drawer** | Menu điều hướng phụ | `Scaffold.drawer`, `openDrawer()` |

**Điểm nhấn nhóm 3:**
- Demo chạy được trong Mobiapp (icon Food Demo)
- Code tuân theme A05 (`AppColors`, `AppTextStyles`, `AppSpacing`)
- Bonus: GridView, Slivers, Nested ListView trong Drawer tabs

**Q&A — Câu hỏi thường gặp:**
- *PageView vs TabBar?* → TabBar có tab header; PageView chỉ vuốt nội dung
- *Modal vs Dialog?* → Sheet từ dưới, phù hợp mobile thumb zone
- *Drawer vs NavigationRail?* → Drawer cho mobile; Rail cho tablet/desktop

**Lời kết:**
> Cảm ơn thầy/cô. Nhóm 3 sẵn sàng trả lời câu hỏi và demo lại trên app.

---

## Phụ lục — Timeline trình bày (15 phút)

| Phút | Slide | Hành động |
|------|-------|-----------|
| 0–2 | 1–3 | Giới thiệu, vấn đề, mục tiêu |
| 2–5 | 4–6 | Lý thuyết PageView + **demo vuốt** |
| 5–8 | 7–9 | So sánh Sheet + **demo modal & giỏ** |
| 8–11 | 10–12 | Drawer + **demo menu** |
| 11–14 | 13–14 | **Full flow** đặt món |
| 14–15 | 15 | Tổng kết + Q&A |

## Phụ lục — Map file code

| Slide | File |
|-------|------|
| 5–6, 13–14 | `lib/features/group3_demo/group3_food_demo_screen.dart` |
| 12 (bonus) | `lib/features/group3_demo/a07_widget_sections.dart` |
| PageView (Home iOS) | `lib/features/home_ios/presentation/pages/ios_home_screen.dart` |
