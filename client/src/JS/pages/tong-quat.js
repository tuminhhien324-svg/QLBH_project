import axios from "axios";
import Chart from "chart.js/auto";
import { BASE_URL } from "/src/JS/common/header";

function getEnterpriseColors() {
  return [
    "#3b82f6", // Blue
    "#8b5cf6", // Purple
    "#10b981", // Green
    "#f59e0b", // Orange
    "#6366f1", // Indigo
    "#14b8a6", // Teal
    "#ec4899", // Pink
    "#f43f5e"  // Rose
  ];
}

// 1. Biểu đồ hình tròn: Phân bổ sản phẩm theo danh mục
async function renderCategoryChart() {
  try {
    const response = await axios.get(`${BASE_URL}/thongke/san-pham-danh-muc`);
    const stats = response.data.data;

    // PostgreSQL trả về trường viết thường hoặc object tùy biến, hỗ trợ cả hai kiểu label/value
    const labels = stats.map((item) => item.label || item.tendanhmuc);
    const dataValues = stats.map((item) => parseInt(item.value) || 0);

    const enterpriseColors = getEnterpriseColors();
    const dynamicColors = stats.map((_, i) => enterpriseColors[i % enterpriseColors.length]);
    const canvasElement = document.getElementById("categoryPieChart");
    if (!canvasElement) return;

    const ctx = canvasElement.getContext("2d");
    const existingChart = Chart.getChart(canvasElement);
    if (existingChart) {
      existingChart.destroy();
    }

    new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Số lượng",
            data: dataValues,
            backgroundColor: dynamicColors,
            borderRadius: 4,
          },
        ],
      },
      options: {
        indexAxis: 'y', // Sử dụng Horizontal Bar
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "rgba(26, 28, 46, 0.9)",
            padding: 12,
            cornerRadius: 8,
            titleFont: { size: 14, weight: "bold" },
            bodyFont: { size: 13 },
          },
        },
        scales: {
          x: { grid: { color: "#eef0f3", borderDash: [5, 5] } },
          y: { grid: { display: false } }
        }
      },
    });
  } catch (err) {
    console.error("Lỗi khi vẽ biểu đồ danh mục:", err);
  }
}

// 2. Biểu đồ Horizontal Bar: Top 5 sản phẩm bán chạy
async function renderTopProductsChart() {
  try {
    const response = await axios.get(`${BASE_URL}/thongke/top-products`);
    const products = response.data.data.slice(0, 5); // Lấy top 5

    const labels = products.map((item) => {
        let label = item.label || item.tendanhmuc || "Sản phẩm";
        if (label.length > 20) label = label.substring(0, 20) + '...';
        return label;
    });
    const dataValues = products.map((item) => parseFloat(item.totalRevenue || item.totalrevenue) || 0);

    const canvasElement = document.getElementById("topProductsChart");
    if (!canvasElement) return;

    const ctx = canvasElement.getContext("2d");
    const existingChart = Chart.getChart(canvasElement);
    if (existingChart) existingChart.destroy();

    new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Doanh thu",
            data: dataValues,
            backgroundColor: "#3b82f6", // Đổi màu xanh sang theme đồng nhất
            borderRadius: 4,
            barThickness: 24,
          },
        ],
      },
      options: {
        indexAxis: 'y', // Convert to horizontal bar
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "rgba(26, 28, 46, 0.9)",
            callbacks: {
              label: function(context) {
                return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(context.parsed.x);
              }
            }
          }
        },
        scales: {
          x: { 
            grid: { color: "#eef0f3", borderDash: [5, 5] },
            ticks: {
              callback: function(value) {
                return value >= 1000000 ? (value / 1000000) + "M" : value;
              }
            }
          },
          y: { grid: { display: false } }
        }
      },
    });
  } catch (err) {
    console.error("Lỗi vẽ biểu đồ Top Products:", err);
  }
}

// 3. GRAPH 1: Biểu đồ ĐƯỜNG - Doanh thu theo tháng
async function renderMonthlyRevenueChart() {
  try {
    const response = await axios.get(`${BASE_URL}/thongke/monthly-revenue`);
    const stats = response.data.data;

    const labels = stats.map((item) => item.label);
    const dataValues = stats.map((item) => parseFloat(item.value) || 0);

    const canvasElement = document.getElementById("monthlyRevenueChart");
    if (!canvasElement) return;

    const ctx = canvasElement.getContext("2d");
    const existingChart = Chart.getChart(canvasElement);
    if (existingChart) existingChart.destroy();

    new Chart(ctx, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Doanh thu",
            data: dataValues,
            borderColor: "#3b82f6",
            backgroundColor: "rgba(59, 130, 246, 0.04)",
            borderWidth: 3,
            tension: 0.4,
            pointBackgroundColor: "#ffffff",
            pointBorderColor: "#3b82f6",
            pointBorderWidth: 2,
            pointRadius: 5,
            pointHoverRadius: 7,
            fill: true,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            grid: { color: "#eef0f3", drawBorder: false, borderDash: [5, 5] },
            ticks: {
              font: { size: 12 },
              color: "#64748b",
              callback: function (value) {
                if (value === 0) return "0";
                return value >= 1000000
                  ? value / 1000000 + "M"
                  : value.toLocaleString("vi-VN");
              },
            },
          },
          x: {
            grid: { display: false },
            ticks: { font: { size: 12, weight: "500" }, color: "#64748b" },
          },
        },
        plugins: {
          legend: {
            position: "bottom",
            labels: { usePointStyle: true, pointStyle: "circle", padding: 20 },
          },
        },
      },
    });

    // Hide skeleton
    const skeleton = document.getElementById("skeletonRev");
    if (skeleton) skeleton.classList.add("d-none");
  } catch (err) {
    console.error("Lỗi vẽ biểu đồ đường doanh thu tháng:", err);
  }
}

// 4. GRAPH 2: Biểu đồ CỘT - Số lượng đơn hàng theo tháng
async function renderMonthlyOrdersChart() {
  try {
    const response = await axios.get(`${BASE_URL}/thongke/monthly-orders`);
    const stats = response.data.data;

    // 🟢 FIX LỖI: Đồng bộ mapping với dữ liệu đã được Backend chuẩn hóa kiểu mới { label, value }
    const labels = stats.map((item) => item.label);
    const dataValues = stats.map((item) => parseInt(item.value) || 0);

    const canvasElement = document.getElementById("monthlyOrdersChart");
    if (!canvasElement) return;

    const ctx = canvasElement.getContext("2d");
    const existingChart = Chart.getChart(canvasElement);
    if (existingChart) existingChart.destroy();

    new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Số đơn",
            data: dataValues,
            backgroundColor: "#9333ea",
            borderRadius: 5,
            barThickness: 30,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            grid: { drawBorder: false, color: "#f0f0f0" },
            ticks: { color: "#64748b" },
          },
          x: {
            grid: { display: false },
            ticks: { color: "#64748b" },
          },
        },
        plugins: {
          legend: {
            position: "bottom",
            labels: { usePointStyle: true, padding: 20 },
          },
        },
      },
    });

    // Hide skeleton
    const skeleton = document.getElementById("skeletonOrd");
    if (skeleton) skeleton.classList.add("d-none");
  } catch (err) {
    console.error("Lỗi vẽ biểu đồ cột số đơn:", err);
  }
}

function updateBadgeTrend(badgeEl, trendTextEl, percentage) {
  if (!badgeEl || !trendTextEl) return;

  if (percentage >= 0) {
    // Nếu tăng trưởng Dương: Thêm class màu xanh của Bootstrap
    badgeEl.className =
      "badge bg-success-light text-success rounded-pill px-3 py-2";
    trendTextEl.innerHTML = `<i class="fa-solid fa-arrow-up me-1"></i> +${percentage}%`;
  } else {
    // Nếu tăng trưởng Âm: Đổi sang class màu đỏ nhạt (Cần định nghĩa bg-danger-light nếu chưa có, hoặc dùng bg-danger và text-white)
    badgeEl.className = "badge bg-danger text-white rounded-pill px-3 py-2";
    trendTextEl.innerHTML = `<i class="fa-solid fa-arrow-down me-1"></i> ${percentage}%`;
  }
}

// Hàm khởi tạo tổng hợp toàn bộ Dashboard Admin
export async function initTongQuan() {
  // Show skeletons before fetching
  const skelRev = document.getElementById("skeletonRev");
  const skelOrd = document.getElementById("skeletonOrd");
  if (skelRev) skelRev.classList.remove("d-none");
  if (skelOrd) skelOrd.classList.remove("d-none");

  // Get filter values if available
  const branchFilter = document.getElementById("branchFilter")?.value || "ALL";
  const channelFilter = document.getElementById("channelFilter")?.value || "ALL";
  const params = { branch: branchFilter, channel: channelFilter };

  try {
    const resStats = await axios.get(`${BASE_URL}/thongke/overview`, { params });
    const stats = resStats.data.data;

    // Phân rã dữ liệu từ cấu trúc Object đa tầng mới của Backend
    const doanhThuObj = stats.DoanhThu || { ThangNay: 0, PhanTram: 0 };
    const donHangObj = stats.TongDonHang || { ThangNay: 0, PhanTram: 0 };
    const khachHangObj = stats.TongKhachHang || { ThangNay: 0, PhanTram: 0 };
    const loiNhuanObj = stats.LoiNhuanGop || { ThangNay: 0, PhanTram: 0 };

    // 1. Gán giá trị số liệu chính (Tháng này) vào thẻ
    const revenueEl = document.getElementById("totalRevenue");
    const ordersEl = document.getElementById("totalOrders");
    const customersEl = document.getElementById("totalCustomers");
    const profitEl = document.getElementById("totalProfit");

    if (revenueEl) {
      revenueEl.innerText = new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND",
      }).format(parseFloat(doanhThuObj.ThangNay) || 0);
    }
    if (ordersEl)
      ordersEl.innerText = donHangObj.ThangNay.toLocaleString("vi-VN");
    if (customersEl)
      customersEl.innerText = khachHangObj.ThangNay.toLocaleString("vi-VN");
    if (profitEl) {
      profitEl.innerText = new Intl.NumberFormat("vi-VN", {
        style: "currency",
        currency: "VND",
      }).format(parseFloat(loiNhuanObj.ThangNay) || 0);
    }

    const aovEl = document.getElementById("totalAOV");
    if (aovEl) {
      const rev = parseFloat(doanhThuObj.ThangNay) || 0;
      const ord = parseInt(donHangObj.ThangNay) || 0;
      const aov = ord > 0 ? rev / ord : 0;
      aovEl.innerText = new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(aov);
    }

    // 2. Gán giá trị tăng trưởng phần trăm kèm thay đổi màu sắc Badge
    updateBadgeTrend(
      document.getElementById("revenueBadge"),
      document.getElementById("revenueTrend"),
      doanhThuObj.PhanTram,
    );
    updateBadgeTrend(
      document.getElementById("ordersBadge"),
      document.getElementById("ordersTrend"),
      donHangObj.PhanTram,
    );
    updateBadgeTrend(
      document.getElementById("customersBadge"),
      document.getElementById("customersTrend"),
      khachHangObj.PhanTram,
    );
    updateBadgeTrend(
      document.getElementById("profitBadge"),
      document.getElementById("profitTrend"),
      loiNhuanObj.PhanTram,
    );

    // Kích hoạt đồng thời 4 đồ thị và danh sách chi tiết
    renderCategoryChart();
    renderTopProductsChart();
    renderMonthlyRevenueChart();
    renderMonthlyOrdersChart();
  } catch (err) {
    console.error("Lỗi cập nhật Dashboard tổng quan:", err);
  }
}

// Lắng nghe sự kiện click nút Cập nhật (Filter Bar) bằng Event Delegation
document.addEventListener("click", async function(e) {
  const btn = e.target.closest("#btnUpdateDashboard");
  if (btn) {
    e.preventDefault();
    
    // Thêm trạng thái Loading State cho nút
    const originalHtml = btn.innerHTML;
    btn.innerHTML = `<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Đang tải...`;
    btn.disabled = true;

    try {
      // Re-fetch data and show loading state
      await initTongQuan();
    } finally {
      // Trả lại trạng thái cũ
      btn.innerHTML = originalHtml;
      btn.disabled = false;
    }
  }
});
