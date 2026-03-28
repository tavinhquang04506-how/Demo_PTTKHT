-- =====================================================
-- CẬP NHẬT NGÀY CHIẾU PHIM - Bắt đầu từ 07/04/2026
-- Chạy trên Supabase SQL Editor
-- =====================================================

-- 1. Cập nhật ngày khởi chiếu cho phim đang chiếu (bắt đầu từ 7/4/2026)
UPDATE phim SET ngay_khoi_chieu = '2026-04-01' WHERE ten_phim = 'Những Mảnh Ghép Cảm Xúc 2';
UPDATE phim SET ngay_khoi_chieu = '2026-04-01' WHERE ten_phim = 'Deadpool & Wolverine';
UPDATE phim SET ngay_khoi_chieu = '2026-04-02' WHERE ten_phim = 'Hành Tinh Cát: Phần Hai';
UPDATE phim SET ngay_khoi_chieu = '2026-04-02' WHERE ten_phim = 'Kung Fu Panda 4';
UPDATE phim SET ngay_khoi_chieu = '2026-04-03' WHERE ten_phim = 'Godzilla x Kong: Đế Chế Mới';
UPDATE phim SET ngay_khoi_chieu = '2026-04-03' WHERE ten_phim = 'Robot Hoang Dã';
UPDATE phim SET ngay_khoi_chieu = '2026-04-04' WHERE ten_phim = 'Phù Thủy Xứ Oz';
UPDATE phim SET ngay_khoi_chieu = '2026-04-04' WHERE ten_phim = 'Hành Trình Của Moana 2';
UPDATE phim SET ngay_khoi_chieu = '2026-04-05' WHERE ten_phim = 'Mai';
UPDATE phim SET ngay_khoi_chieu = '2026-04-05' WHERE ten_phim = 'Hành Tinh Khỉ: Vương Quốc Mới';

-- 2. Cập nhật ngày khởi chiếu cho phim sắp chiếu (chiếu sau 10/4)
UPDATE phim SET ngay_khoi_chieu = '2026-04-18' WHERE ten_phim = 'Liên Minh Sấm Sét';
UPDATE phim SET ngay_khoi_chieu = '2026-04-25' WHERE ten_phim = 'Lật Mặt 8: Vòng Tay Nắng';

-- 3. Xóa suất chiếu cũ và tạo lại từ 07/04/2026
DELETE FROM suat_chieu;

INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
SELECT
  movie.id,
  room.id,
  '2026-04-07'::date + day_offset,
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
  (movie.rn % 4) + 1 = room.rn
  OR ((movie.rn + 1) % 4) + 1 = room.rn;

-- Kiểm tra
SELECT 'Phim' as type, ten_phim, ngay_khoi_chieu, trang_thai FROM phim ORDER BY ngay_khoi_chieu;
SELECT 'Suất chiếu' as type, COUNT(*) as total, MIN(ngay_chieu) as from_date, MAX(ngay_chieu) as to_date FROM suat_chieu;
