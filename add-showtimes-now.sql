-- =====================================================
-- THÊM SUẤT CHIẾU TỪ 28/03 - 30/03/2026
-- Chạy trên Supabase SQL Editor
-- =====================================================

INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
SELECT
  movie.id,
  room.id,
  '2026-03-28'::date + day_offset,
  t.start_time,
  t.end_time,
  CASE WHEN t.start_time >= '18:00' THEN 90000 ELSE 75000 END
FROM
  (SELECT id, thoi_luong, ROW_NUMBER() OVER (ORDER BY id) as rn
   FROM phim WHERE trang_thai = 'dang_chieu') movie,
  (SELECT id, ROW_NUMBER() OVER (ORDER BY id) as rn FROM phong_chieu) room,
  generate_series(0, 2) day_offset,
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
SELECT ngay_chieu, COUNT(*) as so_suat FROM suat_chieu GROUP BY ngay_chieu ORDER BY ngay_chieu;
