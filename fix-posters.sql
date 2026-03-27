-- =====================================================
-- FIX POSTER URLs - Chạy trong Supabase SQL Editor
-- Cập nhật poster cho các phim bị lỗi hiển thị
-- =====================================================

-- 1. Những Mảnh Ghép Cảm Xúc 2 (Inside Out 2)
UPDATE phim SET poster_url = 'https://image.tmdb.org/t/p/w500/oxxqiyWrnM0XPnBtVe9TgYWnPxT.jpg'
WHERE ten_phim = 'Những Mảnh Ghép Cảm Xúc 2';

-- 2. Hành Trình Của Moana 2
UPDATE phim SET poster_url = 'https://image.tmdb.org/t/p/w500/aLVkiINlIeCkcZIzb7XHzPYgO6L.jpg'
WHERE ten_phim = 'Hành Trình Của Moana 2';

-- 3. Godzilla x Kong: Đế Chế Mới
UPDATE phim SET poster_url = 'https://image.tmdb.org/t/p/w500/z1p34vh7dEOnLDmyCrlUVLuoDzd.jpg'
WHERE ten_phim = 'Godzilla x Kong: Đế Chế Mới';

-- 4. Liên Minh Sấm Sét (Thunderbolts*)
UPDATE phim SET poster_url = 'https://image.tmdb.org/t/p/w500/hqcexYHbiTBfDIdDWxrxPtVndBX.jpg'
WHERE ten_phim = 'Liên Minh Sấm Sét';

-- 5. Lật Mặt 8: Vòng Tay Nắng
UPDATE phim SET poster_url = 'https://image.tmdb.org/t/p/w500/5MRo3arvulO98v27OPO5DXA7UDy.jpg'
WHERE ten_phim LIKE 'Lật Mặt 8%';

-- 6. Mai (Trấn Thành)
UPDATE phim SET poster_url = 'https://image.tmdb.org/t/p/w500/2nF8xD200rcDawuCg5ObxxqA2fC.jpg'
WHERE ten_phim = 'Mai';
