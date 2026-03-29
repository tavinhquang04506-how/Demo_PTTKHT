-- =====================================================
-- RESET SUẤT CHIẾU - Xóa cũ & tạo mới chuẩn chỉ
-- Mỗi phòng: 5 suất/ngày, mỗi suất chỉ 1 phim
-- Không có phim trùng giờ trong cùng phòng
-- Ngày chiếu: 29/03 - 13/04/2026
-- =====================================================
-- HƯỚNG DẪN: Copy toàn bộ → Supabase Dashboard 
--   → SQL Editor → New Query → Paste → Run
-- =====================================================

-- 1. Xóa dữ liệu liên quan (theo thứ tự foreign key)
DELETE FROM chi_tiet_combo;
DELETE FROM chi_tiet_ve;
DELETE FROM dat_ve;
DELETE FROM suat_chieu;

-- 2. Reset điểm thưởng về mặc định
UPDATE nguoi_dung SET diem_thuong = 150 WHERE email = 'khach1@demo.com';
UPDATE nguoi_dung SET diem_thuong = 80 WHERE email = 'khach2@demo.com';
UPDATE nguoi_dung SET diem_thuong = 200 WHERE email = 'khach3@demo.com';

-- 3. Reset voucher
UPDATE voucher SET da_su_dung = FALSE;

-- =====================================================
-- 4. TẠO SUẤT CHIẾU MỚI - CHUẨN CHỈ
-- Hệ thống: 2 rạp × 2 phòng = 4 phòng
--   Phòng 1 (Rap 1 - 2D)  → Phim 1, 5, 9
--   Phòng 2 (Rap 1 - 3D)  → Phim 2, 6, 10  
--   Phòng 3 (Rap 2 - 2D)  → Phim 3, 7
--   Phòng 4 (Rap 2 - IMAX) → Phim 4, 8
-- 
-- Mỗi phòng có 5 suất/ngày:
--   09:30, 13:00, 15:30, 18:00, 20:30
-- Mỗi suất chỉ chiếu 1 phim (xoay vòng theo suất)
-- =====================================================

-- Lấy danh sách phim đang chiếu  
-- Giả sử phim đang chiếu có id từ phim 1-10 (10 phim)

DO $$
DECLARE
  phim_ids INT[];
  phong_ids INT[];
  gio_bat_dau TIME[] := ARRAY['09:30','13:00','15:30','18:00','20:30'];
  gio_ket_thuc TIME[] := ARRAY['11:30','15:00','17:30','20:00','22:30'];
  ngay_start DATE := '2026-03-29';
  ngay_end DATE := '2026-04-13';
  d DATE;
  p_idx INT;  -- phong index
  s_idx INT;  -- slot index
  phim_counter INT := 0;
  gia INT;
  phim_id_now INT;
  total_phim INT;
BEGIN
  -- Lấy danh sách phim đang chiếu
  SELECT ARRAY_AGG(id ORDER BY id) INTO phim_ids
  FROM phim WHERE trang_thai = 'dang_chieu';
  
  -- Lấy danh sách phòng chiếu
  SELECT ARRAY_AGG(id ORDER BY id) INTO phong_ids
  FROM phong_chieu;
  
  total_phim := array_length(phim_ids, 1);
  
  -- Duyệt từng ngày
  d := ngay_start;
  WHILE d <= ngay_end LOOP
    -- Duyệt từng phòng
    FOR p_idx IN 1..array_length(phong_ids, 1) LOOP
      -- Duyệt từng suất trong ngày
      FOR s_idx IN 1..5 LOOP
        -- Xoay vòng phim: mỗi suất chiếu 1 phim khác nhau
        phim_counter := phim_counter + 1;
        phim_id_now := phim_ids[((phim_counter - 1) % total_phim) + 1];
        
        -- Giá vé: buổi tối từ 18:00 = 90k, còn lại = 75k
        IF gio_bat_dau[s_idx] >= '18:00' THEN
          gia := 90000;
        ELSE
          gia := 75000;
        END IF;
        
        INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve)
        VALUES (phim_id_now, phong_ids[p_idx], d, gio_bat_dau[s_idx], gio_ket_thuc[s_idx], gia);
      END LOOP;
    END LOOP;
    
    d := d + 1;
  END LOOP;
  
  RAISE NOTICE 'Đã tạo suất chiếu thành công!';
END $$;

-- =====================================================
-- 5. KIỂM TRA KẾT QUẢ
-- =====================================================

-- Tổng số suất chiếu
SELECT 'Tổng suất chiếu' as info, COUNT(*) as so_luong FROM suat_chieu;

-- Suất chiếu theo ngày
SELECT ngay_chieu, COUNT(*) as so_suat 
FROM suat_chieu 
GROUP BY ngay_chieu 
ORDER BY ngay_chieu;

-- Kiểm tra KHÔNG CÓ trùng (cùng phòng, cùng ngày, cùng giờ phải chỉ có 1 suất)
SELECT 'Kiểm tra trùng' as info, 
  phong_chieu_id, ngay_chieu, gio_bat_dau, COUNT(*) as dem
FROM suat_chieu
GROUP BY phong_chieu_id, ngay_chieu, gio_bat_dau
HAVING COUNT(*) > 1;
-- Nếu kết quả trống = KHÔNG CÓ TRÙNG = OK ✅

-- Xem mẫu: suất chiếu ngày 29/03
SELECT sc.id, p.ten_phim, r.ten_rap, pc.ten_phong, pc.loai_phong,
  sc.ngay_chieu, sc.gio_bat_dau, sc.gia_ve
FROM suat_chieu sc
JOIN phim p ON sc.phim_id = p.id
JOIN phong_chieu pc ON sc.phong_chieu_id = pc.id
JOIN rap r ON pc.rap_id = r.id
WHERE sc.ngay_chieu = '2026-03-29'
ORDER BY r.ten_rap, pc.ten_phong, sc.gio_bat_dau;
