// =====================================================
// Authentication Module
// =====================================================

const Auth = {
  // Lấy user hiện tại từ localStorage
  getUser() {
    const u = localStorage.getItem('currentUser');
    return u ? JSON.parse(u) : null;
  },

  // Kiểm tra đã đăng nhập chưa
  isLoggedIn() {
    return this.getUser() !== null;
  },

  // Lấy vai trò
  getRole() {
    const u = this.getUser();
    return u ? u.vai_tro : null;
  },

  // Đăng nhập
  async login(email, password) {
    const { data, error } = await db
      .from('nguoi_dung')
      .select('*')
      .eq('email', email)
      .eq('mat_khau', password)
      .single();

    if (error || !data) {
      throw new Error('Email hoặc mật khẩu không đúng');
    }

    localStorage.setItem('currentUser', JSON.stringify(data));
    return data;
  },

  // Đăng ký
  async register(hoTen, email, soDienThoai, matKhau) {
    // Kiểm tra email đã tồn tại
    const { data: existing } = await db
      .from('nguoi_dung')
      .select('id')
      .eq('email', email)
      .single();

    if (existing) {
      throw new Error('Email đã được sử dụng');
    }

    const { data, error } = await db
      .from('nguoi_dung')
      .insert({
        ho_ten: hoTen,
        email: email,
        so_dien_thoai: soDienThoai,
        mat_khau: matKhau,
        vai_tro: 'khach_hang',
        diem_thuong: 0
      })
      .select()
      .single();

    if (error) throw new Error('Đăng ký thất bại: ' + error.message);

    localStorage.setItem('currentUser', JSON.stringify(data));
    return data;
  },

  // Đăng xuất
  logout() {
    localStorage.removeItem('currentUser');
    localStorage.removeItem('bookingData');
    window.location.href = '/pages/dang-nhap';
  },

  // Cập nhật thông tin user trong localStorage
  async refreshUser() {
    const u = this.getUser();
    if (!u) return;
    const { data } = await db
      .from('nguoi_dung')
      .select('*')
      .eq('id', u.id)
      .single();
    if (data) localStorage.setItem('currentUser', JSON.stringify(data));
  },

  // Yêu cầu đăng nhập, redirect nếu chưa
  requireLogin() {
    if (!this.isLoggedIn()) {
      window.location.href = '/pages/dang-nhap';
      return false;
    }
    return true;
  },

  // Yêu cầu vai trò cụ thể
  requireRole(role) {
    if (!this.requireLogin()) return false;
    if (this.getRole() !== role) {
      alert('Bạn không có quyền truy cập trang này');
      window.location.href = '/';
      return false;
    }
    return true;
  },

  // Redirect theo vai trò sau đăng nhập
  redirectByRole() {
    const role = this.getRole();
    switch (role) {
      case 'nhan_vien':
        window.location.href = '/pages/nhan-vien';
        break;
      case 'quan_ly':
        window.location.href = '/pages/quan-ly';
        break;
      default:
        window.location.href = '/';
    }
  }
};
