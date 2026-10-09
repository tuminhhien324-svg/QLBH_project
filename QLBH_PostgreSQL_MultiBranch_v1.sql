-- ============================================================
-- HP STORE / QLBH - PostgreSQL schema tham chiếu cho hệ thống đa chi nhánh
-- Phiên bản: 1.0 | PostgreSQL 14+
-- LƯU Ý: Đây là schema mục tiêu để phát triển/migrate, KHÔNG chạy đè
-- lên database hiện tại. Hãy backup và viết migration từ schema cũ.
-- ============================================================

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS qlbh;
SET search_path TO qlbh, public;

-- 1. Tổ chức, chi nhánh, kho
CREATE TABLE IF NOT EXISTS organizations (
  organization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(30) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  tax_code VARCHAR(30),
  phone VARCHAR(30),
  email VARCHAR(254),
  address TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS branches (
  branch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  code VARCHAR(30) NOT NULL,
  name VARCHAR(200) NOT NULL,
  phone VARCHAR(30),
  email VARCHAR(254),
  address TEXT,
  province VARCHAR(100),
  district VARCHAR(100),
  opened_at DATE,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE','CLOSED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS warehouses (
  warehouse_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  branch_id UUID REFERENCES branches(branch_id),
  code VARCHAR(30) NOT NULL,
  name VARCHAR(200) NOT NULL,
  warehouse_type VARCHAR(20) NOT NULL DEFAULT 'STORE'
    CHECK (warehouse_type IN ('STORE','CENTRAL','RETURN','DAMAGED')),
  address TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);

-- 2. Người dùng, vai trò và phạm vi truy cập
CREATE TABLE IF NOT EXISTS roles (
  role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(organization_id),
  code VARCHAR(40) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS permissions (
  permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  module VARCHAR(80) NOT NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS users (
  user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  username VARCHAR(80) NOT NULL,
  email VARCHAR(254),
  phone VARCHAR(30),
  password_hash TEXT NOT NULL,
  full_name VARCHAR(160) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE','LOCKED')),
  failed_login_count INT NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
  locked_until TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, username),
  UNIQUE (organization_id, email)
);

CREATE TABLE IF NOT EXISTS user_branch_access (
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  branch_id UUID NOT NULL REFERENCES branches(branch_id) ON DELETE CASCADE,
  is_default BOOLEAN NOT NULL DEFAULT false,
  PRIMARY KEY (user_id, branch_id)
);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- 3. Danh mục, thương hiệu, sản phẩm và biến thể/SKU
CREATE TABLE IF NOT EXISTS categories (
  category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  parent_category_id UUID REFERENCES categories(category_id),
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE')),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS brands (
  brand_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  code VARCHAR(50) NOT NULL,
  name VARCHAR(150) NOT NULL,
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS products (
  product_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  category_id UUID REFERENCES categories(category_id),
  brand_id UUID REFERENCES brands(brand_id),
  code VARCHAR(80) NOT NULL,
  name VARCHAR(250) NOT NULL,
  description TEXT,
  image_url TEXT,
  warranty_months INT NOT NULL DEFAULT 0 CHECK (warranty_months >= 0),
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE','DISCONTINUED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS product_variants (
  variant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(product_id),
  sku VARCHAR(100) NOT NULL UNIQUE,
  barcode VARCHAR(100) UNIQUE,
  variant_name VARCHAR(200),
  attributes JSONB NOT NULL DEFAULT '{}'::jsonb,
  unit VARCHAR(30) NOT NULL DEFAULT 'cái',
  cost_price NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
  selling_price NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (selling_price >= 0),
  min_stock INT NOT NULL DEFAULT 0 CHECK (min_stock >= 0),
  reorder_point INT NOT NULL DEFAULT 0 CHECK (reorder_point >= 0),
  shelf_life_days INT CHECK (shelf_life_days IS NULL OR shelf_life_days >= 0),
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE','DISCONTINUED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Nhà cung cấp và tồn kho theo từng kho/chi nhánh
CREATE TABLE IF NOT EXISTS suppliers (
  supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  code VARCHAR(50) NOT NULL,
  name VARCHAR(200) NOT NULL,
  tax_code VARCHAR(30),
  phone VARCHAR(30),
  email VARCHAR(254),
  address TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE','INACTIVE')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS inventory_balances (
  warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  quantity_on_hand NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
  quantity_reserved NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
  quantity_available NUMERIC(14,3) GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved) STORED,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (warehouse_id, variant_id),
  CHECK (quantity_reserved <= quantity_on_hand)
);

CREATE TABLE IF NOT EXISTS inventory_movements (
  movement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  movement_type VARCHAR(30) NOT NULL CHECK (movement_type IN
    ('OPENING','PURCHASE_RECEIPT','SALE_ISSUE','SALE_RETURN','PURCHASE_RETURN',
     'TRANSFER_IN','TRANSFER_OUT','ADJUSTMENT_IN','ADJUSTMENT_OUT','DAMAGE','RESERVATION','RELEASE')),
  quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
  unit_cost NUMERIC(14,2) CHECK (unit_cost IS NULL OR unit_cost >= 0),
  reference_type VARCHAR(40),
  reference_id UUID,
  note TEXT,
  created_by UUID REFERENCES users(user_id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stock_lots (
  lot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  lot_code VARCHAR(100),
  received_at DATE NOT NULL DEFAULT CURRENT_DATE,
  expiry_date DATE,
  quantity_received NUMERIC(14,3) NOT NULL CHECK (quantity_received >= 0),
  quantity_remaining NUMERIC(14,3) NOT NULL CHECK (quantity_remaining >= 0),
  unit_cost NUMERIC(14,2) NOT NULL CHECK (unit_cost >= 0),
  CHECK (expiry_date IS NULL OR expiry_date >= received_at),
  CHECK (quantity_remaining <= quantity_received)
);

-- 5. Khách hàng, giỏ/đơn hàng, thanh toán và hóa đơn
CREATE TABLE IF NOT EXISTS customers (
  customer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  code VARCHAR(50) NOT NULL,
  full_name VARCHAR(200) NOT NULL,
  phone VARCHAR(30),
  email VARCHAR(254),
  address TEXT,
  customer_type VARCHAR(20) NOT NULL DEFAULT 'RETAIL'
    CHECK (customer_type IN ('RETAIL','BUSINESS')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(organization_id, phone);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(organization_id, email);

CREATE TABLE IF NOT EXISTS sales_orders (
  order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  branch_id UUID NOT NULL REFERENCES branches(branch_id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  order_code VARCHAR(50) NOT NULL,
  customer_id UUID REFERENCES customers(customer_id),
  created_by UUID REFERENCES users(user_id),
  channel VARCHAR(20) NOT NULL DEFAULT 'IN_STORE'
    CHECK (channel IN ('IN_STORE','WEB','APP','MARKETPLACE','PHONE')),
  status VARCHAR(25) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','PENDING','CONFIRMED','PAID','PROCESSING','SHIPPED','COMPLETED','CANCELLED','RETURNED')),
  currency CHAR(3) NOT NULL DEFAULT 'VND',
  subtotal NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  shipping_fee NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (shipping_fee >= 0),
  total_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
  note TEXT,
  placed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, order_code)
);
CREATE INDEX IF NOT EXISTS idx_sales_orders_branch_date ON sales_orders(branch_id, placed_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_orders_status_date ON sales_orders(status, placed_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_orders_customer ON sales_orders(customer_id);

CREATE TABLE IF NOT EXISTS sales_order_items (
  order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES sales_orders(order_id) ON DELETE CASCADE,
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  sku_snapshot VARCHAR(100) NOT NULL,
  product_name_snapshot VARCHAR(250) NOT NULL,
  quantity NUMERIC(14,3) NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(14,2) NOT NULL CHECK (unit_price >= 0),
  unit_cost_snapshot NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (unit_cost_snapshot >= 0),
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  line_total NUMERIC(14,2) NOT NULL CHECK (line_total >= 0)
);

CREATE TABLE IF NOT EXISTS payments (
  payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  order_id UUID NOT NULL REFERENCES sales_orders(order_id),
  payment_code VARCHAR(60) NOT NULL,
  method VARCHAR(20) NOT NULL CHECK (method IN ('CASH','BANK_TRANSFER','QR','CARD','E_WALLET','COD')),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING','SUCCESS','FAILED','REFUNDED','PARTIALLY_REFUNDED')),
  amount NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  provider_transaction_id VARCHAR(150),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, payment_code)
);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id, status);

CREATE TABLE IF NOT EXISTS invoices (
  invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  branch_id UUID NOT NULL REFERENCES branches(branch_id),
  order_id UUID NOT NULL REFERENCES sales_orders(order_id),
  invoice_code VARCHAR(60) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ISSUED'
    CHECK (status IN ('DRAFT','ISSUED','VOID','ADJUSTED')),
  subtotal NUMERIC(14,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (organization_id, invoice_code)
);

-- 6. Đặt hàng nhà cung cấp / nhập hàng
CREATE TABLE IF NOT EXISTS purchase_orders (
  purchase_order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  supplier_id UUID NOT NULL REFERENCES suppliers(supplier_id),
  destination_warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  po_code VARCHAR(60) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','SUBMITTED','APPROVED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')),
  created_by UUID REFERENCES users(user_id),
  ordered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expected_at DATE,
  received_at TIMESTAMPTZ,
  subtotal NUMERIC(14,2) NOT NULL DEFAULT 0,
  tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  note TEXT,
  UNIQUE (organization_id, po_code)
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
  purchase_order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id UUID NOT NULL REFERENCES purchase_orders(purchase_order_id) ON DELETE CASCADE,
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  quantity_ordered NUMERIC(14,3) NOT NULL CHECK (quantity_ordered > 0),
  quantity_received NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
  unit_cost NUMERIC(14,2) NOT NULL CHECK (unit_cost >= 0),
  line_total NUMERIC(14,2) NOT NULL CHECK (line_total >= 0),
  CHECK (quantity_received <= quantity_ordered)
);

-- 7. Chuyển kho liên chi nhánh
CREATE TABLE IF NOT EXISTS stock_transfers (
  transfer_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  source_warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  destination_warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  transfer_code VARCHAR(60) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
    CHECK (status IN ('DRAFT','REQUESTED','APPROVED','IN_TRANSIT','RECEIVED','CANCELLED')),
  requested_by UUID REFERENCES users(user_id),
  approved_by UUID REFERENCES users(user_id),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  shipped_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  note TEXT,
  CHECK (source_warehouse_id <> destination_warehouse_id),
  UNIQUE (organization_id, transfer_code)
);

CREATE TABLE IF NOT EXISTS stock_transfer_items (
  transfer_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_id UUID NOT NULL REFERENCES stock_transfers(transfer_id) ON DELETE CASCADE,
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  quantity_sent NUMERIC(14,3) NOT NULL CHECK (quantity_sent > 0),
  quantity_received NUMERIC(14,3) NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
  CHECK (quantity_received <= quantity_sent)
);

-- 8. Khuyến mãi, dự báo nhu cầu, cảnh báo tồn kho và nhật ký
CREATE TABLE IF NOT EXISTS promotions (
  promotion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  code VARCHAR(60) NOT NULL,
  name VARCHAR(200) NOT NULL,
  discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('PERCENT','FIXED')),
  discount_value NUMERIC(14,2) NOT NULL CHECK (discount_value > 0),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  min_order_value NUMERIC(14,2) NOT NULL DEFAULT 0,
  max_discount NUMERIC(14,2),
  usage_limit INT CHECK (usage_limit IS NULL OR usage_limit > 0),
  used_count INT NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','INACTIVE','EXPIRED')),
  UNIQUE (organization_id, code),
  CHECK (ends_at > starts_at)
);

CREATE TABLE IF NOT EXISTS promotion_products (
  promotion_id UUID NOT NULL REFERENCES promotions(promotion_id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
  PRIMARY KEY (promotion_id, product_id)
);

CREATE TABLE IF NOT EXISTS demand_forecasts (
  forecast_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  branch_id UUID REFERENCES branches(branch_id),
  warehouse_id UUID REFERENCES warehouses(warehouse_id),
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  forecast_date DATE NOT NULL,
  horizon_days INT NOT NULL CHECK (horizon_days > 0),
  predicted_quantity NUMERIC(14,3) NOT NULL CHECK (predicted_quantity >= 0),
  lower_bound NUMERIC(14,3),
  upper_bound NUMERIC(14,3),
  model_name VARCHAR(100),
  model_version VARCHAR(50),
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (warehouse_id, variant_id, forecast_date, horizon_days)
);

CREATE TABLE IF NOT EXISTS inventory_alerts (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(organization_id),
  warehouse_id UUID NOT NULL REFERENCES warehouses(warehouse_id),
  variant_id UUID NOT NULL REFERENCES product_variants(variant_id),
  alert_type VARCHAR(30) NOT NULL CHECK (alert_type IN ('LOW_STOCK','OUT_OF_STOCK','OVERSTOCK','NEAR_EXPIRY','EXPIRED','DEAD_STOCK')),
  severity VARCHAR(15) NOT NULL DEFAULT 'MEDIUM' CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  message TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','ACKNOWLEDGED','RESOLVED')),
  detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS audit_logs (
  audit_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  organization_id UUID REFERENCES organizations(organization_id),
  branch_id UUID REFERENCES branches(branch_id),
  user_id UUID REFERENCES users(user_id),
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_id TEXT,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. View phục vụ dashboard. Backend phải luôn lọc organization_id/branch_id
CREATE OR REPLACE VIEW v_inventory_summary AS
SELECT
  w.organization_id, w.branch_id, w.warehouse_id,
  ib.variant_id, p.product_id, p.code AS product_code, p.name AS product_name,
  pv.sku, pv.cost_price, pv.selling_price,
  ib.quantity_on_hand, ib.quantity_reserved, ib.quantity_available,
  (ib.quantity_on_hand * pv.cost_price)::NUMERIC(16,2) AS inventory_cost_value,
  (ib.quantity_on_hand * pv.selling_price)::NUMERIC(16,2) AS inventory_retail_value,
  pv.min_stock, pv.reorder_point,
  CASE
    WHEN ib.quantity_on_hand = 0 THEN 'OUT_OF_STOCK'
    WHEN ib.quantity_on_hand <= GREATEST(pv.min_stock, pv.reorder_point) THEN 'LOW_STOCK'
    ELSE 'NORMAL'
  END AS stock_status
FROM inventory_balances ib
JOIN warehouses w ON w.warehouse_id = ib.warehouse_id
JOIN product_variants pv ON pv.variant_id = ib.variant_id
JOIN products p ON p.product_id = pv.product_id;

CREATE INDEX IF NOT EXISTS idx_inventory_movements_warehouse_date
  ON inventory_movements(warehouse_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_variant_date
  ON inventory_movements(variant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_date
  ON purchase_orders(supplier_id, ordered_at DESC);
CREATE INDEX IF NOT EXISTS idx_forecasts_branch_date
  ON demand_forecasts(branch_id, forecast_date);
CREATE INDEX IF NOT EXISTS idx_alerts_open
  ON inventory_alerts(organization_id, status, severity) WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS idx_audit_logs_org_date
  ON audit_logs(organization_id, created_at DESC);

COMMIT;

-- Các nghiệp vụ KHÔNG nên thực hiện bằng cách sửa trực tiếp số tồn:
-- 1) Nhập/xuất/chuyển kho: transaction + SELECT ... FOR UPDATE + movement ledger.
-- 2) Bán hàng: tạo order + items + reserve stock trong một transaction.
-- 3) Hủy/hoàn hàng: chỉ hoàn kho đúng một lần (idempotency), có movement tham chiếu.
-- 4) Nhận chuyển kho: xuất kho nguồn khi gửi, nhập kho đích khi xác nhận nhận.
-- 5) Mọi truy vấn phải giới hạn organization_id; người dùng chi nhánh chỉ được
--    truy cập branch_id nằm trong user_branch_access.
-- 6) Dự báo nhu cầu chỉ là kết quả mô hình; cần lưu model/version và đánh giá sai số.
