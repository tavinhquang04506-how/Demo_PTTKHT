-- =====================================================
-- MIGRATION: Thêm cột hủy vé vào bảng dat_ve
-- Chạy trong Supabase Dashboard → SQL Editor
-- =====================================================

ALTER TABLE dat_ve ADD COLUMN IF NOT EXISTS huy_luc TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE dat_ve ADD COLUMN IF NOT EXISTS phi_huy INTEGER DEFAULT 0;
ALTER TABLE dat_ve ADD COLUMN IF NOT EXISTS tien_hoan INTEGER DEFAULT 0;
ALTER TABLE dat_ve ADD COLUMN IF NOT EXISTS loai_huy VARCHAR(20) DEFAULT NULL;

-- Kiểm tra:
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'dat_ve';
