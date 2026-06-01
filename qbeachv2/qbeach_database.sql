-- ============================================================
--  Q Beach Side — Restoran & Plaj Lounge
--  Veritabanı Şeması
--  MySQL 8.0 uyumlu
--  Not: Proje canlıda Supabase (PostgreSQL) üzerinde çalışmaktadır.
-- ============================================================

CREATE DATABASE IF NOT EXISTS qbeach_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_turkish_ci;

USE qbeach_db;

-- ------------------------------------------------------------
-- 1. YÖNETİCİ  (Admin paneli girişi)
-- ------------------------------------------------------------
CREATE TABLE yonetici (
  yonetici_id   INT           PRIMARY KEY AUTO_INCREMENT,
  kullanici_adi VARCHAR(100)  NOT NULL UNIQUE,
  sifre_hash    VARCHAR(255)  NOT NULL  COMMENT 'SHA-256 ile hashlenmiş şifre',
  rol           VARCHAR(50)   DEFAULT 'admin',
  son_giris     DATETIME      NULL
);

-- ------------------------------------------------------------
-- 2. ALAN  (Restoran veya Plaj Alanı)
-- ------------------------------------------------------------
CREATE TABLE alan (
  alan_id    INT          PRIMARY KEY AUTO_INCREMENT,
  alan_tipi  VARCHAR(50)  NOT NULL    COMMENT 'restoran | plaj',
  kapasite   INT          NOT NULL    COMMENT 'Maksimum masa / şezlong sayısı',
  aciklama   TEXT         NULL
);

-- ------------------------------------------------------------
-- 3. MÜŞTERİ
-- ------------------------------------------------------------
CREATE TABLE musteri (
  musteri_id  INT          PRIMARY KEY AUTO_INCREMENT,
  ad          VARCHAR(100) NOT NULL,
  soyad       VARCHAR(100) NULL,
  telefon     VARCHAR(20)  NULL,
  email       VARCHAR(150) NULL
);

-- ------------------------------------------------------------
-- 4. REZERVASYON
-- ------------------------------------------------------------
CREATE TABLE rezervasyon (
  rezervasyon_id   INT         PRIMARY KEY AUTO_INCREMENT,
  musteri_id       INT         NULL,
  alan_id          INT         NULL,
  tarih            DATE        NOT NULL,
  saat             TIME        NOT NULL,
  kisi_sayisi      INT         NULL,
  durum            VARCHAR(20) DEFAULT 'bekleyen' COMMENT 'bekleyen | onaylı | iptal',
  notlar           TEXT        NULL,
  olusturma_zamani DATETIME    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (musteri_id) REFERENCES musteri(musteri_id) ON DELETE SET NULL,
  FOREIGN KEY (alan_id)    REFERENCES alan(alan_id)
);

-- ------------------------------------------------------------
-- 5. DOLULUK KAYDI  (Admin panelinden güncellenir, sitede canlı gösterilir)
-- ------------------------------------------------------------
CREATE TABLE doluluk_kaydi (
  kayit_id         INT      PRIMARY KEY AUTO_INCREMENT,
  alan_id          INT      NULL,
  doluluk_yuzdesi  INT      NULL,
  zaman_damgasi    DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (alan_id) REFERENCES alan(alan_id),
  CONSTRAINT chk_pct CHECK (doluluk_yuzdesi BETWEEN 0 AND 100)
);

-- ------------------------------------------------------------
-- 6. MENÜ KATEGORİSİ
-- ------------------------------------------------------------
CREATE TABLE menu_kategori (
  kategori_id       INT          PRIMARY KEY AUTO_INCREMENT,
  kategori_adi      VARCHAR(100) NOT NULL,
  kategori_aciklama TEXT         NULL
);

-- ------------------------------------------------------------
-- 7. ÜRÜN  (Menü öğesi)
-- ------------------------------------------------------------
CREATE TABLE urun (
  urun_id     INT            PRIMARY KEY AUTO_INCREMENT,
  kategori_id INT            NULL,
  urun_adi    VARCHAR(150)   NOT NULL,
  fiyat       DECIMAL(10,2)  NOT NULL,
  aciklama    TEXT           NULL,
  etiket      VARCHAR(100)   NULL COMMENT 'Şef Önerisi, Vegan, Popüler vb.',
  aktif       BOOLEAN        DEFAULT TRUE,
  FOREIGN KEY (kategori_id) REFERENCES menu_kategori(kategori_id)
);

-- ------------------------------------------------------------
-- 8. SİTE POSTLARI  (AI ile üretilen sosyal medya duyuruları)
-- ------------------------------------------------------------
CREATE TABLE site_posts (
  id          INT          PRIMARY KEY AUTO_INCREMENT,
  platform    VARCHAR(50)  DEFAULT 'site' COMMENT 'instagram | facebook | site vb.',
  text        TEXT         NOT NULL,
  topic       VARCHAR(100) NULL,
  model       VARCHAR(50)  NULL COMMENT 'Kullanılan AI modeli: Claude, ChatGPT vb.',
  created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 9. SİTE YORUMLARI  (TripAdvisor'dan kopyalanıp admin'den yönetilir)
-- ------------------------------------------------------------
CREATE TABLE site_yorum (
  yorum_id   INT          PRIMARY KEY AUTO_INCREMENT,
  ad         VARCHAR(100) NOT NULL,
  sehir      VARCHAR(100) NULL,
  puan       INT          DEFAULT 5,
  metin      TEXT         NOT NULL,
  tarih_str  VARCHAR(50)  NULL COMMENT 'Görüntülenecek tarih metni, örn: Ağustos 2024',
  eklenme    DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
--  ÖRNEK VERİLER
-- ============================================================

INSERT INTO yonetici (kullanici_adi, sifre_hash, rol) VALUES
  ('admin', SHA2('kazim5353', 256), 'admin');

INSERT INTO alan (alan_tipi, kapasite, aciklama) VALUES
  ('restoran',   38, 'Deniz manzaralı kapalı ve açık oturma alanı'),
  ('plaj',       60, 'Şezlong ve VIP koltuk alanı, denize sıfır');

INSERT INTO menu_kategori (kategori_id, kategori_adi, kategori_aciklama) VALUES
  (1, 'Başlangıçlar',        'Hafif başlangıç tabakları ve paylaşım yemekleri'),
  (2, 'Deniz Ürünleri',      'Günlük taze balık ve deniz mahsulleri'),
  (3, 'Et & Izgara',         'Seçme et kesimi ve ızgara özel tarifleri'),
  (4, 'Kokteyller',          'İmza kokteyller, alkolsüz seçenekler ve şarap'),
  (5, 'Tatlılar',            'El yapımı tatlılar ve dondurma çeşitleri');

INSERT INTO urun (urun_adi, fiyat, kategori_id, aciklama, etiket) VALUES
  ('Avokado Salatası',         280.00, 1, 'Taze avokado, cherry domates, rokola, limon vinaigrette, kinoa',              'Vegan'),
  ('Sığır Carpaccio',          420.00, 1, 'İnce dilim dana bonfile, parmesan, kapari, roka, truffle yağı',               'Şef Önerisi'),
  ('Karides Tava',             380.00, 1, 'Sarımsaklı tereyağ, cherry domates, taze fesleğen, sourdough ekmek',          NULL),
  ('Kalamar Tava',             320.00, 1, 'Çıtır kalamar halkası, limon sosu, taze maydanozlu aioli',                   'Popüler'),
  ('Avokadolu Somon',          520.00, 2, 'Pan-seared somon, avokado salsa, limon sosu, taze kişniş',                    'Şef Önerisi'),
  ('Levrek Izgara',            440.00, 2, 'Taze levrek, limon-dereotu sosu, sebze tian, zeytinyağı',                     NULL),
  ('Deniz Mahsulleri Risotto', 490.00, 2, 'Karides, ahtapot, midye, arborio pirinç, safran, parmesan',                  'Popüler'),
  ('Surf & Turf',              890.00, 3, 'Bonfile + ıstakoz kuyruğu, béarnaise sos, kuşkonmaz',                        NULL),
  ('Gorgonzola Steak',         720.00, 3, '250gr ribeye, gorgonzola sosu, çıtır soğan, ev patates kızartması',           'Şef Önerisi'),
  ('Kuzu Pirzola',             580.00, 3, 'Kekikli kuzu pirzola, taze nane sosu, köz biber, pilav',                     'Popüler'),
  ('Q Signature',              240.00, 4, 'Tequila, mango püresi, jalapeño, limon, tuzlu rim',                          'İmza İçki'),
  ('Sunset Spritz',            220.00, 4, 'Aperol, prosecco, portakal suyu, gül yaprakları, soda',                      'Popüler'),
  ('Beach Mojito',             200.00, 4, 'Beyaz rom, limon, nane, şeker kamışı, soda',                                 NULL),
  ('Virgin Colada',            160.00, 4, 'Hindistancevizi sütü, ananas, limon, nane — alkolsüz',                       'Alkolsüz'),
  ('Limon Tart',               180.00, 5, 'Taze limon kreması, İtalyan merengi, çıtır tart hamuru',                     'Hafif'),
  ('Çikolatalı Lav Kek',      200.00, 5, 'Sıcak çikolata fondant, vanilyalı dondurma, frenk üzümü sosu',               'Popüler'),
  ('Tiramisu',                 175.00, 5, 'Klasik İtalyan tarifi, mascarpone, espresso, kakao',                          NULL),
  ('Panna Cotta',              160.00, 5, 'Vanilyalı panna cotta, çilek coulis, taze mevsim meyveleri',                 NULL);

INSERT INTO musteri (ad, soyad, telefon, email) VALUES
  ('Ahmet',  'Yılmaz',   '+90 532 111 22 33', 'ahmet.yilmaz@example.com'),
  ('Fatma',  'Kaya',     '+90 545 222 33 44', 'fatma.kaya@example.com'),
  ('Mehmet', 'Demir',    '+90 555 333 44 55',  NULL),
  ('Sarah',  'Thompson', '+44 7911 123456',   'sarah.t@example.com'),
  ('Klaus',  'Müller',   '+49 151 2345678',   'klaus.m@example.com');

INSERT INTO rezervasyon (musteri_id, alan_id, tarih, saat, kisi_sayisi, durum, notlar) VALUES
  (1, 1, '2026-06-15', '20:00', 4, 'onaylı',   'Pencere kenarı masa tercih edilir'),
  (2, 2, '2026-06-16', '11:00', 2, 'onaylı',   'VIP koltuk alanı, şemsiye isteniyor'),
  (3, 1, '2026-06-17', '19:30', 6, 'bekleyen', 'Doğum günü kutlaması — pasta hazır olsun'),
  (4, 1, '2026-06-18', '20:30', 2, 'bekleyen',  NULL),
  (5, 2, '2026-06-19', '10:00', 3, 'onaylı',   '3 şezlong yan yana olsun');

INSERT INTO doluluk_kaydi (alan_id, doluluk_yuzdesi) VALUES
  (1, 84),
  (2, 62);

INSERT INTO site_yorum (ad, sehir, puan, metin, tarih_str) VALUES
  ('Ayşe K.',         'İstanbul, Türkiye', 5, 'Hem deniz manzarası hem de yemekler muhteşemdi. Levrek ızgarası hayatımda yediğim en taze balıktı. Gün batımında kokteylinizi yudumlarken dünyanın en güzel yerinde olduğunuzu hissediyorsunuz. Kesinlikle tekrar geleceğiz.', 'Ağustos 2024'),
  ('James & Sarah T.','London, UK',        5, 'Absolutely stunning location and exceptional food. The seafood platter was incredibly fresh and the service was impeccable. The sunset view from our table was breathtaking. One of the best dining experiences we had in Turkey!', 'Temmuz 2024'),
  ('Mehmet A.',       'Ankara, Türkiye',   5, 'Harika bir mekan! Plaj alanı tertemiz ve şık, yemekler ise lezzetli. Özellikle Surf & Turf''ü mutlaka deneyin. Personel çok ilgili ve profesyonel. Side''ye her gelişimizde Q Beach''e uğruyoruz.', 'Eylül 2024'),
  ('Klaus M.',        'München, Germany',  5, 'Ein wunderschönes Restaurant direkt am Meer. Das Essen war hervorragend, besonders der Oktopus-Grill. Die Atmosphäre beim Sonnenuntergang ist einfach unvergesslich.', 'Ekim 2024'),
  ('Elif & Burak S.', 'İzmir, Türkiye',    5, 'Yıllardır bu sahile geliyoruz ama Q Beach''i keşfetmek bambaşka bir deneyim oldu. Kokteylleri, özellikle Q Signature, eşsiz. Gün batımı saatlerinde masa bulmak zor olabiliyor, mutlaka rezervasyon yaptırın!', 'Temmuz 2024'),
  ('Marie-Claire D.', 'Paris, France',     5, 'Magnifique restaurant en bord de mer! Le carpaccio de bœuf et les cocktails sont divins. L''ambiance du coucher de soleil est vraiment magique. Le personnel parle plusieurs langues, très accueillant.', 'Ağustos 2024');

INSERT INTO site_posts (platform, text, topic, model) VALUES
  ('instagram',
   'Denizin tam kıyısında, günbatımının altın ışıklarıyla buluşun. 🌅 Q Beach Side sizi bekliyor!\n#QBeachSide #SideAntalya #BeachRestaurant',
   'gunbatimi', 'Claude'),
  ('facebook',
   'Bu hafta sonu rezervasyonunuzu yaptırdınız mı? 🍽 Taze deniz ürünleri ve benzersiz Akdeniz lezzetleri için masanızı şimdiden ayırtın.\n#QBeachSide #SideAntalya',
   'rezervasyon', 'Claude');
