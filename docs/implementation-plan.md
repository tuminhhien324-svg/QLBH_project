# Kế Hoạch Triển Khai (Implementation Plan) - Nâng Cấp HP STORE / QLBH

Dựa trên kết quả khảo sát (Phase 0) và yêu cầu nâng cấp, lộ trình dưới đây được thiết lập để chuyển đổi hệ thống sang mô hình bán lẻ Đa Chi Nhánh (Multi-branch) với kiến trúc Modular Monolith.

## Mục Tiêu Cốt Lõi
- Đảm bảo tính đúng đắn của dữ liệu: Áp dụng Transaction khi xử lý Kho/Đơn hàng.
- Mở rộng Multi-tenant/Branching: Các truy vấn phải giới hạn dữ liệu theo chi nhánh tương ứng.
- Giữ tương thích ngược (Backward Compatibility) cao nhất có thể hoặc cung cấp bản Migration an toàn để không làm mất dữ liệu hiện tại.

---

## Phase 0: Audit & Foundation Planning (Đã Hoàn Thành)
- Đã đọc code repository.
- Đã lập tài liệu khảo sát hiện trạng `docs/current-state-audit.md`.
- Đã lập định nghĩa các chỉ số báo cáo `docs/dashboard-metrics.md`.

## Phase 1: Foundation (Cơ sở dữ liệu và Phân Quyền)
- **Database Migration**: Áp dụng file schema chuẩn (`QLBH_PostgreSQL_MultiBranch_v1.sql`) vào Database test/mới. Tạo script mapping chuyển dữ liệu từ các bảng cũ sang bảng mới.
- **Organization & Branch Scope**: Sửa file kết nối Database và tạo Middleware chặn quyền (`organization_id`, `branch_id`).
- **RBAC**: Thiết lập Role & Permission, gắn middleware xác thực vào các Endpoint quan trọng.

## Phase 2: Data Correctness (Thống Nhất Dữ Liệu Báo Cáo)
- **Chỉnh sửa Dashboard API**: Viết lại Query SQL để tính toán Doanh Thu, Số Đơn, Khách hàng, Lợi nhuận đúng định nghĩa trong `dashboard-metrics.md`.
- **Test Baseline**: Bơm dữ liệu mẫu và chạy script test xem các số liệu Dashboard trả về có chính xác với SQL hay không.

## Phase 3: UI/UX Dashboard
- **Tối ưu Layout**: Sửa file `dashboard.html` / `tong-quan.html` để có spacing, cards, biểu đồ đúng thiết kế.
- **Tích hợp Filter Thực**: Hoàn thiện các nút lọc Ngày, Chi Nhánh, Kênh Bán hoạt động trơn tru.
- **Trạng Thái Hiển Thị**: Thêm Skeleton loading, Empty state, Error state cho các API trả về chậm/lỗi.

## Phase 4: Multi-Branch Inventory (Quản Lý Tồn Kho Nâng Cao)
- **Refactor Tồn Kho**: Tách dữ liệu `soluongton` trong bảng `sanpham` cũ ra bảng `inventory_balances` (theo từng kho).
- **Inventory Ledger**: Xây dựng lại logic giao dịch kho (`giaodichkho` -> `inventory_movements`), xử lý Lock `SELECT ... FOR UPDATE` khi cập nhật kho để tránh Race Condition.

## Phase 5: Sales Operations (Nghiệp Vụ Bán Hàng)
- **Tách Luồng Bán Hàng**: Quản lý giỏ hàng, Thanh toán, Hóa Đơn và Trả Hàng (nếu có).
- Bổ sung Transaction xuyên suốt cho toàn bộ quá trình Thanh toán -> Trừ Kho -> Tạo Đơn Hàng.

## Phase 6 & 7: Forecasting, BI & Release
- Tích hợp số liệu cảnh báo Tồn Kho trên Dashboard (Dưới ngưỡng, Hết hàng).
- Review Security, thử nghiệm Migration lần cuối và tiến hành Deploy.
