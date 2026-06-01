<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once 'config.php';

$action = $_GET['action'] ?? '';

// ── MÜŞTERİ EKLE ──────────────────────────────────────
if ($action === 'musteri_ekle') {
    $d = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO musteri (ad, soyad, telefon, email) VALUES (?,?,?,?)");
    $stmt->execute([$d['ad'], $d['soyad'] ?? '', $d['telefon'] ?? '', $d['email'] ?? '']);
    echo json_encode([['musteri_id' => $pdo->lastInsertId()]]);
}

// ── REZERVASYON EKLE ───────────────────────────────────
elseif ($action === 'rezervasyon_ekle') {
    $d = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO rezervasyon (musteri_id, alan_id, tarih, saat, kisi_sayisi, durum, notlar)
                           VALUES (?,?,?,?,?,'bekleyen',?)");
    $stmt->execute([
        $d['musteri_id'], $d['alan_id'], $d['tarih'],
        $d['saat'], $d['kisi_sayisi'], $d['notlar'] ?? ''
    ]);
    echo json_encode([['rezervasyon_id' => $pdo->lastInsertId()]]);
}

// ── REZERVASYONLARI LİSTELE ────────────────────────────
elseif ($action === 'rezervasyon_listele') {
    $sql = "SELECT r.*, m.ad, m.soyad, m.telefon FROM rezervasyon r
            LEFT JOIN musteri m ON r.musteri_id = m.musteri_id
            ORDER BY r.olusturma_zamani DESC";
    $rows = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    $rows = array_map(function($r) {
        $r['musteri'] = ['ad' => $r['ad'], 'soyad' => $r['soyad'], 'telefon' => $r['telefon']];
        unset($r['ad'], $r['soyad'], $r['telefon']);
        return $r;
    }, $rows);
    echo json_encode($rows);
}

// ── REZERVASYON GÜNCELLE ───────────────────────────────
elseif ($action === 'rezervasyon_guncelle') {
    $d = json_decode(file_get_contents('php://input'), true);
    $id = $_GET['id'] ?? 0;
    $stmt = $pdo->prepare("UPDATE rezervasyon SET durum=? WHERE rezervasyon_id=?");
    $stmt->execute([$d['durum'], $id]);
    echo json_encode(['ok' => true]);
}

// ── REZERVASYON SİL ────────────────────────────────────
elseif ($action === 'rezervasyon_sil') {
    $id = $_GET['id'] ?? 0;
    $pdo->prepare("DELETE FROM rezervasyon WHERE rezervasyon_id=?")->execute([$id]);
    echo json_encode(['ok' => true]);
}

// ── DOLULUK KAYDET ─────────────────────────────────────
elseif ($action === 'doluluk_kaydet') {
    $d = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO doluluk_kaydi (alan_id, doluluk_yuzdesi) VALUES (?,?)");
    $stmt->execute([$d['alan_id'], $d['doluluk_yuzdesi']]);
    echo json_encode(['ok' => true]);
}

// ── DOLULUK GETİR (her alan için en güncel kayıt) ──────
elseif ($action === 'doluluk_getir') {
    $rows = $pdo->query("
        SELECT d1.alan_id, d1.doluluk_yuzdesi
        FROM doluluk_kaydi d1
        INNER JOIN (
            SELECT alan_id, MAX(zaman_damgasi) AS max_ts
            FROM doluluk_kaydi
            GROUP BY alan_id
        ) d2 ON d1.alan_id = d2.alan_id AND d1.zaman_damgasi = d2.max_ts
    ")->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows);
}

// ── KATEGORİ LİSTELE ──────────────────────────────────
elseif ($action === 'kategori_listele') {
    $rows = $pdo->query("SELECT kategori_id, kategori_adi FROM menu_kategori ORDER BY kategori_id")
                ->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows);
}

// ── KATEGORİ EKLE / GÜNCELLE ──────────────────────────
elseif ($action === 'kategori_ekle') {
    $d = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO menu_kategori (kategori_id, kategori_adi) VALUES (?,?)
                           ON DUPLICATE KEY UPDATE kategori_adi = VALUES(kategori_adi)");
    $stmt->execute([$d['kategori_id'], $d['kategori_adi']]);
    echo json_encode(['ok' => true]);
}

// ── ÜRÜN LİSTELE ───────────────────────────────────────
elseif ($action === 'urun_listele') {
    $kat = $_GET['kategori_id'] ?? null;
    if ($kat) {
        $stmt = $pdo->prepare("SELECT * FROM urun WHERE kategori_id=? AND aktif=1 ORDER BY urun_id");
        $stmt->execute([$kat]);
    } else {
        $stmt = $pdo->query("SELECT * FROM urun WHERE aktif=1 ORDER BY urun_id");
    }
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
}

// ── ÜRÜN EKLE ──────────────────────────────────────────
elseif ($action === 'urun_ekle') {
    $d = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO urun (urun_adi, fiyat, kategori_id, aciklama, etiket, aktif) VALUES (?,?,?,?,?,1)");
    $stmt->execute([$d['urun_adi'], $d['fiyat'], $d['kategori_id'], $d['aciklama'] ?? '', $d['etiket'] ?? '']);
    echo json_encode([['urun_id' => $pdo->lastInsertId()]]);
}

// ── ÜRÜN SİL ───────────────────────────────────────────
elseif ($action === 'urun_sil') {
    $id = $_GET['id'] ?? 0;
    $pdo->prepare("DELETE FROM urun WHERE urun_id=?")->execute([$id]);
    echo json_encode(['ok' => true]);
}

// ── POST LİSTELE ──────────────────────────────────────
elseif ($action === 'post_listele') {
    $rows = $pdo->query("SELECT id, platform, text, topic, model, created_at FROM site_posts ORDER BY created_at DESC")
                ->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows);
}

// ── POST EKLE ─────────────────────────────────────────
elseif ($action === 'post_ekle') {
    $d = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO site_posts (platform, text, topic, model) VALUES (?,?,?,?)");
    $stmt->execute([$d['platform'] ?? 'site', $d['text'], $d['topic'] ?? null, $d['model'] ?? null]);
    echo json_encode(['id' => $pdo->lastInsertId()]);
}

// ── POST SİL ──────────────────────────────────────────
elseif ($action === 'post_sil') {
    $id = $_GET['id'] ?? 0;
    $pdo->prepare("DELETE FROM site_posts WHERE id=?")->execute([$id]);
    echo json_encode(['ok' => true]);
}

// ── TÜM POSTLARI TEMİZLE ─────────────────────────────
elseif ($action === 'post_temizle') {
    $pdo->query("DELETE FROM site_posts");
    echo json_encode(['ok' => true]);
}

// ── YORUM LİSTELE ─────────────────────────────────────
elseif ($action === 'yorum_listele') {
    $rows = $pdo->query("SELECT yorum_id, ad, sehir, puan, metin, tarih_str FROM site_yorum ORDER BY eklenme ASC")
                ->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows);
}

// ── YORUM EKLE ────────────────────────────────────────
elseif ($action === 'yorum_ekle') {
    $d = json_decode(file_get_contents('php://input'), true);
    $stmt = $pdo->prepare("INSERT INTO site_yorum (ad, sehir, puan, metin, tarih_str) VALUES (?,?,?,?,?)");
    $stmt->execute([$d['ad'], $d['sehir'] ?? '', $d['puan'] ?? 5, $d['metin'], $d['tarih_str'] ?? '']);
    echo json_encode(['yorum_id' => $pdo->lastInsertId()]);
}

// ── YORUM SİL ─────────────────────────────────────────
elseif ($action === 'yorum_sil') {
    $id = $_GET['id'] ?? 0;
    $pdo->prepare("DELETE FROM site_yorum WHERE yorum_id=?")->execute([$id]);
    echo json_encode(['ok' => true]);
}

// ── TÜM YORUMLARI TEMİZLE (varsayılana dönmek için) ──
elseif ($action === 'yorum_temizle') {
    $pdo->query("DELETE FROM site_yorum");
    echo json_encode(['ok' => true]);
}

else {
    echo json_encode(['hata' => 'Geçersiz işlem']);
}
