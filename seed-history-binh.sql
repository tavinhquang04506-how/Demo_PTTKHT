-- =====================================================
-- TẠO 7 LỊCH SỬ ĐẶT VÉ CHO "TRẦN THỊ BÌNH"
-- Ngày đặt: 25/03 - 30/03/2026
-- =====================================================
-- HƯỚNG DẪN: Copy → Supabase SQL Editor → Run
-- =====================================================

DO $$
DECLARE
  v_binh_id INT;
  v_phim_ids INT[];
  v_phong_ids INT[];
  v_combo_ids INT[];
  
  -- Ngày chiếu từ 25-30 tháng 3
  v_dates DATE[] := ARRAY[
    '2026-03-25'::date, '2026-03-26'::date, '2026-03-27'::date, 
    '2026-03-28'::date, '2026-03-29'::date, '2026-03-30'::date
  ];
  
  v_phuong_thuc VARCHAR[] := ARRAY['Momo', 'ZaloPay', 'Thẻ nội địa'];
  
  v_new_suat_id INT;
  v_new_dat_ve_id INT;
  v_d DATE;
  v_p_id INT;
  v_rm_id INT;
  
  v_gia_ve INT := 75000;
  v_so_luong_ghe INT;
  v_co_combo BOOLEAN;
  v_tong_ghe INT;
  v_tong_cb INT;
  v_ma_ve VARCHAR;
  v_ghi_id INT;

BEGIN
  -- 1. Lấy ID của Trần Thị Bình
  SELECT id INTO v_binh_id FROM nguoi_dung WHERE email = 'khach2@demo.com';
  
  IF v_binh_id IS NULL THEN
    RAISE EXCEPTION 'Không tìm thấy user Trần Thị Bình (khach2@demo.com)';
  END IF;

  -- 2. Xóa các đặt vé cũ của người này (nếu có, để tránh chạy lại sinh thêm quá nhiều)
  DELETE FROM chi_tiet_combo WHERE dat_ve_id IN (SELECT id FROM dat_ve WHERE nguoi_dung_id = v_binh_id);
  DELETE FROM chi_tiet_ve WHERE dat_ve_id IN (SELECT id FROM dat_ve WHERE nguoi_dung_id = v_binh_id);
  DELETE FROM dat_ve WHERE nguoi_dung_id = v_binh_id;

  -- Lấy danh sách data có sẵn
  SELECT ARRAY_AGG(id) INTO v_phim_ids FROM phim WHERE trang_thai IN ('dang_chieu', 'da_chieu');
  SELECT ARRAY_AGG(id) INTO v_phong_ids FROM phong_chieu;
  SELECT ARRAY_AGG(id) INTO v_combo_ids FROM combo;

  -- 3. Tạo 7 vé ngẫu nhiên
  FOR i IN 1..7 LOOP
    -- Random ngày từ 25-30
    v_d := v_dates[1 + floor(random() * 6)::INT];
    v_p_id := v_phim_ids[1 + floor(random() * array_length(v_phim_ids, 1))::INT];
    v_rm_id := v_phong_ids[1 + floor(random() * array_length(v_phong_ids, 1))::INT];
    
    -- Tạo suất chiếu "ảo" cho lịch sử (vì cần record cho vé). Set trang thái 'da_chieu' nếu ngày trước < today
    INSERT INTO suat_chieu (phim_id, phong_chieu_id, ngay_chieu, gio_bat_dau, gio_ket_thuc, gia_ve, trang_thai)
    VALUES (
      v_p_id, 
      v_rm_id, 
      v_d, 
      ('09:00'::time + (floor(random() * 12)::INT || ' hours')::interval),
      ('11:00'::time + (floor(random() * 12)::INT || ' hours')::interval),
      v_gia_ve,
      CASE WHEN v_d < CURRENT_DATE THEN 'da_chieu' ELSE 'con_cho' END
    ) RETURNING id INTO v_new_suat_id;
    
    -- Random 1-3 ghế
    v_so_luong_ghe := 1 + floor(random() * 3)::INT;
    v_tong_ghe := v_so_luong_ghe * v_gia_ve;
    
    -- Random combo 50%
    v_co_combo := random() > 0.5;
    IF v_co_combo THEN
       v_tong_cb := 69000; -- Giá combo đơn giản
    ELSE
       v_tong_cb := 0;
    END IF;
    
    -- Tạo mã đặt vé VD: BK260325XXXX
    v_ma_ve := 'BK' || to_char(v_d, 'YYMMDD') || lpad((floor(random() * 9000) + 1000)::text, 4, '0');
    
    -- Lưu thông tin đặt vé
    INSERT INTO dat_ve (
      ma_dat_ve, nguoi_dung_id, suat_chieu_id, 
      tong_tien_ghe, tong_tien_combo, giam_gia, tong_tien, 
      trang_thai, phuong_thuc, created_at
    ) VALUES (
      v_ma_ve, v_binh_id, v_new_suat_id,
      v_tong_ghe, v_tong_cb, 0, v_tong_ghe + v_tong_cb,
      CASE WHEN v_d < CURRENT_DATE THEN 'da_su_dung' ELSE 'da_thanh_toan' END, 
      v_phuong_thuc[1 + floor(random() * 3)::INT],
      -- Vé được đặt trước vài tiếng đến 1 ngày
      (v_d || ' 08:00:00')::timestamp - (floor(random()*24)::INT || ' hours')::interval
    ) RETURNING id INTO v_new_dat_ve_id;
    
    -- Tạo chi tiết ghế (chỉ lấy top limit ghế của phòng này cho đơn giản)
    FOR v_ghi_id IN 
      SELECT id FROM ghe WHERE phong_chieu_id = v_rm_id LIMIT v_so_luong_ghe
    LOOP
       INSERT INTO chi_tiet_ve (dat_ve_id, ghe_id, gia_ve)
       VALUES (v_new_dat_ve_id, v_ghi_id, v_gia_ve);
    END LOOP;
    
    -- Tạo chi tiết combo
    IF v_co_combo THEN
       INSERT INTO chi_tiet_combo (dat_ve_id, combo_id, so_luong, thanh_tien)
       VALUES (v_new_dat_ve_id, v_combo_ids[1], 1, v_tong_cb);
    END IF;
    
  END LOOP;
  
  RAISE NOTICE '✅ Đã tạo thành công 7 lịch sử đặt vé cho Trần Thị Bình!';
END $$;

-- ═══════════════════════════════════════════════════════
-- KIỂM TRA LẠI
-- ═══════════════════════════════════════════════════════
SELECT 
  dv.ma_dat_ve, 
  dv.created_at::date as ngay_dat, 
  sc.ngay_chieu as ngay_xem_phim,
  p.ten_phim, 
  dv.tong_tien, 
  dv.trang_thai
FROM dat_ve dv
JOIN suat_chieu sc ON dv.suat_chieu_id = sc.id
JOIN phim p ON sc.phim_id = p.id
JOIN nguoi_dung nd ON dv.nguoi_dung_id = nd.id
WHERE nd.email = 'khach2@demo.com'
ORDER BY sc.ngay_chieu DESC;
