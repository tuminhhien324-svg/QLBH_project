# Kế Hoạch Chuyển Đổi Cơ Sở Dữ Liệu (Database Migration Plan)

Tài liệu này hướng dẫn cách ánh xạ (mapping) và di chuyển (migrate) dữ liệu từ phiên bản QLBH cũ sang chuẩn Multi-Branch v1.

## 1. Mục Đích & Nguyên Tắc
- Chuyển đổi tên bảng/cột từ Tiếng Việt (cũ) sang Tiếng Anh chuẩn (mới).
- Bổ sung cấu trúc Multi-tenant: Tổ chức (`organizations`) và Chi nhánh (`branches`).
- Đảm bảo **Không mất dữ liệu**: Có kịch bản Backup và Rollback đầy đủ.

## 2. Bảng Ánh Xạ Dữ Liệu (Mapping)

### 2.1 Bảng Cơ Sở (Foundation)
| Bảng Cũ | Bảng Mới | Thay Đổi Chính |
| --- | --- | --- |
| Không có | `organizations` | Tạo mới 1 bản ghi tổ chức mặc định cho toàn bộ dữ liệu hiện tại. |
| Không có | `branches` | Tạo mới 1 bản ghi chi nhánh mặc định (Main Branch). |
| `nguoidung` | `users` | Thêm cột `organization_id`. `mand` -> `user_id`, `tendangnhap` -> `username`. `mavaitro` -> mapped sang bảng `roles` và `user_roles`. |

### 2.2 Quản Lý Sản Phẩm (Catalog)
| Bảng Cũ | Bảng Mới | Thay Đổi Chính |
| --- | --- | --- |
| `danhmuc` | `categories` | `madanhmuc` -> `category_id`, thêm `organization_id`. |
| `sanpham` | `products` & `product_variants` | Tách làm 2 cấp. Thông tin cơ bản (`tensp`, `mota`) vào `products`. Giá, số lượng (`soluongton`) và barcode vào `product_variants`. |

### 2.3 Kho Hàng (Inventory)
| Bảng Cũ | Bảng Mới | Thay Đổi Chính |
| --- | --- | --- |
| Không có | `warehouses` | Tạo mới 1 kho mặc định liên kết với chi nhánh mặc định. |
| (Cột `soluongton` của `sanpham`) | `inventory_balances` | Chuyển `soluongton` vào đây, gán theo `warehouse_id` và `variant_id`. Thêm cột `quantity_reserved`. |
| `giaodichkho` | `inventory_movements` | `magd` -> `movement_id`, `loaigd` (1/2) -> `movement_type` (RECEIPT/ISSUE). Bỏ cột `tontruoc`, `tonsau` (áp dụng truy vấn tồn động thay vì hardcode snapshot nếu cần thiết, hoặc đổi thành `unit_cost_snapshot`). |
| `nhacungcap` | `suppliers` | `mancc` -> `supplier_id`, thêm `organization_id`. |

### 2.4 Bán Hàng (Sales)
| Bảng Cũ | Bảng Mới | Thay Đổi Chính |
| --- | --- | --- |
| `khachhang` | `customers` | `makh` -> `customer_id`, thêm `organization_id`. |
| `donhang` | `sales_orders` | Thêm `organization_id`, `branch_id`, `warehouse_id`. Trạng thái đơn đổi sang chuẩn (`PENDING`, `COMPLETED`...). |
| `chitiet_donhang`| `sales_order_items` | `masp` trỏ sang `variant_id`. Chụp giá bán và giá vốn lúc mua (`unit_cost_snapshot`) để tính lợi nhuận đúng. |

## 3. Script Khởi Tạo Dữ Liệu Mặc Định
*Sau khi chạy schema v1, cần thực thi script tạo Tổ chức và Chi nhánh gốc để map dữ liệu cũ sang:*
```sql
-- Tạo Organization mặc định
INSERT INTO qlbh.organizations (code, name) 
VALUES ('DEFAULT_ORG', 'HP Store - Main Organization') 
RETURNING organization_id;

-- Tạo Branch mặc định (Sử dụng organization_id vừa tạo)
INSERT INTO qlbh.branches (organization_id, code, name) 
VALUES ((SELECT organization_id FROM qlbh.organizations LIMIT 1), 'MAIN_BRANCH', 'Chi nhánh Chính')
RETURNING branch_id;

-- Tạo Warehouse mặc định
INSERT INTO qlbh.warehouses (organization_id, branch_id, code, name, warehouse_type)
VALUES (
    (SELECT organization_id FROM qlbh.organizations LIMIT 1),
    (SELECT branch_id FROM qlbh.branches LIMIT 1),
    'MAIN_WH', 'Kho Tổng', 'STORE'
);
```

## 4. Kịch Bản Backup & Rollback
1. **Backup**: Lệnh `pg_dump -U username -h host dbname > backup_old.sql`
2. **Migration**: Tạo 1 file Script PL/pgSQL chuyển dữ liệu từng bảng, wrap trong 1 khối `BEGIN ... EXCEPTION ... COMMIT/ROLLBACK`.
3. **Rollback**: Nếu script lỗi, Postgres sẽ tự động rollback. Nếu phát hiện lỗi sau khi đã commit, chạy lệnh `psql < backup_old.sql` để restore lại trạng thái cũ.
