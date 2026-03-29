-- =====================================================
-- RESET TOÀN BỘ V5 - Ưu tiên phim hot, full suất chiếu
-- =====================================================
-- 🔥 Mai: 6 suất/rạp × 5 rạp = 30 suất/ngày
-- 🔥 Moana 2: 6 suất/rạp × 5 rạp = 30 suất/ngày
-- 🔥 KFP4: 3 suất/rạp × 5 rạp = 15 suất/ngày
-- 🔥 Cảm Xúc 2: 3 suất/rạp × 5 rạp = 15 suất/ngày
-- 📽️ Phim khác: 3 suất tại 1-2 rạp (xoay vòng)
-- =====================================================
-- Giờ chiếu lệch 15 phút giữa các rạp:
-- Rạp 1: 09:00, 11:30, 14:00, 16:30, 19:00, 21:30
-- Rạp 2: 09:15, 11:45, 14:15, 16:45, 19:15, 21:45
-- Rạp 3: 09:30, 12:00, 14:30, 17:00, 19:30, 22:00
-- Rạp 4: 09:45, 12:15, 14:45, 17:15, 19:45, 22:15
-- Rạp 5: 10:00, 12:30, 15:00, 17:30, 20:00, 22:30
-- =====================================================
-- HƯỚNG DẪN: Copy → Supabase SQL Editor → Run
-- =====================================================

-- ═══ BƯỚC 1: XÓA DỮ LIỆU CŨ ═══
DELETE FROM chi_tiet_combo;
DELETE FROM chi_tiet_ve;
DELETE FROM dat_ve;
DELETE FROM suat_chieu;
DELETE FROM ghe;
DELETE FROM phong_chieu;
DELETE FROM rap;

ALTER SEQUENCE rap_id_seq RESTART WITH 1;
ALTER SEQUENCE phong_chieu_id_seq RESTART WITH 1;
ALTER SEQUENCE ghe_id_seq RESTART WITH 1;
ALTER SEQUENCE suat_chieu_id_seq RESTART WITH 1;

UPDATE nguoi_dung SET diem_thuong = 150 WHERE email = 'khach1@demo.com';
UPDATE nguoi_dung SET diem_thuong = 80 WHERE email = 'khach2@demo.com';
UPDATE nguoi_dung SET diem_thuong = 200 WHERE email = 'khach3@demo.com';
UPDATE voucher SET da_su_dung = FALSE;

-- ═══ BƯỚC 2: TẠO 5 RẠP ═══
INSERT INTO rap (ten_rap, dia_chi, thanh_pho) VALUES
('CineStar Quốc Thanh',     '271 Nguyễn Trãi, Quận 1',               'TP. Hồ Chí Minh'),
('CineStar Hai Bà Trưng',   '135 Hai Bà Trưng, Quận 1',              'TP. Hồ Chí Minh'),
('CineStar Sinh Viên',      'Lầu 3 TTTM Becamex, Thủ Dầu Một',      'Bình Dương'),
('CineStar Lý Chính Thắng', '135 Lý Chính Thắng, Quận 3',            'TP. Hồ Chí Minh'),
('CineStar Mỹ Tho',         '54 Ấp Bắc, Phường 4, TP. Mỹ Tho',      'Tiền Giang');

-- ═══ BƯỚC 3: TẠO 15 PHÒNG CHIẾU ═══
INSERT INTO phong_chieu (rap_id, ten_phong, loai_phong, tong_ghe) VALUES
(1, 'Phòng 1', '2D', 96), (1, 'Phòng 2', '3D', 96), (1, 'Phòng 3', 'IMAX', 96),
(2, 'Phòng 1', '2D', 96), (2, 'Phòng 2', '3D', 96), (2, 'Phòng 3', '4DX', 96),
(3, 'Phòng 1', '2D', 96), (3, 'Phòng 2', '3D', 96), (3, 'Phòng 3', 'VIP', 96),
(4, 'Phòng 1', '2D', 96), (4, 'Phòng 2', '3D', 96), (4, 'Phòng 3', 'IMAX', 96),
(5, 'Phòng 1', '2D', 96), (5, 'Phòng 2', '3D', 96), (5, 'Phòng 3', 'VIP', 96);

-- ═══ BƯỚC 4: TẠO 1440 GHẾ ═══
INSERT INTO ghe (phong_chieu_id, hang_ghe, so_ghe, loai_ghe, gia_them)
SELECT p.id, chr(65 + (s-1)/12), ((s-1) % 12) + 1,
  CASE WHEN (s-1)/12 < 4 THEN 'thuong' WHEN (s-1)/12 < 7 THEN 'vip' ELSE 'doi' END,
  CASE WHEN (s-1)/12 < 4 THEN 0 WHEN (s-1)/12 < 7 THEN 30000 ELSE 50000 END
FROM phong_chieu p, generate_series(1, 96) s;

-- ═══ BƯỚC 5: TẠO SUẤT CHIẾU ═══
DO $$
DECLARE
  -- Phim ưu tiên
  id_mai INT;
  id_moana INT;
  id_kfp4 INT;
  id_camxuc INT;
  
  -- Phim còn lại
  other_ids INT[] := ARRAY[]::INT[];
  total_other INT;
  
  -- Rạp & phòng
  rap_ids INT[];
  phong_rec RECORD;
  phong_map INT[];  -- [rap*3 + room + 1]
  
  -- Ngày chiếu (11 ngày)
  dates DATE[] := ARRAY[
    '2026-03-29','2026-03-30',
    '2026-04-07','2026-04-08','2026-04-09','2026-04-10',
    '2026-04-11','2026-04-12','2026-04-13','2026-04-14','2026-04-15'
  ];
  
  -- 6 khung giờ cơ bản (cách 2.5 tiếng)
  base_starts TIME[] := ARRAY['09:00','11:30','14:00','16:30','19:00','21:30'];
  stagger INT[] := ARRAY[0, 15, 30, 45, 60]; -- phút lệch/rạp
  
  d DATE;
  d_idx INT;
  r_idx INT;
  s_idx INT;
  gio_start TIME;
  gio_end TIME;
  gia INT;
  phong_id_now INT;
  other_offset INT;
  phim_A INT;
  phim_B INT;

BEGIN
  -- ═══ Lấy ID 4 phim ưu tiên ═══
  SELECT id INTO id_mai FROM phim WHERE ten_phim = 'Mai';
  SELECT id INTO id_moana FROM phim WHERE ten_phim = 'Hành Trình Của Moana 2';
  SELECT id INTO id_kfp4 FROM phim WHERE ten_phim = 'Kung Fu Panda 4';
  SELECT id INTO id_camxuc FROM phim WHERE ten_phim = 'Những Mảnh Ghép Cảm Xúc 2';
  
  RAISE NOTICE 'Phim ưu tiên IDs: Mai=%, Moana=%, KFP4=%, CamXuc=%', 
    id_mai, id_moana, id_kfp4, id_camxuc;
  
  -- ═══ Lấy ID phim còn lại ═══
  FOR phong_rec IN 
    SELECT id FROM phim 
    WHERE trang_thai = 'dang_chieu' 
      AND id NOT IN (id_mai, id_moana, id_kfp4, id_camxuc)
    ORDER BY id
  LOOP
    other_ids := array_append(other_ids, phong_rec.id);
  END LOOP;
  total_other := array_length(other_ids, 1);
  
  -- ═══ Map phòng chiếu ═══
  SELECT ARRAY_AGG(id ORDER BY id) INTO rap_ids FROM rap;
  phong_map := ARRAY[]::INT[];
  FOR r_idx IN 0..4 LOOP
    FOR phong_rec IN 
      SELECT id FROM phong_chieu 
      WHERE rap_id = rap_ids[r_idx + 1] ORDER BY id
    LOOP
      phong_map := array_append(phong_map, phong_rec.id);
    END LOOP;
  END LOOP;
  
  -- ═══════════════════════════════════════════════════
  -- VÒNG LẶP CHÍNH
  -- ═══════════════════════════════════════════════════
  FOR d_idx IN 1..array_length(dates, 1) LOOP
    d := dates[d_idx];
    
    FOR r_idx IN 0..4 LOOP
      
      -- ────────────────────────────────────────────
      -- PHÒNG 1 (2D): MAI - full 6 suất
      -- ────────────────────────────────────────────
      phong_id_now := phong_map[r_idx * 3 + 1];
      FOR s_idx IN 0..5 LOOP
        gio_start := base_starts[s_idx + 1] + (stagger[r_idx + 1] * INTERVAL '1 minute');
        gio_end := gio_start + INTERVAL '2 hours';
        IF gio_start >= '17:00' THEN gia := 90000; ELSE gia := 75000; END IF;
        
        INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
        VALUES (id_mai, phong_id_now, d, gio_start, gio_end, gia);
      END LOOP;
      
      -- ────────────────────────────────────────────
      -- PHÒNG 2 (3D): MOANA 2 - full 6 suất
      -- ────────────────────────────────────────────
      phong_id_now := phong_map[r_idx * 3 + 2];
      FOR s_idx IN 0..5 LOOP
        gio_start := base_starts[s_idx + 1] + (stagger[r_idx + 1] * INTERVAL '1 minute');
        gio_end := gio_start + INTERVAL '2 hours';
        IF gio_start >= '17:00' THEN gia := 90000; ELSE gia := 75000; END IF;
        
        INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
        VALUES (id_moana, phong_id_now, d, gio_start, gio_end, gia);
      END LOOP;
      
      -- ────────────────────────────────────────────
      -- PHÒNG 3 (IMAX/4DX/VIP): Xoay vòng
      --   Rạp 1-3: KFP4 (even) + Cảm Xúc 2 (odd)
      --   Rạp 4-5: 2 phim khác (xoay vòng theo ngày)
      -- ────────────────────────────────────────────
      phong_id_now := phong_map[r_idx * 3 + 3];
      
      IF r_idx <= 2 THEN
        -- Rạp 1,2,3: KFP4 + Cảm Xúc 2
        phim_A := id_kfp4;
        phim_B := id_camxuc;
      ELSE
        -- Rạp 4,5: Phim khác xoay vòng
        other_offset := ((d_idx - 1) * 2 + (r_idx - 3) * 2) % total_other;
        phim_A := other_ids[(other_offset % total_other) + 1];
        phim_B := other_ids[((other_offset + 1) % total_other) + 1];
      END IF;
      
      FOR s_idx IN 0..5 LOOP
        gio_start := base_starts[s_idx + 1] + (stagger[r_idx + 1] * INTERVAL '1 minute');
        gio_end := gio_start + INTERVAL '2 hours';
        IF gio_start >= '17:00' THEN gia := 90000; ELSE gia := 75000; END IF;
        
        IF s_idx % 2 = 0 THEN
          INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
          VALUES (phim_A, phong_id_now, d, gio_start, gio_end, gia);
        ELSE
          INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
          VALUES (phim_B, phong_id_now, d, gio_start, gio_end, gia);
        END IF;
      END LOOP;
      
    END LOOP; -- rạp
  END LOOP; -- ngày
  
  RAISE NOTICE '✅ Hoàn tất! Tạo % suất chiếu.', array_length(dates, 1) * 5 * 3 * 6;
END $$;

-- ═══════════════════════════════════════════════════════
-- BƯỚC 6: KIỂM TRA
-- ═══════════════════════════════════════════════════════

SELECT '📊 Tổng quan' as info,
  (SELECT COUNT(*) FROM rap) as so_rap,
  (SELECT COUNT(*) FROM phong_chieu) as so_phong,
  (SELECT COUNT(*) FROM ghe) as so_ghe,
  (SELECT COUNT(*) FROM suat_chieu) as tong_suat;

-- Suất chiếu mỗi phim HÔM NAY
SELECT p.ten_phim, COUNT(sc.id) as suat_hom_nay,
  COUNT(DISTINCT pc.rap_id) as tai_so_rap
FROM phim p
LEFT JOIN suat_chieu sc ON p.id = sc.phim_id AND sc.ngay_chieu = CURRENT_DATE
LEFT JOIN phong_chieu pc ON sc.phong_chieu_id = pc.id
WHERE p.trang_thai = 'dang_chieu'
GROUP BY p.ten_phim
ORDER BY suat_hom_nay DESC;

-- Chi tiết phim Mai hôm nay
SELECT r.ten_rap, pc.ten_phong || ' · ' || pc.loai_phong as phong,
  TO_CHAR(sc.gio_bat_dau, 'HH24:MI') || ' - ' || TO_CHAR(sc.gio_ket_thuc, 'HH24:MI') as gio,
  TO_CHAR(sc.gia_ve, 'FM999,999') || 'đ' as gia
FROM suat_chieu sc
JOIN phim p ON sc.phim_id = p.id
JOIN phong_chieu pc ON sc.phong_chieu_id = pc.id
JOIN rap r ON pc.rap_id = r.id
WHERE p.ten_phim = 'Mai' AND sc.ngay_chieu = CURRENT_DATE
ORDER BY r.id, sc.gio_bat_dau;

-- Kiểm tra trùng
SELECT 'Kiểm tra →' as info, 
  CASE WHEN COUNT(*) = 0 THEN '✅ KHÔNG TRÙNG' ELSE '❌ CÓ TRÙNG!' END
FROM (
  SELECT phong_chieu_id, ngay_chieu, gio_bat_dau, COUNT(*)
  FROM suat_chieu
  GROUP BY phong_chieu_id, ngay_chieu, gio_bat_dau
  HAVING COUNT(*) > 1
) x;
