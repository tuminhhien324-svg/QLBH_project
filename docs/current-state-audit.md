# Bản Khảo Sát Hiện Trạng (Current State Audit) - HP STORE / QLBH

## 1. Cấu Trúc Hệ Thống Hiện Tại
- **Frontend**: Dự án dùng Vanilla Javascript (Vite) + Bootstrap + Chart.js, các trang chia theo dạng file HTML tĩnh (`.html`) trong thư mục `client/src/pages/`.
- **Backend**: Node.js + Express + PostgreSQL. Sử dụng kiến trúc MVC với các lớp `controllers`, `models`, `routes`.
- **Database**: PostgreSQL (kết nối qua file config `database.js`), các bảng thiết kế dạng tiếng Việt (nguoidung, khachhang, donhang, sanpham, v.v.).

## 2. Bản Đồ Hiện Trạng (Mapping)

### 2.1 Các bảng Database chính đang hoạt động:
- `nguoidung`: Tài khoản nhân viên/quản trị, phân quyền sơ khai (`mavaitro`).
- `khachhang`: Lưu thông tin khách (chưa tích hợp multi-branch).
- `danhmuc`, `sanpham`: Quản lý danh mục và thông tin sản phẩm (`masp`, `soluongton`).
- `donhang`, `chitiet_donhang`: Xử lý bán hàng/đặt hàng.
- `nhacungcap`: Danh sách NCC.
- `giaodichkho`: Lịch sử xuất/nhập, ghi nhận số dư tồn kho trước/sau (`tontruoc`, `tonsau`).

### 2.2 Các Endpoint / Controllers:
- `authRoutes`, `userRoutes`: Đăng nhập, đăng ký, quên mật khẩu (OTP).
- `productRoutes`, `productManagerRoutes`: API sản phẩm.
- `orderRoutes`, `orderHistoryRoutes`, `checkoutRoutes`: Luồng mua bán.
- `warehouseRoutes`: Quản lý giao dịch kho. Đã áp dụng `BEGIN/COMMIT` và `SELECT ... FOR UPDATE` khi xuất/nhập, nhưng cấu trúc chỉ cho một kho chung.
- `thongkeRoutes`: Phục vụ dashboard, tính tổng doanh thu, khách hàng mới...

### 2.3 Frontend UI:
- Màn hình chính: `tong-quan.html`, `dashboard.html`.
- Các trang quản lý: `san-pham.html`, `don-hang.html`, `khach-hang.html`, `quanly-khohang.html`, `quanly-nhanvien.html`.

## 3. Lỗ Hổng / Điểm Thiếu Sót (Gap Analysis)
- **Thiếu Multi-tenant & Branching**: Không có khái niệm Tổ chức (`organization`) và Chi nhánh (`branch`), mọi dữ liệu đang thuộc về một thực thể bán lẻ duy nhất.
- **Kiểm Soát Tồn Kho**: Tồn kho (`soluongton`) đang nằm chung trên bảng `sanpham`. Chưa phân tách tồn kho theo từng chi nhánh, cũng như chưa tách biệt giữa Hàng chờ xuất (Reserved) và Hàng khả dụng (Available).
- **Phân Quyền (RBAC)**: Đang dựa vào cột `mavaitro` cứng trong bảng `nguoidung`, chưa có mô hình Phân quyền động chi tiết (Role - Permission).
- **Định nghĩa KPI**: Truy vấn thống kê (trong `thongKeModel`) có thể chưa loại trừ các đơn hàng Đã hủy/Trả hàng một cách chặt chẽ.
- **UI/UX**: Dashboard chưa có bộ lọc chi nhánh/kho, responsive có thể bị vỡ với các bảng dữ liệu lớn.

## 4. Kế Hoạch Ưu Tiên Nâng Cấp (Priority Plan)
1. **P0 (Critical)**: Thống nhất định nghĩa Metric/KPI. Chuẩn bị tài liệu Migration DB từ schema tiếng Việt (cũ) sang schema Multi-branch chuẩn tiếng Anh.
2. **P1 (High)**: Xây dựng cơ sở hạ tầng Backend (Organization, Branch, Users), cập nhật Middleware chặn quyền theo Chi nhánh.
3. **P2 (Medium)**: Tái cấu trúc logic Tồn Kho (Inventory Ledger) và Luồng Đặt hàng (Order/Checkout) để hỗ trợ Multi-branch.
4. **P3 (Low/UI)**: Cập nhật giao diện Dashboard, đảm bảo responsive tốt và kết nối các bộ lọc mới (Chi nhánh, Kênh bán).
