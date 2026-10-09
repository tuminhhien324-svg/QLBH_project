// routes/warehouseRoutes.js
const express = require("express");
const router = express.Router();
const WarehouseController = require("../controllers/warehouseController");
const { verifyToken, authorizeRoles, requireOrganization, requireBranch } = require("../middleware/auth");

// 🟢 Áp dụng Auth và Multi-branch Scope cho toàn bộ route liên quan đến Kho hàng
router.use(verifyToken, requireOrganization, requireBranch, authorizeRoles("Manager", "Employee"));

// 1. Tuyến đường lấy toàn bộ danh sách lịch sử biến động kho hàng
router.get("/transactions", WarehouseController.getAllTransactions);

// 2. Tuyến đường xem lịch sử biến động kho của một sản phẩm nhất định
router.get("/transactions/:maSP", WarehouseController.getTransactionsByProduct);

// 3. Tuyến đường thực hiện một phiên Nhập hoặc Xuất kho mới
// CẢI TIẾN: Chỉ có Manager mới được quyền nhập/xuất kho (Ví dụ về phân quyền chi tiết)
router.post("/transaction", authorizeRoles("Manager"), WarehouseController.createTransaction);

module.exports = router;
