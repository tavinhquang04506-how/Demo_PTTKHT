-- =====================================================
-- RESET TOÀN BỘ - 5 Rạp × 3 Phòng × Lịch Chiếu Mới
-- =====================================================
-- ✅ 5 rạp CineStar
-- ✅ 3 phòng chiếu / rạp (2D, 3D, IMAX/VIP/4DX)
-- ✅ 96 ghế / phòng = 1440 ghế tổng
-- ✅ 6 suất / phòng / ngày, cách ~2.5 tiếng
-- ✅ Giờ chiếu lệch 15 phút giữa các rạp
-- ✅ Mỗi phim: 9 suất/ngày (xuất hiện ở 3 rạp)
-- ✅ Ngày: 29-30/03, 07-15/04/2026
-- ✅ Tổng: 990 suất chiếu
-- =====================================================
-- HƯỚNG DẪN: Copy → Supabase SQL Editor → Run
-- =====================================================

-- ═══════════════════════════════════════════════════════
-- BƯỚC 1: XÓA DỮ LIỆU CŨ (theo thứ tự foreign key)
-- ═══════════════════════════════════════════════════════
DELETE FROM chi_tiet_combo;
DELETE FROM chi_tiet_ve;
DELETE FROM dat_ve;
DELETE FROM suat_chieu;
DELETE FROM ghe;
DELETE FROM phong_chieu;
DELETE FROM rap;

-- Reset sequences
ALTER SEQUENCE rap_id_seq RESTART WITH 1;
ALTER SEQUENCE phong_chieu_id_seq RESTART WITH 1;
ALTER SEQUENCE ghe_id_seq RESTART WITH 1;
ALTER SEQUENCE suat_chieu_id_seq RESTART WITH 1;

-- Reset điểm thưởng + voucher
UPDATE nguoi_dung SET diem_thuong = 150 WHERE email = 'khach1@demo.com';
UPDATE nguoi_dung SET diem_thuong = 80 WHERE email = 'khach2@demo.com';
UPDATE nguoi_dung SET diem_thuong = 200 WHERE email = 'khach3@demo.com';
UPDATE voucher SET da_su_dung = FALSE;

-- ═══════════════════════════════════════════════════════
-- BƯỚC 2: TẠO 5 RẠP CINESTAR
-- ═══════════════════════════════════════════════════════
INSERT INTO rap (ten_rap, dia_chi, thanh_pho) VALUES
('CineStar Quốc Thanh',     '271 Nguyễn Trãi, Quận 1',               'TP. Hồ Chí Minh'),
('CineStar Hai Bà Trưng',   '135 Hai Bà Trưng, Quận 1',              'TP. Hồ Chí Minh'),
('CineStar Sinh Viên',      'Lầu 3 TTTM Becamex, Thủ Dầu Một',      'Bình Dương'),
('CineStar Lý Chính Thắng', '135 Lý Chính Thắng, Quận 3',            'TP. Hồ Chí Minh'),
('CineStar Mỹ Tho',         '54 Ấp Bắc, Phường 4, TP. Mỹ Tho',      'Tiền Giang');

-- ═══════════════════════════════════════════════════════
-- BƯỚC 3: TẠO 3 PHÒNG CHIẾU MỖI RẠP (15 phòng)
-- ═══════════════════════════════════════════════════════
INSERT INTO phong_chieu (rap_id, ten_phong, loai_phong, tong_ghe) VALUES
-- Rạp 1: CineStar Quốc Thanh
(1, 'Phòng 1', '2D', 96),
(1, 'Phòng 2', '3D', 96),
(1, 'Phòng 3', 'IMAX', 96),
-- Rạp 2: CineStar Hai Bà Trưng
(2, 'Phòng 1', '2D', 96),
(2, 'Phòng 2', '3D', 96),
(2, 'Phòng 3', '4DX', 96),
-- Rạp 3: CineStar Sinh Viên
(3, 'Phòng 1', '2D', 96),
(3, 'Phòng 2', '3D', 96),
(3, 'Phòng 3', 'VIP', 96),
-- Rạp 4: CineStar Lý Chính Thắng
(4, 'Phòng 1', '2D', 96),
(4, 'Phòng 2', '3D', 96),
(4, 'Phòng 3', 'IMAX', 96),
-- Rạp 5: CineStar Mỹ Tho
(5, 'Phòng 1', '2D', 96),
(5, 'Phòng 2', '3D', 96),
(5, 'Phòng 3', 'VIP', 96);

-- ═══════════════════════════════════════════════════════
-- BƯỚC 4: TẠO GHẾ (96 ghế × 15 phòng = 1440 ghế)
-- Hàng A-D: Thường (48 ghế)
-- Hàng E-G: VIP +30.000đ (36 ghế)
-- Hàng H: Đôi +50.000đ (12 ghế)
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
-- BƯỚC 5: TẠO SUẤT CHIẾU
-- ═══════════════════════════════════════════════════════
-- Lịch chiếu mỗi rạp (6 suất/phòng, lệch 15 phút/rạp):
--   Rạp 1: 09:00, 11:30, 14:00, 16:30, 19:00, 21:30
--   Rạp 2: 09:15, 11:45, 14:15, 16:45, 19:15, 21:45
--   Rạp 3: 09:30, 12:00, 14:30, 17:00, 19:30, 22:00
--   Rạp 4: 09:45, 12:15, 14:45, 17:15, 19:45, 22:15
--   Rạp 5: 10:00, 12:30, 15:00, 17:30, 20:00, 22:30
--
-- Phim phân bổ: shift 2 phim/rạp → mỗi phim xuất hiện
-- ở 3 rạp × 3 suất = 9 suất/ngày
-- ═══════════════════════════════════════════════════════

DO $$
DECLARE
  phim_ids INT[];
  rap_ids INT[];
  phong_data RECORD;
  
  -- 11 ngày chiếu
  dates DATE[] := ARRAY[
    '2026-03-29'::date, '2026-03-30'::date,
    '2026-04-07'::date, '2026-04-08'::date, '2026-04-09'::date,
    '2026-04-10'::date, '2026-04-11'::date, '2026-04-12'::date,
    '2026-04-13'::date, '2026-04-14'::date, '2026-04-15'::date
  ];
  
  -- 6 khung giờ cơ bản (cách 2.5 tiếng)
  base_starts TIME[] := ARRAY['09:00','11:30','14:00','16:30','19:00','21:30'];
  
  -- Lệch giờ mỗi rạp (phút): 0, 15, 30, 45, 60
  stagger INT[] := ARRAY[0, 15, 30, 45, 60];
  
  d DATE;
  d_idx INT;
  r_idx INT;        -- index rạp (0-4)
  rm_idx INT;       -- index phòng trong rạp (0-2)
  s_idx INT;        -- index slot (0-5)
  total_phim INT;
  movie_offset INT;
  phim_now INT;
  gio_start TIME;
  gio_end TIME;
  gia INT;
  phong_id_now INT;
  
  -- Cache phòng chiếu theo rạp
  phong_map INT[];  -- phong_map[rap_idx * 3 + room_idx + 1]
  
BEGIN
  -- Lấy phim đang chiếu
  SELECT ARRAY_AGG(id ORDER BY id) INTO phim_ids
  FROM phim WHERE trang_thai = 'dang_chieu';
  total_phim := array_length(phim_ids, 1);
  
  -- Lấy rạp
  SELECT ARRAY_AGG(id ORDER BY id) INTO rap_ids FROM rap;
  
  -- Build phong_map: cho mỗi rạp, lấy 3 phòng theo thứ tự
  phong_map := ARRAY[]::INT[];
  FOR r_idx IN 0..4 LOOP
    FOR phong_data IN 
      SELECT id FROM phong_chieu 
      WHERE rap_id = rap_ids[r_idx + 1] 
      ORDER BY id 
    LOOP
      phong_map := array_append(phong_map, phong_data.id);
    END LOOP;
  END LOOP;
  
  -- ═══ VÒNG LẶP CHÍNH ═══
  FOR d_idx IN 1..array_length(dates, 1) LOOP
    d := dates[d_idx];
    
    FOR r_idx IN 0..4 LOOP  -- 5 rạp
      FOR rm_idx IN 0..2 LOOP  -- 3 phòng/rạp
        
        phong_id_now := phong_map[r_idx * 3 + rm_idx + 1];
        
        -- Offset phim: dịch 2/rạp + 2/phòng + 2/ngày
        movie_offset := (r_idx * 2 + rm_idx * 2 + (d_idx - 1) * 2) % total_phim;
        
        FOR s_idx IN 0..5 LOOP  -- 6 suất/phòng
          
          -- Chọn phim: xen kẽ 2 phim (A=chẵn, B=lẻ)
          IF s_idx % 2 = 0 THEN
            phim_now := phim_ids[(movie_offset % total_phim) + 1];
          ELSE
            phim_now := phim_ids[((movie_offset + 1) % total_phim) + 1];
          END IF;
          
          -- Tính giờ (lệch theo rạp)
          gio_start := base_starts[s_idx + 1] + (stagger[r_idx + 1] * INTERVAL '1 minute');
          gio_end := gio_start + INTERVAL '2 hours';
          
          -- Giá vé: tối (từ 17:00) = 90k, còn lại = 75k
          IF gio_start >= '17:00'::TIME THEN gia := 90000;
          ELSE gia := 75000;
          END IF;
          
          INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
          VALUES (phim_now, phong_id_now, d, gio_start, gio_end, gia);
          
        END LOOP; -- slots
      END LOOP; -- rooms
    END LOOP; -- rạp
  END LOOP; -- dates
  
  RAISE NOTICE '✅ Hoàn tất! Tạo % suất chiếu.', array_length(dates, 1) * 5 * 3 * 6;
END $$;

-- ═══════════════════════════════════════════════════════
-- BƯỚC 6: KIỂM TRA KẾT QUẢ
-- ═══════════════════════════════════════════════════════

-- Tổng quan
SELECT '📊 Tổng quan' as info, 
  (SELECT COUNT(*) FROM rap) as so_rap,
  (SELECT COUNT(*) FROM phong_chieu) as so_phong,
  (SELECT COUNT(*) FROM ghe) as so_ghe,
  (SELECT COUNT(*) FROM suat_chieu) as so_suat_chieu;

-- Số suất chiếu mỗi phim (hôm nay)
SELECT '🎬 ' || p.ten_phim as phim, COUNT(sc.id) as suat_hom_nay
FROM phim p
LEFT JOIN suat_chieu sc ON p.id = sc.phim_id AND sc.ngay_chieu = CURRENT_DATE
WHERE p.trang_thai = 'dang_chieu'
GROUP BY p.ten_phim
ORDER BY suat_hom_nay DESC;

-- Chi tiết hôm nay - phân theo rạp
SELECT r.ten_rap, pc.ten_phong || ' · ' || pc.loai_phong as phong,
  p.ten_phim, 
  TO_CHAR(sc.gio_bat_dau, 'HH24:MI') as gio_chieu,
  TO_CHAR(sc.gia_ve, 'FM999,999') || 'đ' as gia
FROM suat_chieu sc
JOIN phim p ON sc.phim_id = p.id
JOIN phong_chieu pc ON sc.phong_chieu_id = pc.id
JOIN rap r ON pc.rap_id = r.id
WHERE sc.ngay_chieu = CURRENT_DATE
ORDER BY r.ten_rap, pc.ten_phong, sc.gio_bat_dau;

-- Suất chiếu theo ngày
SELECT ngay_chieu, COUNT(*) as so_suat 
FROM suat_chieu GROUP BY ngay_chieu ORDER BY ngay_chieu;

-- Kiểm tra KHÔNG trùng
SELECT 'Kiểm tra trùng →' as info, 
  CASE WHEN COUNT(*) = 0 THEN '✅ KHÔNG CÓ TRÙNG' ELSE '❌ CÓ TRÙNG!' END as ket_qua
FROM (
  SELECT phong_chieu_id, ngay_chieu, gio_bat_dau, COUNT(*)
  FROM suat_chieu
  GROUP BY phong_chieu_id, ngay_chieu, gio_bat_dau
  HAVING COUNT(*) > 1
) x;

-- Xem lịch chiếu mẫu 1 rạp hôm nay
SELECT '🏢 ' || r.ten_rap as rap, 
  pc.ten_phong || ' (' || pc.loai_phong || ')' as phong,
  STRING_AGG(
    TO_CHAR(sc.gio_bat_dau, 'HH24:MI') || ' ' || LEFT(p.ten_phim, 20),
    ' | ' ORDER BY sc.gio_bat_dau
  ) as lich_chieu
FROM suat_chieu sc
JOIN phim p ON sc.phim_id = p.id
JOIN phong_chieu pc ON sc.phong_chieu_id = pc.id
JOIN rap r ON pc.rap_id = r.id
WHERE sc.ngay_chieu = CURRENT_DATE
GROUP BY r.ten_rap, pc.ten_phong, pc.loai_phong, r.id, pc.id
ORDER BY r.id, pc.id;
