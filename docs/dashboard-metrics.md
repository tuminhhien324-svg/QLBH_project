# Định Nghĩa Chỉ Số (Dashboard Metrics) - HP STORE

Tài liệu này xác định cách tính toán các chỉ số trên Dashboard, nhằm đảm bảo Frontend và Backend đồng nhất về mặt số liệu. Các chỉ số này **phải luôn được lọc** theo `organization_id`, `branch_id` (nếu có chọn) và khung thời gian (`date_from`, `date_to`).

## 1. Doanh Thu (Revenue)
- **Định nghĩa**: Tổng số tiền thu được từ việc bán hàng (đã trừ chiết khấu), không bao gồm doanh thu từ các đơn đã hủy hoặc trả lại.
- **Trạng thái hợp lệ**: Chỉ tính các đơn hàng có trạng thái `COMPLETED` (Đã hoàn tất) hoặc `PAID` (Đã thanh toán).
- **Công thức**: `SUM(total_amount)` của các đơn hàng thỏa mãn điều kiện.
- **Lưu ý**: Thuế (Tax) và Phí vận chuyển (Shipping Fee) nếu có sẽ được tách riêng trong báo cáo chi tiết, nhưng tổng doanh thu tổng quan sẽ hiển thị dựa trên `total_amount` khách thực trả.

## 2. Số Đơn Hàng (Order Count)
- **Định nghĩa**: Tổng số lượng đơn hàng được tạo trong kỳ.
- **Trạng thái hợp lệ**: Tất cả trạng thái ngoại trừ `DRAFT` (Nháp) và `CANCELLED` (Đã hủy).
- **Công thức**: `COUNT(order_id)`.

## 3. Khách Hàng Mới (New Customers)
- **Định nghĩa**: Số lượng khách hàng được tạo mới (đăng ký) trong kỳ báo cáo tại chi nhánh/tổ chức hiện tại.
- **Công thức**: `COUNT(customer_id)` có `created_at` nằm trong khung thời gian lọc. Tránh đếm trùng số điện thoại/email trong cùng tổ chức.

## 4. Lợi Nhuận Gộp (Gross Profit)
- **Định nghĩa**: Doanh thu thuần trừ đi giá vốn hàng bán (COGS).
- **Công thức**: `SUM(line_total) - SUM(quantity * unit_cost_snapshot)` trên bảng `sales_order_items` của các đơn hoàn tất.
- **Lưu ý**: Chỉ dùng từ "Lợi nhuận gộp", tuyệt đối không dùng "Lợi nhuận ròng" vì chưa trừ các chi phí vận hành (Mặt bằng, Lương, Marketing...).

## 5. Giá Trị Tồn Kho (Inventory Value)
- **Định nghĩa**: Tổng giá trị hàng hóa hiện đang nằm trong các kho (của chi nhánh đang chọn).
- **Phương pháp tính giá vốn**: Sử dụng `cost_price` trung bình hoặc định danh tùy cấu hình, mặc định nhân số lượng tồn thực tế.
- **Công thức**: `SUM(quantity_on_hand * cost_price)`.
- **Trạng thái**: Loại trừ các kho Hàng lỗi (`DAMAGED`), chỉ tính `STORE` và `CENTRAL`.

## 6. Top Sản Phẩm (Top Products)
- **Tiêu chí xếp hạng**: Xếp theo "Tổng Doanh Thu" hoặc "Số Lượng Bán Ra".
- **Trạng thái đơn hàng**: Chỉ lấy từ các đơn hàng hợp lệ (`COMPLETED`, `PAID`).
- **Xử lý hoàn hàng**: Nếu có trả hàng, số lượng và doanh thu phải bị trừ ngược lại trong báo cáo.

## 7. So Sánh Kỳ (Period Comparison)
- **So sánh cùng kỳ trước đó**: (Ví dụ: 7 ngày qua so với 7 ngày trước đó).
- Cần tính cả % thay đổi (Tăng/Giảm) trên Dashboard.
- **Múi giờ**: Chốt xử lý ngày giờ ở múi giờ `Asia/Ho_Chi_Minh` để tránh sai lệch báo cáo giữa ca đêm và ca ngày.
