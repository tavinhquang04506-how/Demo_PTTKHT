// =====================================================
// Supabase Configuration
// =====================================================
const SUPABASE_URL = 'https://obblpuzqelnnvhsevifp.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9iYmxwdXpxZWxubnZoc2V2aWZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NzY1MDcsImV4cCI6MjA5MDE1MjUwN30.fVDYggKyZP_gO_WOSkorPySi_kZ8PwfgDoLOe0hA52E';

// Initialize Supabase client
// CDN gán thư viện vào window.supabase
// Ta tạo client và gán vào window.db để tránh xung đột tên
var db = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// =====================================================
// Constants
// =====================================================
const LOAI_GHE = {
  thuong: { ten: 'Thường', mau: '#4a5568', icon: '' },
  vip: { ten: 'VIP', mau: '#f5a623', icon: '⭐' },
  doi: { ten: 'Đôi', mau: '#e94560', icon: '💑' }
};

const TRANG_THAI_VE = {
  cho_thanh_toan: { ten: 'Chờ thanh toán', mau: '#f5a623' },
  da_thanh_toan: { ten: 'Đã thanh toán', mau: '#4ecca3' },
  da_su_dung: { ten: 'Đã sử dụng', mau: '#718096' },
  da_huy: { ten: 'Đã hủy', mau: '#e94560' }
};

const FORMAT_TIEN = (so) => {
  return new Intl.NumberFormat('vi-VN').format(so) + 'đ';
};

const FORMAT_NGAY = (ngay) => {
  const d = new Date(ngay);
  const options = { weekday: 'long', day: '2-digit', month: '2-digit', year: 'numeric' };
  return d.toLocaleDateString('vi-VN', options);
};

const FORMAT_GIO = (gio) => {
  return gio ? gio.substring(0, 5) : '';
};

// Base path for navigation
const BASE_PATH = '';

// Generate unique booking code
function taoMaDatVe() {
  const now = new Date();
  const y = now.getFullYear().toString().slice(2);
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const r = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `BK${y}${m}${d}${r}`;
}
