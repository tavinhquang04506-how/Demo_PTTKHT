-- =====================================================
-- HỆ THỐNG ĐẶT VÉ XEM PHIM TRỰC TUYẾN
-- Supabase PostgreSQL Schema + Seed Data
-- 
-- HƯỚNG DẪN: Copy toàn bộ file này vào Supabase
--   Dashboard → SQL Editor → New Query → Paste → Run
-- =====================================================

-- Xóa bảng cũ nếu có
DROP TABLE IF EXISTS chi_tiet_combo CASCADE;
DROP TABLE IF EXISTS chi_tiet_ve CASCADE;
DROP TABLE IF EXISTS dat_ve CASCADE;
DROP TABLE IF EXISTS voucher CASCADE;
DROP TABLE IF EXISTS combo CASCADE;
DROP TABLE IF EXISTS suat_chieu CASCADE;
DROP TABLE IF EXISTS ghe CASCADE;
DROP TABLE IF EXISTS phong_chieu CASCADE;
DROP TABLE IF EXISTS rap CASCADE;
DROP TABLE IF EXISTS phim CASCADE;
DROP TABLE IF EXISTS nguoi_dung CASCADE;

-- =====================================================
-- 1. TẠO BẢNG
-- =====================================================

CREATE TABLE nguoi_dung (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  mat_khau VARCHAR(255) NOT NULL DEFAULT '123456',
  ho_ten VARCHAR(255) NOT NULL,
  so_dien_thoai VARCHAR(20),
  vai_tro VARCHAR(20) NOT NULL DEFAULT 'khach_hang',
  diem_thuong INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE phim (
  id SERIAL PRIMARY KEY,
  ten_phim VARCHAR(255) NOT NULL,
  mo_ta TEXT,
  thoi_luong INTEGER NOT NULL,
  dao_dien VARCHAR(255),
  dien_vien TEXT,
  the_loai VARCHAR(255),
  quoc_gia VARCHAR(100),
  gioi_han_tuoi VARCHAR(10) DEFAULT 'P',
  ngay_khoi_chieu DATE,
  poster_url TEXT,
  diem_danh_gia DECIMAL(3,1) DEFAULT 0,
  trang_thai VARCHAR(20) DEFAULT 'dang_chieu',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE rap (
  id SERIAL PRIMARY KEY,
  ten_rap VARCHAR(255) NOT NULL,
  dia_chi TEXT,
  thanh_pho VARCHAR(100) DEFAULT 'TP. Hồ Chí Minh'
);

CREATE TABLE phong_chieu (
  id SERIAL PRIMARY KEY,
  rap_id INTEGER REFERENCES rap(id) ON DELETE CASCADE,
  ten_phong VARCHAR(50) NOT NULL,
  loai_phong VARCHAR(20) DEFAULT '2D',
  tong_ghe INTEGER DEFAULT 96
);

CREATE TABLE ghe (
  id SERIAL PRIMARY KEY,
  phong_chieu_id INTEGER REFERENCES phong_chieu(id) ON DELETE CASCADE,
  hang_ghe CHAR(1) NOT NULL,
  so_ghe INTEGER NOT NULL,
  loai_ghe VARCHAR(20) DEFAULT 'thuong',
  gia_them INTEGER DEFAULT 0,
  UNIQUE(phong_chieu_id, hang_ghe, so_ghe)
);

CREATE TABLE suat_chieu (
  id SERIAL PRIMARY KEY,
  phim_id INTEGER REFERENCES phim(id) ON DELETE CASCADE,
  phong_chieu_id INTEGER REFERENCES phong_chieu(id) ON DELETE CASCADE,
  ngay_chieu DATE NOT NULL,
  gio_bat_dau TIME NOT NULL,
  gio_ket_thuc TIME NOT NULL,
  gia_ve INTEGER DEFAULT 75000,
  trang_thai VARCHAR(20) DEFAULT 'con_cho'
);

CREATE TABLE combo (
  id SERIAL PRIMARY KEY,
  ten_combo VARCHAR(255) NOT NULL,
  mo_ta TEXT,
  gia INTEGER NOT NULL,
  hinh_url TEXT,
  loai VARCHAR(20) DEFAULT 'combo'
);

CREATE TABLE dat_ve (
  id SERIAL PRIMARY KEY,
  ma_dat_ve VARCHAR(20) UNIQUE NOT NULL,
  nguoi_dung_id INTEGER REFERENCES nguoi_dung(id),
  suat_chieu_id INTEGER REFERENCES suat_chieu(id),
  tong_tien_ghe INTEGER DEFAULT 0,
  tong_tien_combo INTEGER DEFAULT 0,
  giam_gia INTEGER DEFAULT 0,
  tong_tien INTEGER DEFAULT 0,
  trang_thai VARCHAR(20) DEFAULT 'cho_thanh_toan',
  phuong_thuc VARCHAR(20),
  voucher_code VARCHAR(50),
  ma_qr TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE chi_tiet_ve (
  id SERIAL PRIMARY KEY,
  dat_ve_id INTEGER REFERENCES dat_ve(id) ON DELETE CASCADE,
  ghe_id INTEGER REFERENCES ghe(id),
  gia_ve INTEGER NOT NULL
);

CREATE TABLE chi_tiet_combo (
  id SERIAL PRIMARY KEY,
  dat_ve_id INTEGER REFERENCES dat_ve(id) ON DELETE CASCADE,
  combo_id INTEGER REFERENCES combo(id),
  so_luong INTEGER DEFAULT 1,
  thanh_tien INTEGER NOT NULL
);

CREATE TABLE voucher (
  id SERIAL PRIMARY KEY,
  ma_code VARCHAR(50) UNIQUE NOT NULL,
  ten_voucher VARCHAR(255),
  loai_giam VARCHAR(10) DEFAULT 'tien',
  gia_tri INTEGER NOT NULL,
  dieu_kien_toi_thieu INTEGER DEFAULT 0,
  ngay_het_han DATE,
  da_su_dung BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- 2. BẬT RLS + POLICY CHO PHÉP TRUY CẬP CÔNG KHAI
-- =====================================================

DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'nguoi_dung','phim','rap','phong_chieu','ghe',
    'suat_chieu','combo','dat_ve','chi_tiet_ve',
    'chi_tiet_combo','voucher'
  ])
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY "public_access" ON %I FOR ALL USING (true) WITH CHECK (true)', t);
  END LOOP;
END $$;

-- =====================================================
-- 3. DỮ LIỆU MẪU - NGƯỜI DÙNG
-- =====================================================

INSERT INTO nguoi_dung (email, mat_khau, ho_ten, so_dien_thoai, vai_tro, diem_thuong) VALUES
('khach1@demo.com', '123456', 'Nguyễn Văn An', '0901234567', 'khach_hang', 150),
('khach2@demo.com', '123456', 'Trần Thị Bình', '0912345678', 'khach_hang', 80),
('khach3@demo.com', '123456', 'Lê Hoàng Nam', '0923456789', 'khach_hang', 200),
('nhanvien@demo.com', '123456', 'Phạm Văn Cường', '0934567890', 'nhan_vien', 0),
('nhanvien2@demo.com', '123456', 'Hoàng Thị Dung', '0945678901', 'nhan_vien', 0),
('quanly@demo.com', '123456', 'Võ Minh Đức', '0956789012', 'quan_ly', 0);

-- =====================================================
-- 4. DỮ LIỆU MẪU - PHIM (12 phim)
-- =====================================================

INSERT INTO phim (ten_phim, mo_ta, thoi_luong, dao_dien, dien_vien, the_loai, quoc_gia, gioi_han_tuoi, ngay_khoi_chieu, poster_url, diem_danh_gia, trang_thai) VALUES
('Những Mảnh Ghép Cảm Xúc 2', 'Riley bước vào tuổi dậy thì và phải đối mặt với những cảm xúc mới: Lo Âu, Ghen Tị, Chán Nản và Xấu Hổ cùng xuất hiện trong tâm trí cô bé.', 100, 'Kelsey Mann', 'Amy Poehler, Maya Hawke, Ayo Edebiri', 'Hoạt hình, Hài, Gia đình', 'Mỹ', 'P', '2024-06-14', 'https://image.tmdb.org/t/p/w500/oxxqiyWrnM0XPnBtVe9TgYWnPxT.jpg', 7.6, 'dang_chieu'),

('Deadpool & Wolverine', 'Deadpool được tổ chức TVA tuyển dụng để cứu đa vũ trụ. Anh phải hợp tác với Wolverine trong một cuộc phiêu lưu điên rồ xuyên không gian và thời gian.', 128, 'Shawn Levy', 'Ryan Reynolds, Hugh Jackman, Emma Corrin', 'Hành động, Hài, Phiêu lưu', 'Mỹ', 'C18', '2024-07-26', 'https://image.tmdb.org/t/p/w500/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg', 7.8, 'dang_chieu'),

('Hành Tinh Cát: Phần Hai', 'Paul Atreides liên minh với người Fremen để trả thù những kẻ đã hủy diệt gia đình anh, đồng thời phải ngăn chặn một tương lai khủng khiếp mà chỉ mình anh thấy trước.', 166, 'Denis Villeneuve', 'Timothée Chalamet, Zendaya, Austin Butler', 'Khoa học viễn tưởng, Phiêu lưu', 'Mỹ', 'C13', '2024-03-01', 'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg', 8.1, 'dang_chieu'),

('Kung Fu Panda 4', 'Po được chọn làm Lãnh đạo Tinh thần của Thung lũng Hòa bình nhưng trước tiên phải tìm được người kế nhiệm vai trò Rồng Chiến binh, đồng thời đối đầu với phù thủy Tắc Kè Hoa đầy mưu mô.', 94, 'Mike Mitchell', 'Jack Black, Awkwafina, Viola Davis', 'Hoạt hình, Hành động, Hài', 'Mỹ', 'P', '2024-03-08', 'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg', 7.0, 'dang_chieu'),

('Godzilla x Kong: Đế Chế Mới', 'Hai titan huyền thoại Godzilla và Kong phải hợp sức chống lại mối đe dọa khổng lồ ẩn sâu trong lòng đất, đe dọa sự tồn tại của cả loài người và quái vật.', 115, 'Adam Wingard', 'Rebecca Hall, Brian Tyree Henry, Dan Stevens', 'Hành động, Khoa học viễn tưởng', 'Mỹ', 'C13', '2024-03-29', 'https://image.tmdb.org/t/p/w500/z1p34vh7dEOnLDmyCrlUVLuoDzd.jpg', 6.5, 'dang_chieu'),

('Robot Hoang Dã', 'Robot Roz bị trôi dạt đến một hòn đảo hoang và phải học cách sinh tồn trong tự nhiên, trở thành mẹ nuôi của một chú ngỗng con mồ côi.', 102, 'Chris Sanders', 'Lupita Nyongo, Pedro Pascal, Kit Connor', 'Hoạt hình, Khoa học viễn tưởng, Gia đình', 'Mỹ', 'P', '2024-09-27', 'https://image.tmdb.org/t/p/w500/wTnV3PCVW5O92JMrFvvrRcV39RU.jpg', 8.2, 'dang_chieu'),

('Phù Thủy Xứ Oz', 'Câu chuyện về tình bạn giữa Elphaba và Glinda - hai phù thủy tại học viện phép thuật xứ Oz, trước khi một người trở thành Phù thủy Xấu xa và người kia thành Phù thủy Tốt lành.', 160, 'Jon M. Chu', 'Cynthia Erivo, Ariana Grande, Jeff Goldblum', 'Nhạc kịch, Giả tưởng', 'Mỹ', 'P', '2024-11-22', 'https://image.tmdb.org/t/p/w500/xDGbZ0JJ3mYaGKy4Nzd9Kph6M9L.jpg', 7.9, 'dang_chieu'),

('Hành Trình Của Moana 2', 'Moana nhận được lời kêu gọi bí ẩn từ đại dương và phải lên đường tới vùng biển xa xôi của Châu Đại Dương, cùng với thủy thủ đoàn mới trong một chuyến phiêu lưu chưa từng có.', 100, 'David Derrick Jr.', 'Auliʻi Cravalho, Dwayne Johnson, Alan Tudyk', 'Hoạt hình, Phiêu lưu, Gia đình', 'Mỹ', 'P', '2024-11-27', 'https://image.tmdb.org/t/p/w500/aLVkiINlIeCkcZIzb7XHzPYgO6L.jpg', 7.0, 'dang_chieu'),

('Liên Minh Sấm Sét', 'Một nhóm phản anh hùng được chính phủ Mỹ tuyển mộ cho nhiệm vụ bí mật nguy hiểm. Họ phải chứng minh rằng mình có thể trở thành anh hùng thực sự.', 127, 'Jake Schreier', 'Florence Pugh, Sebastian Stan, David Harbour', 'Hành động, Phiêu lưu', 'Mỹ', 'C13', '2025-05-02', 'https://image.tmdb.org/t/p/w500/hqcexYHbiTBfDIdDWxrxPtVndBX.jpg', 7.3, 'sap_chieu'),

('Lật Mặt 8: Vòng Tay Nắng', 'Phần mới nhất trong series phim ăn khách của đạo diễn Lý Hải, tiếp tục khai thác những câu chuyện gia đình đầy cảm xúc và kịch tính.', 132, 'Lý Hải', 'Huy Khánh, Mạc Văn Khoa, Ốc Thanh Vân', 'Tâm lý, Gia đình, Hành động', 'Việt Nam', 'C13', '2025-04-30', 'https://image.tmdb.org/t/p/w500/5MRo3arvulO98v27OPO5DXA7UDy.jpg', 7.5, 'sap_chieu'),

('Mai', 'Câu chuyện xoay quanh cuộc đời đầy biến cố của Mai - một cô gái mát-xa với quá khứ đau thương và cuộc tình éo le với Dương - một chàng trai đào hoa.', 131, 'Trấn Thành', 'Phương Anh Đào, Tuấn Trần, Trấn Thành', 'Tâm lý, Tình cảm', 'Việt Nam', 'C18', '2024-02-10', 'https://image.tmdb.org/t/p/w500/2nF8xD200rcDawuCg5ObxxqA2fC.jpg', 7.8, 'dang_chieu'),

('Hành Tinh Khỉ: Vương Quốc Mới', 'Nhiều thế hệ sau triều đại của Caesar, loài khỉ giờ đã thống trị trong khi loài người sống trong bóng tối. Một nhà lãnh đạo khỉ mới xây dựng đế chế qua bạo lực.', 145, 'Wes Ball', 'Owen Teague, Freya Allan, Kevin Durand', 'Khoa học viễn tưởng, Hành động', 'Mỹ', 'C13', '2024-05-10', 'https://image.tmdb.org/t/p/w500/gKkl37BQuKTanygYQG1pyYgLVgf.jpg', 7.1, 'dang_chieu');

-- =====================================================
-- 5. DỮ LIỆU MẪU - RẠP & PHÒNG CHIẾU
-- =====================================================

INSERT INTO rap (ten_rap, dia_chi, thanh_pho) VALUES
('CineStar Quốc Thanh', '271 Nguyễn Trãi, Quận 1', 'TP. Hồ Chí Minh'),
('CineStar Hai Bà Trưng', '135 Hai Bà Trưng, Quận 1', 'TP. Hồ Chí Minh');

INSERT INTO phong_chieu (rap_id, ten_phong, loai_phong, tong_ghe) VALUES
(1, 'Phòng 1', '2D', 96),
(1, 'Phòng 2', '3D', 96),
(2, 'Phòng 1', '2D', 96),
(2, 'Phòng 2', 'IMAX', 96);

-- =====================================================
-- 6. DỮ LIỆU MẪU - GHẾ (96 ghế × 4 phòng = 384)
-- Hàng A-D: Thường (48 ghế/phòng)
-- Hàng E-G: VIP +30,000đ (36 ghế/phòng)  
-- Hàng H: Đôi +50,000đ (12 ghế/phòng)
-- =====================================================

INSERT INTO ghe (phong_chieu_id, hang_ghe, so_ghe, loai_ghe, gia_them)
SELECT
  p.id,
  chr(65 + (s-1)/12),
  ((s-1) % 12) + 1,
  CASE
    WHEN (s-1)/12 < 4 THEN 'thuong'
    WHEN (s-1)/12 < 7 THEN 'vip'
    ELSE 'doi'
  END,
  CASE
    WHEN (s-1)/12 < 4 THEN 0
    WHEN (s-1)/12 < 7 THEN 30000
    ELSE 50000
  END
FROM phong_chieu p, generate_series(1, 96) s;

-- =====================================================
-- 7. DỮ LIỆU MẪU - SUẤT CHIẾU (7 ngày tới)
-- =====================================================

INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
SELECT
  movie.id,
  room.id,
  CURRENT_DATE + day_offset,
  t.start_time,
  t.end_time,
  CASE WHEN t.start_time >= '18:00' THEN 90000 ELSE 75000 END
FROM
  (SELECT id, thoi_luong, ROW_NUMBER() OVER (ORDER BY id) as rn
   FROM phim WHERE trang_thai = 'dang_chieu') movie,
  (SELECT id, ROW_NUMBER() OVER (ORDER BY id) as rn FROM phong_chieu) room,
  generate_series(0, 6) day_offset,
  (VALUES
    ('09:30'::time, '11:30'::time),
    ('13:00'::time, '15:00'::time),
    ('15:30'::time, '17:30'::time),
    ('18:00'::time, '20:00'::time),
    ('20:30'::time, '22:30'::time)
  ) AS t(start_time, end_time)
WHERE
  -- Mỗi phim chiếu ở 1-2 phòng, xoay vòng
  (movie.rn % 4) + 1 = room.rn
  OR ((movie.rn + 1) % 4) + 1 = room.rn;

-- =====================================================
-- 8. DỮ LIỆU MẪU - COMBO BẮP NƯỚC
-- =====================================================

INSERT INTO combo (ten_combo, mo_ta, gia, hinh_url, loai) VALUES
('Bắp Rang Bơ Nhỏ', 'Bắp rang bơ size S (32oz)', 35000, 'https://cdn-icons-png.flaticon.com/512/3081/3081967.png', 'bap'),
('Bắp Rang Bơ Lớn', 'Bắp rang bơ size L (46oz)', 49000, 'https://cdn-icons-png.flaticon.com/512/3081/3081967.png', 'bap'),
('Bắp Caramel', 'Bắp rang vị caramel thơm ngon (46oz)', 55000, 'https://cdn-icons-png.flaticon.com/512/3081/3081967.png', 'bap'),
('Coca-Cola Lớn', 'Coca-Cola size L (32oz)', 29000, 'https://cdn-icons-png.flaticon.com/512/3081/3081956.png', 'nuoc'),
('Pepsi Lớn', 'Pepsi size L (32oz)', 29000, 'https://cdn-icons-png.flaticon.com/512/3081/3081956.png', 'nuoc'),
('Nước Suối', 'Nước suối Aquafina 500ml', 15000, 'https://cdn-icons-png.flaticon.com/512/3081/3081956.png', 'nuoc'),
('Combo Đơn', '1 Bắp Lớn + 1 Nước Lớn', 69000, 'https://cdn-icons-png.flaticon.com/512/737/737967.png', 'combo'),
('Combo Đôi', '1 Bắp Lớn + 2 Nước Lớn', 89000, 'https://cdn-icons-png.flaticon.com/512/737/737967.png', 'combo'),
('Combo Gia Đình', '2 Bắp Lớn + 4 Nước Lớn + 1 Snack', 159000, 'https://cdn-icons-png.flaticon.com/512/737/737967.png', 'combo'),
('Hotdog', 'Hotdog xúc xích nướng', 39000, 'https://cdn-icons-png.flaticon.com/512/1046/1046751.png', 'do_an'),
('Nachos Phô Mai', 'Nachos với sốt phô mai béo ngậy', 45000, 'https://cdn-icons-png.flaticon.com/512/1046/1046751.png', 'do_an'),
('Khoai Tây Chiên', 'Khoai tây chiên giòn rụm', 35000, 'https://cdn-icons-png.flaticon.com/512/1046/1046751.png', 'do_an');

-- =====================================================
-- 9. DỮ LIỆU MẪU - VOUCHER
-- =====================================================

INSERT INTO voucher (ma_code, ten_voucher, loai_giam, gia_tri, dieu_kien_toi_thieu, ngay_het_han) VALUES
('CHAOBAN2026', 'Chào bạn mới - Giảm 20,000đ', 'tien', 20000, 100000, '2026-12-31'),
('PHIM10', 'Giảm 10% đơn hàng', 'phan_tram', 10, 150000, '2026-12-31'),
('COMBO50K', 'Giảm 50,000đ cho combo', 'tien', 50000, 200000, '2026-06-30'),
('SINHVIEN', 'Ưu đãi sinh viên - Giảm 15%', 'phan_tram', 15, 75000, '2026-12-31'),
('TET2026', 'Khuyến mãi Tết 2026 - Giảm 30,000đ', 'tien', 30000, 100000, '2026-02-28');

-- =====================================================
-- HOÀN TẤT! Kiểm tra dữ liệu:
-- =====================================================
-- SELECT COUNT(*) FROM nguoi_dung;  -- 6 users
-- SELECT COUNT(*) FROM phim;         -- 12 movies
-- SELECT COUNT(*) FROM ghe;          -- 384 seats
-- SELECT COUNT(*) FROM suat_chieu;   -- ~350 showtimes
-- SELECT COUNT(*) FROM combo;        -- 12 combos
-- SELECT COUNT(*) FROM voucher;      -- 5 vouchers
