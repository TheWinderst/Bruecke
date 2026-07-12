# Brücke — Geliştirme & Düzeltme Planı

Bu plan, kod tabanını inceleyen çok-ekipli bir denetimle hazırlandı: **6 uzman ekip**
(Eşzamanlılık, Ağ/Ayrıştırma, SwiftUI/Arayüz, UX/Tasarım, Güvenlik & Açık-Kaynak/Hukuk,
Mimari/Ürün) toplam **37 ajan** ile kodu taradı; her hata bulgusu ayrıca bağımsız bir
**şüpheci doğrulayıcı** tarafından sınandı (yanlış alarmlar elendi). Sonuç: 59 bulgu →
**16 doğrulanmış hata**, 10 UX, 5 hukuk, 13 yol-haritası kalemi.

---

## ✅ Sürüm 1.0 — Düzeltme planı (tamamlandı)

### Çökme / kararlılık
- **Telaffuz çökmesi (yüksek):** Mikrofon ekranında hızlı çift dokunuş aynı ses kanalına
  ikinci bir "tap" kuruyor ve uygulamayı kapatıyordu → yeniden-giriş koruması + idempotent
  başlatma eklendi.
- **Ses motoru sızıntısı (yüksek):** Kart pratik sırasında kapatılınca mikrofon/tanıma
  görevi açık kalıyordu → `onDisappear` temizliği + `deinit` güvenlik ağı.
- **4 sn'lik zamanlayıcı sızıntısı:** Eski zamanlayıcı iptal edilmeden yenisi kuruluyordu.

### Doğruluk
- **Hızlı ardışık aramalar yarışı (orta):** Artık yalnızca **en yeni** arama kartı boyar
  (kuşak sayacı).
- **Kayıtlı kelime çakışması (orta):** Eş yazımlı kelimeler (der/die See) birbirini
  eziyordu → kimlik artık lemma+tür+cinsiyet.
- **Ağ hataları sessizdi (orta):** Çeviri alınamayınca artık "—" yerine **"Çeviri
  alınamadı — bağlantını kontrol et"** gösterilir; harf olmayan seçimde yardım kartı çıkar.
- **URL kodlaması (düşük):** `& ? +` içeren kelimeler Wiktionary/Tatoeba/OpenThesaurus
  isteklerini bozuyordu → katı kodlama.
- **Çoğul işaretleme temizliği (düşük):** `<ref>`/`[[…]]` artıkları çoğuldan ayıklanır.

### Arayüz / lifecycle
- **Uzun kart taşması (orta):** Yükseklik ekrana sığacak şekilde sınırlandı.
- **ESC ile kapatma (düşük):** Genel + yerel izleyici ile artık çalışır.
- **Pencere ortalama (düşük):** Kayıtlı/Ayarlar penceresi her açılışta ortalanıp
  yerini kaybetmiyor.
- **Kısayol işleyici (düşük):** Carbon olay işleyicisi uygulama ömründe **bir kez** kurulur.

### Güvenlik & gizlilik
- **Dünyaya açık günlük (düşük):** `/tmp/apfel.log` → `~/Library/Caches/Bruecke/`
  altında, `0600` izniyle; seçili metin asla loglanmaz.
- **Pano koruması:** Seçim okunurken panonun **tüm içeriği** (resim/dosya/biçimli metin)
  yedeklenip geri yüklenir — eskiden yalnızca düz metin korunuyordu.

### UX — telaffuz ekranı (senin bildirdiğin sorun)
- **Şeffaf katman kaldırıldı:** Pratik ekranı artık kartın üstüne **binmiyor**; kartın
  yerine geçip kendi cam yüzeyini kullanıyor → alttan kelime sızmıyor, **açık ve koyu
  modda temiz**.
- Ortalanmış kompakt yerleşim, daha okunur "geri" düğmesi, halkayla aynı renkte/kalın
  yüzde, dinlerken nabız atan kayıt noktası + 4 sn ilerleme çubuğu, sessizken bile
  hareket eden dalga.

### Açık-kaynak hazırlığı
- `LICENSE` (GPL-3.0, thewinderst), `.gitignore`, `README` (kaynak atıfları + gizlilik +
  Google notu), "Hakkında" kutusunda kaynaklar.
- **Çeviri motoru artık seçilebilir** (Google varsayılan + açık kaynak LibreTranslate).

---

## ✅ Sürüm 1.3 — Akıcılık ve öğrenme güncellemesi (tamamlandı)

- **P1 · Kelime tekrar kartları ✔** — "Kelimelerim" penceresinde flashcard modu:
  3B dönen kart, bildim/tekrar döngüsü, tur sonu özeti, karttan seslendirme.
  Menüye "Kelime tekrarı…" eklendi.
- **P2 · Arama geçmişi ✔** — Son 200 arama saklanır; yazma kutusunda son 5 arama
  tıklanabilir listelenir. Ayarlardan kapatılabilir/temizlenebilir.
- **P3 · Çevrimdışı önbellek ✔** — Geçmişteki kelime tekrar aranınca ağa çıkılmaz:
  anında açılır, internetsiz de çalışır (geçmişle aynı depo).
- **P8 · Anki/CSV dışa aktarma ✔** — Kayıtlı kelimeler başlıklı CSV olarak dışa
  aktarılır (ilk iki sütun Anki ön/arka yüzüne uyar).
- **Akıcılık:** Arama başlar başlamaz küçük "çevriliyor" kartı belirir; sonuç aynı
  noktada kartla yer değiştirir. Paneller yumuşak açılır. Bekleme kartı ESC/dış
  tıklamayla kapatılırsa bekleyen arama iptal edilir (kart sonradan fırlamaz).

---

## 🗺️ Yol haritası

### Now — sıradaki
- **P5 · Günün kelimesi [S/M]** — Günlük kart/bildirim ile alışkanlık.
- **P9 · Özelleştirilebilir kısayol [S]** — ⌘⇧D bazı uygulamalarla çakışıyor; kullanıcı değiştirebilsin.
- **P10 · Örnek cümle seslendirme [S]** — *(1.0'da eklendi ✔)* her örneğin yanında 🔊.

### Later — sonra (daha büyük)
- **P4 · Aralıklı tekrar (SRS) [M]** — P1'in üstüne SM-2/Leitner; kalıcı öğrenme.
- **P6 · Türkçe → Almanca yön [M]** — *(1.4'te eklendi ✔)* Arama kutusunda DE→TR /
  TR→DE düğmesi; Türkçe kelime Almancaya çevrilip Almanca kelimenin tam kartı
  (artikel, çoğul, örnekler, diğer karşılıklar) gösterilir. Harf ipuçlarıyla
  (ğ/ş/ı ↔ ß/ä) yön otomatik düzeltilir.
- **P7 · Tam çekim/çekimleme tabloları [M]** — Şimdiki zaman kişi çekimleri + 4 hâl
  ismin hâlleri (Wiktionary verisinden).

---

## 🧱 Mimari / teknik borç notları
- **Çeviri istemcisi ayrıldı:** Google çağrıları artık `TranslateClient` içinde
  (LibreTranslate ile birlikte) — eskiden `DictionaryService`'e gömülüydü. *(1.0 ✔)*
- **Test hedefi yok:** Saf mantık (benzerlik/Levenshtein, hece bölme, Wiktionary
  ayrıştırma regex'leri) izole test edilemiyor. Öneri: ince bir `BrueckeCore` kütüphane
  hedefi + `Tests/`. Wiktionary ayrıştırması sayfalar değiştikçe kayacağı için regresyon
  ağı en çok orada gerekli.
- **Çift kod:** Google yanıt ayrıştırması tek yardımcıya alındı. *(1.0 ✔)*

---

*Öncelikler: S = küçük, M = orta, L = büyük iş. Sürüm 1.0 düzeltmeleri ve mimari
ayıklamalar uygulandı; yol haritası kalemleri henüz planlama aşamasında.*
