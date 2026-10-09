const jwt = require("jsonwebtoken");

// 1. Middleware xác thực Token (Kiểm tra xem đã đăng nhập chưa)
const verifyToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res
      .status(401)
      .json({ message: "Không tìm thấy Token. Vui lòng đăng nhập!" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Lưu thông tin user đã giải mã vào request
    req.user = decoded;
    const userId = decoded.id || decoded.mand || decoded.maND;
    req.user.id = userId;
    req.user.mand = userId;
    req.user.maND = userId;

    // 🟢 CẢI TIẾN ĐỒNG BỘ ROLE: Ép về thuộc tính .role chung để dùng cho authorizeRoles
    req.user.role = decoded.role || decoded.mavaitro;

    // Tạo cơ chế fallback: Đảm bảo dù controller dùng req.user.maND hay req.user.mand cũng không bị gãy
    req.user.maND = decoded.maND || decoded.mand;

    // 🟢 CẢI TIẾN MULTI-BRANCH: Gắn organization_id và branch_id
    req.user.organization_id = decoded.organization_id || null;
    req.user.branch_id = decoded.branch_id || null;

    next();
  } catch (error) {
    console.error("JWT Verify Error:", error.message);
    return res
      .status(403)
      .json({ message: "Token không hợp lệ hoặc đã hết hạn!" });
  }
};

// 2. Middleware kiểm tra quyền Manager/Admin
const isAdmin = (req, res, next) => {
  // Lấy quyền linh hoạt từ 'role' hoặc 'mavaitro' phòng trừ lệch chuẩn chữ hoa/thường
  const userRole = req.user ? req.user.role || req.user.mavaitro : null;

  if (!req.user || userRole !== "Manager") {
    return res.status(403).json({
      message: "Truy cập bị từ chối. Yêu cầu quyền Quản trị viên (Manager)!",
    });
  }
  next();
};

// 3. Middleware kiểm tra quyền Nhân viên (Employee)
const isEmployee = (req, res, next) => {
  const userRole = req.user ? req.user.role || req.user.mavaitro : null;

  if (!req.user || userRole !== "Employee") {
    return res.status(403).json({
      message: "Truy cập bị từ chối. Yêu cầu quyền Nhân viên (Employee)!",
    });
  }
  next();
};

// 4. Middleware CẢI TIẾN: Phân quyền linh hoạt theo mảng (Khuyên dùng)
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    const userRole = req.user ? req.user.role || req.user.mavaitro : null;

    if (!req.user || !allowedRoles.includes(userRole)) {
      return res
        .status(403)
        .json({ message: "Bạn không có quyền thực hiện hành động này!" });
    }
    next();
  };
};

// 5. Middleware kiểm tra truy cập theo Tổ chức (Multi-tenant)
const requireOrganization = (req, res, next) => {
  if (!req.user || !req.user.organization_id) {
    return res.status(403).json({
      message: "Truy cập bị từ chối. Không xác định được tổ chức (Organization)!",
    });
  }
  next();
};

// 6. Middleware kiểm tra truy cập theo Chi nhánh (Multi-branch)
const requireBranch = (req, res, next) => {
  if (!req.user || !req.user.branch_id) {
    return res.status(403).json({
      message: "Truy cập bị từ chối. Không xác định được chi nhánh (Branch)!",
    });
  }
  next();
};

module.exports = {
  verifyToken,
  isAdmin,
  isEmployee,
  authorizeRoles,
  requireOrganization,
  requireBranch,
};
