# PROMPT CHÍNH — NÂNG CẤP UI/UX + BACKEND HP STORE / QLBH

Bạn là Senior Product Designer, Senior Full-stack Engineer và Software Architect. Hãy làm việc trực tiếp trên repository QLBH_project hiện tại. Mục tiêu là nâng cấp hệ thống quản lý bán hàng HP STORE thành nền tảng bán lẻ có thể mở rộng nhiều chi nhánh, tham khảo quy mô nghiệp vụ của các chuỗi bán lẻ lớn, nhưng không sao chép thương hiệu/giao diện độc quyền của bất kỳ bên nào.

## NGUYÊN TẮC BẮT BUỘC
1. Đọc README, toàn bộ cấu trúc client/server, package.json, routes, controllers, models, middleware, SQL/schema và luồng UI trước khi sửa.
2. Không xóa hoặc viết lại toàn bộ dự án chỉ để làm đẹp. Không đổi framework, không đổi tên endpoint/field hiện có nếu chưa có adapter tương thích.
3. Tạo branch Git riêng và commit/backup trước khi sửa. Không sửa file .env, không in secrets, không đưa thông tin kết nối vào source control.
4. Lập bảng hiện trạng: chức năng, endpoint, bảng DB, file UI, trạng thái (Đang hoạt động/Thiếu/Chưa xác minh). Nêu rõ phát hiện có bằng chứng và giả thuyết cần kiểm chứng.
5. Thực hiện theo từng phase nhỏ; sau mỗi phase chạy lint/build/test hiện có, kiểm tra diff và báo file đã đổi. Không tự tuyên bố test pass nếu chưa chạy.
6. Database hiện tại có thể đang dùng PostgreSQL/Neon. Không chạy schema mới trực tiếp lên production. Viết migration có backup/rollback, mapping schema cũ sang schema mới và giữ tương thích ngược cho API.
7. Mọi nghiệp vụ ghi dữ liệu quan trọng phải dùng transaction, kiểm soát concurrency, validation phía server, authorization và audit log. Không tin dữ liệu tổng tiền/tồn kho do frontend gửi.

## A. UI/UX — DASHBOARD DESKTOP FIRST, RESPONSIVE
- Giữ nhận diện HP STORE, màu sắc hiện có nếu hợp lý; giao diện chuyên nghiệp, gọn, dễ đọc, phù hợp hệ thống quản trị bán lẻ.
- Tận dụng chiều rộng màn hình: ở desktop dùng padding ngang khoảng 20–32px; tránh max-width nhỏ làm dashboard bị bó hẹp; nội dung nên chiếm phần lớn viewport nhưng vẫn có khoảng thở hợp lý.
- Header, thanh điều hướng, breadcrumb và bộ lọc có thứ bậc rõ. Giữ menu hiện tại và không làm mất liên kết.
- KPI đặt cùng một hàng trên desktop khi đủ chỗ; card đồng nhất chiều cao, số liệu lớn, label ngắn, có đơn vị, kỳ so sánh và trạng thái loading/empty/error.
- Hàng biểu đồ doanh thu/đơn hàng: ưu tiên doanh thu khoảng 65–70%, đơn hàng 30–35%. Hàng danh mục/top sản phẩm: bố cục cân bằng; tiêu đề và loại biểu đồ phải nhất quán.
- Biểu đồ đủ cao để đọc nhãn, có tooltip, định dạng VND/đơn vị, trục không gây hiểu nhầm, legend rõ. Tránh cắt hình, tràn chữ, khoảng trắng lớn không cần thiết.
- Các bộ lọc ngày, chi nhánh, kho, kênh bán và tiêu chí Top sản phẩm phải hoạt động thực sự; không để dropdown chỉ đổi giao diện nhưng không đổi dữ liệu.
- Bổ sung skeleton loading, empty state, error state, nút thử lại; không để skeleton quay mãi khi API lỗi. Tránh vẽ lại chart chồng canvas; hủy chart cũ trước khi tạo chart mới.
- Responsive: desktop 1440px, laptop 1280px, tablet 768px, mobile 360–430px. KPI tự xuống hàng; bảng có scroll hoặc card layout; không có horizontal overflow toàn trang.
- Accessibility: contrast đủ, focus-visible, label cho form, keyboard navigation, trạng thái không chỉ dùng màu.
- Không dùng dữ liệu giả để thay thế API thật. Nếu endpoint chưa có, hiển thị “Chưa có dữ liệu/API chưa sẵn sàng” và ghi rõ việc cần làm.
- Không tạo animation gây rối; chỉ dùng transition ngắn cho hover/loading.

## B. DASHBOARD — ĐỊNH NGHĨA SỐ LIỆU
Trước khi code, lập tài liệu `docs/dashboard-metrics.md` định nghĩa cho từng KPI:
- Doanh thu: xác định theo đơn hoàn tất/đã thanh toán hay hóa đơn hợp lệ; loại trừ đơn hủy, xử lý hoàn tiền/đổi trả.
- Số đơn: định nghĩa trạng thái nào được tính.
- Khách hàng mới: ngày tạo khách hàng, phạm vi tổ chức/chi nhánh và cách tránh đếm trùng.
- Lợi nhuận gộp: doanh thu thuần trừ giá vốn của hàng đã bán; không gọi là lợi nhuận ròng nếu chưa trừ chi phí vận hành.
- Giá trị tồn kho: số lượng khả dụng/tồn thực tế nhân giá vốn; nêu rõ phương pháp giá vốn (bình quân/FIFO) và phạm vi kho.
- Top sản phẩm: tiêu chí doanh thu hoặc số lượng; loại trừ đơn hủy, tính đổi trả rõ ràng.
- So sánh kỳ: cùng độ dài kỳ, timezone Asia/Ho_Chi_Minh, xử lý kỳ chưa kết thúc.
- KPI và biểu đồ phải dùng chung định nghĩa, cùng filter organization/branch/date/channel.

## C. NGHIỆP VỤ BACKEND CẦN ĐÁNH GIÁ VÀ BỔ SUNG
Thực hiện audit gap, không tự động tạo tất cả nếu chưa thiết kế:
1. Multi-tenant/organization: organization_id trên dữ liệu nghiệp vụ, không cho tổ chức A truy cập dữ liệu tổ chức B.
2. Chi nhánh và kho: quản lý chi nhánh, nhiều kho/chi nhánh, phân quyền theo phạm vi; chi nhánh mặc định.
3. RBAC: role/permission rõ, middleware bắt buộc trên API quản trị, kiểm tra quyền ở server.
4. Product catalog: danh mục cha-con, thương hiệu, SKU/variant, barcode, serial/IMEI cho thiết bị điện tử nếu cần, bảo hành.
5. Inventory ledger: tồn theo kho, tồn giữ chỗ, tồn khả dụng, lô/serial nếu cần, lịch sử nhập/xuất/điều chỉnh, cảnh báo dưới ngưỡng/hết hàng/sắp hết hạn/tồn lâu.
6. Purchase: nhà cung cấp, đơn đặt mua, duyệt đơn, nhận hàng từng phần, công nợ nhà cung cấp nếu scope yêu cầu.
7. Sales/POS: tạo đơn, giữ hàng, thanh toán nhiều phương thức, hóa đơn, hủy/hoàn/đổi hàng, idempotency, transaction.
8. Transfer: yêu cầu chuyển kho, duyệt, xuất kho nguồn, đang vận chuyển, xác nhận nhận kho đích, đối soát thiếu/hỏng.
9. Pricing/promotions: lịch hiệu lực giá, mã giảm giá, điều kiện áp dụng, giới hạn lượt, không tin giá frontend.
10. Demand planning: forecast theo SKU/chi nhánh/ngày; điểm đặt hàng lại, safety stock, lead time nhà cung cấp; giải thích dự báo là ước lượng, đo sai số mô hình.
11. Dashboard/BI: lọc theo ngày, tổ chức, chi nhánh, kho, kênh; doanh thu thuần, đơn, AOV, gross margin, tồn kho theo giá vốn, sell-through, stockout, dead stock, top/bottom SKU.
12. Audit/security: audit log, rate limit, input validation, parameterized SQL, CORS, secrets, TLS, refresh/expiry token, reset password, chống lộ dữ liệu cá nhân.
13. Observability/operations: log có correlation ID, health endpoint, error handling, backup/restore, migration, monitoring, test.
14. Integration: API contracts, OpenAPI/Swagger, pagination/filter/sort chuẩn, versioning, webhook/payment provider khi thực sự tích hợp.

## D. KIẾN TRÚC
- Không tách microservices quá sớm. Ưu tiên modular monolith Node.js/Express + PostgreSQL, các module độc lập: Auth, Organization/Branch, Catalog, Inventory, Purchasing, Sales/Orders, Payments, Promotions, Dashboard/BI, Audit.
- Dùng transaction và `SELECT ... FOR UPDATE` hoặc chiến lược concurrency phù hợp khi cập nhật tồn kho.
- Sử dụng UUID/PK nhất quán, FK, CHECK, UNIQUE, index theo query; tiền dùng NUMERIC/DECIMAL, thời gian dùng TIMESTAMPTZ; timezone nghiệp vụ Asia/Ho_Chi_Minh.
- Không để trường `quantity_on_hand` bị sửa trực tiếp từ nhiều luồng mà không có inventory movement tương ứng.
- Nếu phải giữ schema cũ (ví dụ `sanpham`, `donhang`, `chitiet_donhang`, `hoadon`), tạo migration + compatibility view/adapter; không đổi tên bảng hàng loạt trong một lần.
- Dự báo nhu cầu là phase sau khi đủ lịch sử bán hàng, dữ liệu tồn, lead time và ngày thiếu hàng; không hứa độ chính xác nếu chưa đo.

## E. QUY TRÌNH LÀM VIỆC VÀ ĐẦU RA
Phase 0 — Audit: báo cáo hiện trạng, endpoint/file/table map, lỗi P0/P1/P2, sơ đồ luồng, test baseline.
Phase 1 — Foundation: migration/backup plan, organization/branch scope, RBAC, validation, error handling, audit.
Phase 2 — Data correctness: thống nhất KPI; sửa các query doanh thu, đơn hàng, top sản phẩm; test bằng dữ liệu mẫu và đối chiếu SQL.
Phase 3 — UI Dashboard: tối ưu spacing, cards/charts, filter thực, loading/empty/error, responsive; giữ API hiện tại qua adapter.
Phase 4 — Multi-branch inventory: tồn theo kho, movements, transfer, purchase receipt, reserve/release, stock alerts.
Phase 5 — Sales operations: payments, invoice, returns/exchanges, promotions, warranty/serial nếu scope xác nhận.
Phase 6 — Forecasting/BI: chỉ sau khi dữ liệu đủ; baseline đơn giản trước ML; dashboard sai số dự báo.
Phase 7 — Release: regression test, security review, migration rehearsal, backup/rollback, deploy staging rồi production.

Bắt buộc tạo/duy trì:
- `docs/current-state-audit.md`
- `docs/dashboard-metrics.md`
- `docs/target-architecture.md`
- `docs/database-migration-plan.md`
- `docs/api-contracts.md`
- `docs/implementation-plan.md`
- tests cho các luồng bán hàng/tồn kho/KPI.
- Bảng mapping schema cũ → schema đích; mỗi migration có cách rollback hoặc giải thích nếu không thể rollback tự động.

## F. ĐIỀU KIỆN NGHIỆM THU
- Build frontend và backend tests chạy thành công, báo chính xác lệnh/kết quả.
- Không có endpoint quản trị nhạy cảm thiếu authentication/authorization.
- Không thể xem/sửa dữ liệu của tổ chức/chi nhánh ngoài phạm vi user.
- Hủy đơn không hoàn kho hai lần; chuyển kho không tạo tồn âm; thao tác đồng thời không oversell.
- KPI khớp với truy vấn đối soát và filter đang chọn.
- Màn hình responsive, không vỡ bố cục; loading/error/empty state đầy đủ.
- Có migration thử trên bản sao DB, backup và rollback plan.
- Trước mỗi phase: nêu phạm vi/file dự kiến; sau phase: tóm tắt diff, test thực chạy, rủi ro còn lại. Không tự ý xóa tính năng hay dữ liệu.

BẮT ĐẦU BẰNG PHASE 0. Chưa sửa code ngay: đọc repository, lập bản audit và kế hoạch ưu tiên. Sau khi báo cáo, triển khai từng phase theo thứ tự, ưu tiên tính đúng đắn dữ liệu và tương thích ngược trước UI polish.
