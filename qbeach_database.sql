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
-- 1. ALAN (Restoran veya Plaj Alanı)
-- ------------------------------------------------------------
CREATE TABLE alan (
  alan_id   INT          PRIMARY KEY AUTO_INCREMENT,
  alan_adi  VARCHAR(50)  NOT NULL,
  kapasite  INT          NOT NULL COMMENT 'Maksimum masa / şezlong sayısı'
);

-- ------------------------------------------------------------
-- 2. MÜŞTERİ
-- ------------------------------------------------------------
CREATE TABLE musteri (
  musteri_id   INT          PRIMARY KEY AUTO_INCREMENT,
  ad           VARCHAR(100) NOT NULL,
  soyad        VARCHAR(100),
  telefon      VARCHAR(20),
  email        VARCHAR(150),
  kayit_tarihi TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 3. REZERVASYON
-- ------------------------------------------------------------
CREATE TABLE rezervasyon (
  rezervasyon_id  INT      PRIMARY KEY AUTO_INCREMENT,
  musteri_id      INT      NOT NULL,
  alan_id         INT      NOT NULL,
  tarih           DATE     NOT NULL,
  saat            TIME     NOT NULL,
  kisi_sayisi     INT      DEFAULT 2,
  durum           ENUM('bekleyen', 'onaylı', 'iptal') DEFAULT 'bekleyen',
  notlar          TEXT,
  olusturma_zamani TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (musteri_id) REFERENCES musteri(musteri_id) ON DELETE CASCADE,
  FOREIGN KEY (alan_id)    REFERENCES alan(alan_id)
);

-- ------------------------------------------------------------
-- 4. DOLULUK KAYDI  (admin panelinden güncellenir, sitede canlı gösterilir)
-- ------------------------------------------------------------
CREATE TABLE doluluk_kaydi (
  kayit_id         INT PRIMARY KEY AUTO_INCREMENT,
  alan_id          INT NOT NULL,
  doluluk_yuzdesi  INT NOT NULL,
  zaman_damgasi    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (alan_id) REFERENCES alan(alan_id),
  CONSTRAINT chk_pct CHECK (doluluk_yuzdesi BETWEEN 0 AND 100)
);

-- ------------------------------------------------------------
-- 5. MENÜ KATEGORİSİ
-- ------------------------------------------------------------
CREATE TABLE menu_kategori (
  kategori_id   INT          PRIMARY KEY AUTO_INCREMENT,
  kategori_adi  VARCHAR(100) NOT NULL
);

-- ------------------------------------------------------------
-- 6. ÜRÜN (Menü öğesi)
-- ------------------------------------------------------------
CREATE TABLE urun (
  urun_id     INT            PRIMARY KEY AUTO_INCREMENT,
  urun_adi    VARCHAR(150)   NOT NULL,
  fiyat       DECIMAL(10,2)  NOT NULL,
  kategori_id INT            NOT NULL,
  aciklama    TEXT,
  etiket      VARCHAR(100)   COMMENT 'Şef Önerisi, Vegan, Popüler vb.',
  aktif       BOOLEAN        DEFAULT TRUE,
  FOREIGN KEY (kategori_id) REFERENCES menu_kategori(kategori_id)
);

-- ============================================================
--  ÖRNEK VERİLER
-- ============================================================

INSERT INTO alan (alan_adi, kapasite) VALUES
  ('Restoran',   38),
  ('Plaj Alanı', 60);

INSERT INTO menu_kategori (kategori_id, kategori_adi) VALUES
  (1, 'Başlangıçlar'),
  (2, 'Deniz Ürünleri'),
  (3, 'Et & Izgara'),
  (4, 'Kokteyller'),
  (5, 'Tatlılar');

INSERT INTO urun (urun_adi, fiyat, kategori_id, aciklama, etiket) VALUES
  ('Avokado Salatası',      280.00, 1, 'Taze avokado, cherry domates, rokola, limon vinaigrette, kinoa',              'Vegan'),
  ('Sığır Carpaccio',       420.00, 1, 'İnce dilim dana bonfile, parmesan, kapari, roka, truffle yağı',               'Şef Önerisi'),
  ('Karides Tava',          380.00, 1, 'Sarımsaklı tereyağ, cherry domates, taze fesleğen, sourdough ekmek',          NULL),
  ('Kalamar Tava',          320.00, 1, 'Çıtır kalamar halkası, limon sosu, taze maydanozlu aioli',                   'Popüler'),
  ('Avokadolu Somon',       520.00, 2, 'Pan-seared somon, avokado salsa, limon sosu, taze kişniş',                    'Şef Önerisi'),
  ('Levrek Izgara',         440.00, 2, 'Taze levrek, limon-dereotu sosu, sebze tian, zeytinyağı',                     NULL),
  ('Deniz Mahsulleri Risotto', 490.00, 2, 'Karides, ahtapot, midye, arborio pirinç, safran, parmesan',               'Popüler'),
  ('Surf & Turf',           890.00, 3, 'Bonfile + ıstakoz kuyruğu, béarnaise sos, kuşkonmaz',                        NULL),
  ('Gorgonzola Steak',      720.00, 3, '250gr ribeye, gorgonzola sosu, çıtır soğan, ev patates kızartması',           'Şef Önerisi'),
  ('Kuzu Pirzola',          580.00, 3, 'Kekikli kuzu pirzola, taze nane sosu, köz biber, pilav',                     'Popüler'),
  ('Q Signature',           240.00, 4, 'Tequila, mango püresi, jalapeño, limon, tuzlu rim',                          'İmza İçki'),
  ('Sunset Spritz',         220.00, 4, 'Aperol, prosecco, portakal suyu, gül yaprakları, soda',                      'Popüler'),
  ('Beach Mojito',          200.00, 4, 'Beyaz rom, limon, nane, şeker kamışı, soda',                                 NULL),
  ('Virgin Colada',         160.00, 4, 'Hindistancevizi sütü, ananas, limon, nane — alkolsüz',                       'Alkolsüz'),
  ('Limon Tart',            180.00, 5, 'Taze limon kreması, İtalyan merengi, çıtır tart hamuru',                     'Hafif'),
  ('Çikolatalı Lav Kek',   200.00, 5, 'Sıcak çikolata fondant, vanilyalı dondurma, frenk üzümü sosu',               'Popüler'),
  ('Tiramisu',              175.00, 5, 'Klasik İtalyan tarifi, mascarpone, espresso, kakao',                          NULL),
  ('Panna Cotta',           160.00, 5, 'Vanilyalı panna cotta, çilek coulis, taze mevsim meyveleri',                 NULL);

INSERT INTO musteri (ad, soyad, telefon, email) VALUES
  ('Ahmet',  'Yılmaz', '+90 532 111 22 33', 'ahmet.yilmaz@example.com'),
  ('Fatma',  'Kaya',   '+90 545 222 33 44', 'fatma.kaya@example.com'),
  ('Mehmet', 'Demir',  '+90 555 333 44 55', NULL),
  ('Sarah',  'Thompson', '+44 7911 123456', 'sarah.t@example.com'),
  ('Klaus',  'Müller', '+49 151 2345678',  'klaus.m@example.com');

INSERT INTO rezervasyon (musteri_id, alan_id, tarih, saat, kisi_sayisi, durum, notlar) VALUES
  (1, 1, '2026-06-15', '20:00', 4, 'onaylı',  'Pencere kenarı masa tercih edilir'),
  (2, 2, '2026-06-16', '11:00', 2, 'onaylı',  'VIP koltuk alanı, şemsiye isteniyor'),
  (3, 1, '2026-06-17', '19:30', 6, 'bekleyen','Doğum günü kutlaması — pasta hazır olsun'),
  (4, 1, '2026-06-18', '20:30', 2, 'bekleyen', NULL),
  (5, 2, '2026-06-19', '10:00', 3, 'onaylı',  '3 şezlong yan yana olsun');

INSERT INTO doluluk_kaydi (alan_id, doluluk_yuzdesi) VALUES
  (1, 84),
  (2, 62);
