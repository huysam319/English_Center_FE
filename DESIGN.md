---
# 1. LAYER TOKENS (YAML FRONT MATTER)
brand: "English Center FE"
theme: "Light"
tokens:
  colors:
    primary: "#1E40AF"
    primary_hover: "#dd1e40b0"
    background_page: "#F1F5F9"
    background_section: "#F1F3F4"
    surface: "#FFFFFF"
    text_primary: "#000000"
    text_secondary: "#363740"
    border: "#E0E0E0"
    divider: "#8E8D8D"
    notification_badge: "#3C19C0"
    success: "#1624a3"
    warning: "#F59E0B"
    error: "#EF4444"
  typography:
    font_family_sans: "Inter, sans-serif"
    base_size: "14px"
    scale:
      h1: "2rem"
      h2: "1.5rem"
      h3: "1.125rem"
      body: "0.875rem"
      small: "0.75rem"
  spacing:
    unit: "4px"
    scale: [4, 8, 12, 16, 20, 24, 32, 40, 48, 50]
  borders:
    radius_sm: "4px"
    radius_md: "12px"
    radius_lg: "14px"
  shadows:
    soft: "0 10px 20px rgba(0, 0, 0, 0.05)"
  motion:
    duration_fast: "120ms"
    duration_base: "180ms"
    duration_slow: "240ms"
    easing_standard: "cubic-bezier(0.2, 0, 0, 1)"
    easing_emphasized: "cubic-bezier(0.2, 0.8, 0.2, 1)"
  layout:
    medium_breakpoint: "768px"
    large_breakpoint: "1366px"
---

# 2. LAYER NGỮ CẢNH (MARKDOWN BODY)

## Brand Identity & Aesthetic
Project này dùng ngôn ngữ giao diện hiện đại, thực dụng và rõ ràng, ưu tiên khả năng học tập và quản trị hơn là hiệu ứng trang trí. Tổng thể là light UI với nền xám rất nhạt, thẻ trắng, bóng đổ nhẹ và màu nhấn xanh đậm để biểu thị trạng thái active, hành động chính, và tiêu đề điều hướng.

Ứng dụng được thiết kế như một hệ thống quản lý trung tâm tiếng Anh, nên UI phải cân bằng giữa hai nhóm trải nghiệm:
* **Học viên**: thao tác nhanh, đọc nội dung rõ, làm bài/quiz/test tập trung.
* **Giáo viên / quản trị**: nhiều bảng dữ liệu, form nhập liệu, quản lý lớp, đề thi, câu hỏi, chấm điểm.

## Visual Direction
* **Phong cách chính**: sạch, phẳng, bo góc vừa phải, ít chi tiết thừa.
* **Màu chủ đạo**: xanh dương đậm `#1E40AF`.
* **Nền**: page background dùng xám xanh rất nhạt; content blocks thường là trắng.
* **Nhịp điệu thị giác**: dùng khoảng trắng rõ ràng thay vì viền nặng hoặc gradient lớn.
* **Cảm xúc tổng thể**: tin cậy, nhẹ nhàng, học thuật, chuyên nghiệp nhưng không khô cứng.

## Visual Accents
* Dùng gradient rất nhẹ hoặc tint xanh mờ ở hero area, empty state, hoặc header của dashboard để tạo chiều sâu mà không phá sự sạch sẽ.
* Icon nên đồng bộ theo một ngôn ngữ nét đơn giản, ưu tiên outline icons cho điều hướng và action icons.
* Badge, chip, và trạng thái nên dùng dạng pill nhỏ, đổ màu vừa đủ để đọc nhanh.
* Empty state nên có illustration hoặc icon minh họa tối giản, tránh để khung trống lạnh và nặng.

## Shell & Navigation
* App chạy theo mô hình **router-driven shell**: `Top Nav` ở trên, `Side Menu` bên trái khi màn hình lớn, và nội dung chính ở bên phải.
* `Top Nav` dùng nền trắng, có đường phân cách mảnh ở đáy, logo ở trái, title ở giữa-trái, và các action icon ở phải.
* `Side Menu` thay đổi theo vai trò (`ROLE_STUDENT`, `ROLE_TEACHER`, `ROLE_ADMIN`) và đánh dấu trạng thái active bằng nền xanh đậm.
* Trên màn hình nhỏ, layout ưu tiên nội dung chính; drawer được dùng cho menu.

## Color Principles
### Primary Colors
* **Primary** `#1E40AF` dùng cho active state, nút chính, tab đang chọn, heading row của bảng, và các component quan trọng.
* **Primary hover** là phiên bản đậm nhẹ/pha alpha của primary, dùng khi hover trên menu hoặc button.

### Neutral Colors
* **Surface** `#FFFFFF` là nền của card, login panel, top bar, và nhiều khối nội dung.
* **Page background** `#F1F5F9` và **section background** `#F1F3F4` dùng để tách lớp giao diện.
* **Border / divider** giữ ở mức rất nhẹ (`#E0E0E0`, `#8E8D8D`) để không làm rối bố cục.

### Feedback Colors
* **Error** dùng đỏ chuẩn của Material cho validation và trạng thái lỗi.
* **Notification badge** dùng tím/xanh tím `#3C19C0` như một điểm nhấn nhỏ, không phải màu chủ đạo.

## Typography Guidelines
* Font mặc định của UI là **Inter** qua `GoogleFonts.inter`.
* Tiêu đề lớn ở màn hình auth/account thường ở mức `32px`, weight `Bold`.
* Title trên top nav ở mức `18px`, weight `Bold`.
* Menu item, tab, form label, và button text thường ở mức `14px` với weight `Medium` hoặc `SemiBold`.
* Text nên ưu tiên đen hoặc xám đậm; chỉ dùng màu xanh cho trạng thái active hoặc CTA.

## Component Guidelines
### Buttons
* Nút chính thường là `ElevatedButton` phẳng, không đổ bóng, bo góc `12px` hoặc `14px`.
* Kích thước chạm tối thiểu nên giữ quanh `48px` chiều cao.
* Button active trong side menu đổi sang nền `#1E40AF` và chữ trắng.
* Button phụ hoặc tab chọn trạng thái inactive thường dùng nền xám nhạt.

### Forms
* Input field dùng `OutlineInputBorder` với radius `12px`.
* Form trên auth/account page đặt trong container trắng, padding rộng, shadow nhẹ.
* Validation text hiển thị ngay dưới field và không thay đổi layout quá mạnh.
* Password field có icon toggle visibility ở suffix icon.

### Cards & Panels
* Card/panel chuẩn là nền trắng, radius `12px`, shadow mềm.
* Khoảng đệm trong panel thường là `24px`.
* Các block lớn như login hoặc update account nên canh giữa và giới hạn chiều rộng để dễ đọc.

### Side Menu
* Menu item dùng radius `14px`.
* Item active có nền xanh đậm; item phụ trong group có padding thụt vào để thể hiện cấp bậc.
* Group menu mở rộng mặc định, có animation ngắn `200ms`.
* Icon và label phải luôn đủ tương phản để đọc nhanh khi người dùng quét menu.

### Tabs / Pagination
* Tab trạng thái active dùng nền xanh đậm, inactive dùng nền xám nhạt.
* Pagination dùng nút viền mảnh, radius nhỏ `4px`, active state đảo màu rõ ràng.
* Cấu trúc này phù hợp với giao diện quản trị nhiều bảng dữ liệu.

### Tables
* Bảng là một trong những thành phần chủ đạo cho admin/teacher flows.
* Header row thường dùng màu nhấn xanh đậm.
* Table nên giữ spacing thoáng, hàng rõ ràng, tránh border quá dày.

## Layout Rules
* Màn hình lớn: side menu cố định bên trái, content bên phải.
* Màn hình nhỏ: ưu tiên content; drawer thay cho sidebar.
* Breakpoint quan trọng đang được dùng trong code là `768px` và `1366px`.
* Nội dung chính nên có khoảng thở đủ lớn, đặc biệt ở các page nhập liệu và quản trị.

## Interaction Patterns
* Trạng thái active phải luôn nhìn ra ngay bằng màu xanh đậm.
* Hover nên tinh tế, không làm thay đổi bố cục.
* Điều hướng chủ yếu qua router path; người dùng cần ít thao tác nhất để chuyển module.
* Với các page dữ liệu dài, nên kết hợp bảng, pagination, và nút hành động rõ ràng.

## Motion Principles
* Animation phải phục vụ việc hiểu giao diện, không phải để trình diễn.
* Chỉ dùng motion ngắn, mượt, và nhất quán trên toàn app.
* Ưu tiên fade, slide nhẹ, scale rất nhỏ, và color transition; tránh chuyển động quá lớn hoặc quá nhanh.
* Mọi animation cần giữ cảm giác ổn định, đặc biệt trong màn hình học tập và quản trị có nhiều dữ liệu.

### Motion Tokens
* **Duration fast** `120ms`: hover, icon toggle, highlight nhẹ.
* **Duration base** `180ms`: menu expand/collapse, tab switch, button state.
* **Duration slow** `240ms`: page reveal, panel entrance, modal open.
* **Easing standard**: dùng cho đa số tương tác thường ngày.
* **Easing emphasized**: dùng khi cần cảm giác mềm hơn cho panel hoặc hero transition.

### Motion Recipes
* **Page enter**: fade in kết hợp slide lên nhẹ 8-12px.
* **Menu expand/collapse**: height + opacity transition với timing ngắn, không giật.
* **Hover state**: đổi màu nền hoặc nâng nhẹ bằng shadow, tránh scale lớn.
* **Loading**: ưu tiên skeleton hoặc shimmer nhẹ cho bảng và danh sách; spinner chỉ dùng khi nội dung thật sự ngắn.
* **Success feedback**: toast ngắn, icon check nhỏ, hoặc color pulse rất nhẹ.
* **Empty state**: fade in illustration hoặc message card thay vì chỉ để trắng trống.

## Page-Specific Notes
### Authentication
* Login page dùng panel trắng giữa màn hình, nền xám nhạt, tiêu đề lớn và CTA rõ ràng.
* Có nhánh đăng nhập nội bộ và đăng nhập OAuth, nên hai nút hành động phải phân biệt rõ primary/secondary.
* Có thể thêm animation nhẹ cho card xuất hiện và button hover để khu vực này “ấm” hơn.

### Profile & Account
* Profile/account page dùng layout clean, nhiều dòng thông tin dạng label-value.
* Tab ở đây là thành phần điều hướng phụ, không nên quá nổi so với nội dung.
* Các field và block nên có transition nhẹ khi chuyển tab hoặc cập nhật dữ liệu.

### Learning / Test / Exercise
* UI cho học viên cần ưu tiên khả năng đọc và làm bài liên tục.
* Các widget như countdown, answer box, flashcard, dropzone, và review screens nên giữ tương tác trực tiếp, rõ ràng, ít nhiễu.
* Với flashcard hoặc quiz, có thể dùng flip, reveal, hoặc highlight motion rất ngắn để tăng cảm giác tương tác.

### Admin / Teacher Management
* Các màn hình quản trị chủ yếu là table, filter, form tạo mới, và detail view.
* Nên giữ spacing thống nhất, button nhóm rõ, và trạng thái selected phải nhất quán trên mọi module.
* Nên ưu tiên animation trạng thái hơn là animation trang trí, vì các màn này cần đọc dữ liệu nhanh.

## State Hierarchy
* **Default**: nền trắng hoặc xám nhạt, text đen/xám đậm.
* **Hover**: thêm tint nhẹ hoặc shadow mềm, không đổi kích thước quá nhiều.
* **Active**: màu xanh đậm, tương phản rõ.
* **Focused**: outline rõ và có thể thấy trên keyboard navigation.
* **Disabled**: giảm opacity và giảm độ tương phản nhưng vẫn đủ nhận diện.
* **Loading**: giữ khung layout cố định để tránh layout shift.
* **Empty**: dùng card rỗng có minh họa hoặc thông điệp rõ ràng.

## Design Summary
Tóm lại, hệ thống giao diện của project này là một **light enterprise UI**: màu xanh đậm làm trục chính, trắng và xám nhạt làm nền, Inter làm font mặc định, bo góc vừa phải, và shadow rất nhẹ. Tất cả component nên ưu tiên tính rõ ràng, khả dụng, và khả năng đọc dữ liệu nhanh trên cả desktop lẫn màn hình nhỏ.