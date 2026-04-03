// =====================================================
// Shared Utilities - Navbar, Footer, Helpers
// =====================================================

// Tạo Navbar dựa trên vai trò
function renderNavbar() {
  const user = Auth.getUser();
  const nav = document.getElementById('navbar');
  if (!nav) return;

  const isKhach = !user || user.vai_tro === 'khach_hang';
  const isNhanVien = user && user.vai_tro === 'nhan_vien';
  const isQuanLy = user && user.vai_tro === 'quan_ly';

  const initials = user ? user.ho_ten.split(' ').map(w => w[0]).join('').slice(-2).toUpperCase() : '';

  nav.innerHTML = `
    <div class="nav-container">
      <a href="/" class="nav-logo">
        <span class="logo-icon">🎬</span>
        <span class="logo-text">CineTicket</span>
      </a>
      <button class="nav-toggle" onclick="toggleMenu()">☰</button>
      <div class="nav-menu" id="navMenu">
        ${isKhach ? `
          <a href="/" class="nav-link">Trang chủ</a>
          ${user ? `
            <a href="/pages/lich-su" class="nav-link">Lịch sử</a>
            <a href="/pages/tai-khoan" class="nav-link">Tài khoản</a>
          ` : ''}
        ` : ''}
        ${isNhanVien ? `
          <a href="/pages/nhan-vien" class="nav-link active-link">Soát vé</a>
        ` : ''}
        ${isQuanLy ? `
          <a href="/pages/quan-ly" class="nav-link active-link">Dashboard</a>
        ` : ''}
        <div class="nav-user">
          ${user ? `
            <div class="nav-avatar">${initials}</div>
            <span class="nav-username">${user.ho_ten}</span>
            <a href="/pages/dang-nhap" class="btn-logout" id="logoutBtn">Đăng xuất</a>
          ` : `
            <a href="/pages/dang-nhap" class="btn btn-primary btn-sm">Đăng nhập</a>
          `}
        </div>
      </div>
    </div>
  `;
}

function toggleMenu() {
  document.getElementById('navMenu').classList.toggle('active');
}

// Tạo Footer
function renderFooter() {
  const footer = document.getElementById('footer');
  if (!footer) return;
  footer.innerHTML = `
    <div class="footer-container">
      <div class="footer-brand">
        <span class="logo-text" style="color: var(--accent);">🎬 CineTicket</span>
        <p>Hệ thống đặt vé xem phim hiện đại hàng đầu Việt Nam. Trải nghiệm điện ảnh đỉnh cao với chất lượng dịch vụ chuẩn quốc tế.</p>
        <div class="footer-social">
          <a href="#">🎬</a>
          <a href="#">▶️</a>
          <a href="#">🔗</a>
        </div>
      </div>
      <div class="footer-section">
        <h4>Khám phá</h4>
        <a href="/">Trang chủ</a>
        <a href="#">Về chúng tôi</a>
        <a href="#">Điều khoản</a>
        <a href="#">Chính sách bảo mật</a>
      </div>
      <div class="footer-section">
        <h4>Hỗ trợ</h4>
        <a href="#">Trung tâm trợ giúp</a>
        <a href="#">Câu hỏi thường gặp</a>
        <a href="#">Phản hồi</a>
      </div>
      <div class="footer-section">
        <h4>Liên hệ</h4>
        <ul>
          <li>📧 contact@cineticket.vn</li>
          <li>📞 1900-XXXX</li>
          <li>📍 TP. Hồ Chí Minh, Việt Nam</li>
        </ul>
      </div>
      <div class="footer-bottom">
        <p>© 2026 CineTicket — HUTECH. The Digital Premiere Experience.</p>
      </div>
    </div>
  `;
}

// Hiển thị loading
function showLoading(container) {
  if (typeof container === 'string') container = document.getElementById(container);
  if (!container) return;
  container.innerHTML = `
    <div class="loading">
      <div class="spinner"></div>
      <p>Đang tải...</p>
    </div>
  `;
}

// Hiển thị thông báo toast
function showToast(message, type = 'info') {
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => toast.classList.add('show'), 10);
  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}

// Poster fallback khi ảnh lỗi
function posterFallback(img) {
  img.onerror = null;
  img.style.background = 'linear-gradient(135deg, #e94560, #1a1a2e)';
  img.style.display = 'flex';
  img.style.alignItems = 'center';
  img.style.justifyContent = 'center';
  img.alt = img.alt || 'Poster';
  img.src = 'data:image/svg+xml,' + encodeURIComponent(`
    <svg xmlns="http://www.w3.org/2000/svg" width="300" height="450" viewBox="0 0 300 450">
      <rect fill="#1a1a2e" width="300" height="450"/>
      <text fill="#e94560" font-family="Arial" font-size="60" x="150" y="200" text-anchor="middle">🎬</text>
      <text fill="#fff" font-family="Arial" font-size="16" x="150" y="260" text-anchor="middle">Poster</text>
    </svg>
  `);
}

// Format tiền VND
function formatVND(amount) {
  return new Intl.NumberFormat('vi-VN').format(amount) + 'đ';
}

// =====================================================
// Seat Reservation Helpers
// =====================================================

// Cancel a pending reservation (async - for explicit user actions)
async function cancelReservation(datVeId) {
  if (!datVeId) return;
  try {
    await db.from('chi_tiet_ve').delete().eq('dat_ve_id', datVeId);
    await db.from('dat_ve').delete().eq('id', datVeId).eq('trang_thai', 'cho_thanh_toan');
  } catch(e) {
    console.error('Cancel reservation error:', e);
  }
}

// Cleanup expired reservations (older than 10 minutes)
async function cleanupExpiredReservations() {
  try {
    const tenMinAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    // Find expired pending bookings
    const { data: expired } = await db.from('dat_ve')
      .select('id')
      .eq('trang_thai', 'cho_thanh_toan')
      .lt('created_at', tenMinAgo);
    if (expired && expired.length > 0) {
      const ids = expired.map(d => d.id);
      await db.from('chi_tiet_ve').delete().in('dat_ve_id', ids);
      await db.from('dat_ve').delete().in('id', ids);
    }
  } catch(e) {
    console.error('Cleanup expired reservations error:', e);
  }
}

// Cancel reservation via low-level fetch (for beforeunload - fire and forget)
function cancelReservationSync(datVeId) {
  if (!datVeId) return;
  // Delete chi_tiet_ve first
  fetch(`${SUPABASE_URL}/rest/v1/chi_tiet_ve?dat_ve_id=eq.${datVeId}`, {
    method: 'DELETE',
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json'
    },
    keepalive: true
  });
  // Then delete dat_ve
  fetch(`${SUPABASE_URL}/rest/v1/dat_ve?id=eq.${datVeId}&trang_thai=eq.cho_thanh_toan`, {
    method: 'DELETE',
    headers: {
      'apikey': SUPABASE_ANON_KEY,
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json'
    },
    keepalive: true
  });
}

// Lưu dữ liệu đặt vé tạm thời
const BookingStore = {
  save(data) {
    const current = this.get();
    const merged = { ...current, ...data };
    localStorage.setItem('bookingData', JSON.stringify(merged));
  },
  get() {
    const d = localStorage.getItem('bookingData');
    return d ? JSON.parse(d) : {};
  },
  clear() {
    localStorage.removeItem('bookingData');
  }
};

// Khởi tạo trang
function initPage() {
  renderNavbar();
  renderFooter();
  // Gắn sự kiện logout
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', function(e) {
      e.preventDefault();
      localStorage.removeItem('currentUser');
      localStorage.removeItem('bookingData');
      window.location.href = '/pages/dang-nhap';
    });
  }
}

// Gọi khi DOM loaded
document.addEventListener('DOMContentLoaded', initPage);
