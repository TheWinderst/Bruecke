# Brücke

Brücke, menü çubuğunda çalışan, Almancadan Türkçeye native bir macOS sözlüğüdür. Herhangi bir uygulamada bir Almanca kelimeyi seçip `⌘⇧D` kısayoluna basıldığında, kelimenin Türkçe karşılığını ve dil bilgisi ayrıntılarını gösteren bir kart açılır.

Türkçe konuşan ve Almanca öğrenen kullanıcılar için tasarlandı. Anlam doğrudan Türkçe verilir, İngilizce üzerinden geçmek gerekmez. Sözlük sayfaları arasında dolaşmak yerine, çeviriye okunan yerden ulaşılır.

## Özellikler

Bir kelime seçilip kart açıldığında şunlar görünür:

- **Türkçe anlam.** Kartın en üstünde, vurgulu biçimde. (İstenirse Ayarlar'dan İngilizceye alınır.)
- **Artikel.** der, die, das. Renk kodludur; üç artikel bir bakışta ayırt edilir.
- **Tür ve çoğul.** Kelimenin türü (isim, fiil vb.) ve isimlerde çoğul biçim.
- **Fiil çekimi.** Mastar, Präteritum ve Perfekt biçimleri (örneğin gehen, ging, gegangen).
- **Okunuş (IPA)** ve **İngilizce karşılık.** Türkçe karşılığın yetersiz kaldığı durumlarda ikinci bir referans.
- **Diğer anlamlar** ve **Almanca eş anlamlılar.** Hepsi tıklanabilir: bir anlama dokununca o kelimenin kartı açılır, sol üstteki geri okuyla önceki karta dönülür.
- **İki örnek cümle**, Türkçe çevirisiyle birlikte.

Kelime ve örnek cümleler Apple'ın Almanca seslendirmesiyle dinlenebilir; normal hız, yavaş veya hece hece seçenekleri vardır. Mikrofona söylenen telaffuz için puan alınabilir.

**Uzun metin de çevrilir.** Bir paragraf ya da sayfa seçilip aynı kısayolla çevrilebilir; metin cümle sınırlarından bölünüp parça parça çevrilir ve okunabilir bir metin kartında gösterilir (kaynak metinle birlikte, seçilip kopyalanabilir).

## Öğrenme ve hız

- **Kelime tekrarı.** Kaydedilen kelimeler çevir-kapat kartlarla çalışılır: Almanca yüzü görünür, kart çevrilince Türkçesi ve örnek cümlesi açılır. Bilinen kart turdan düşer, bilinmeyen tura geri döner; tur bitince özet gösterilir. Kartın üstündeki mikrofon düğmesiyle telaffuz puanı da alınabilir.
- **Arama geçmişi.** Daha önce bakılan kelimeler kaybolmaz; yazma kutusunda son aramalar tek tıkla yeniden açılır.
- **Çevrimdışı önbellek.** Bir kez bakılan kelime bu Mac'te saklanır: ikinci bakış ağa çıkmadan anında açılır ve internet yokken de çalışır. Ayarlar bölümünden kapatılabilir veya temizlenebilir.
- **Anki'ye aktarma.** Kayıtlı kelimeler tek tıkla CSV dosyasına yazılır; Anki ve benzeri programlara doğrudan alınabilir.
- **Kelimelerim'de arama.** Kayıtlar büyüdükçe liste üstündeki alandan süzülür.
- Arama yapılırken kart yerine küçük bir "çevriliyor" göstergesi anında belirir; sonuç gelince aynı noktada karta dönüşür.

Elde metin seçili değilse de çeviri yapılabilir. Menü çubuğundaki **Kelime yaz ve çevir…** ile ya da hiçbir yer seçili değilken kısayola basınca küçük bir yazma kutusu açılır; kelime ya da uzun metin yazılıp/yapıştırılıp Enter'a basıldığında aynı kart görünür. Bu yol Erişilebilirlik iznine ihtiyaç duymaz.

**Türkçeden Almancaya da sorulabilir.** Yazma kutusundaki DE → TR / TR → DE düğmesiyle yön seçilir; Türkçe bir kelime yazıldığında Almanca karşılığı, artikeli, çoğulu ve örnek cümleleriyle tam kart olarak gelir. Kartta diğer olası Almanca karşılıklar da listelenir. Yön düğmesi yanlış kalsa bile sorun olmaz: ğ, ş, ı gibi harfler görülen kelime Türkçe, ß ve ä görülen kelime Almanca kabul edilir.

**İngilizce desteği.** Ayarlar'daki "Çeviri dili" English'e alındığında kartlar Almancadan İngilizceye çevrilir (DE → EN). Türkçe modundaki ters arama ve edat kalıpları bu modda devre dışı kalır.

Sağ tık menüsünde "Brücke'de çevir" servisi de bulunur.

**Kısayol değiştirilebilir.** ⌘⇧D bazı uygulamalarla çakışırsa Ayarlar → Kısayol bölümünden yeni bir bileşim kaydedilir; menüdeki etiket kendini günceller.

Arayüz native bileşenlerle kuruludur: macOS 26 Liquid Glass yüzeyleri ve sistemin kendi yazı tipleri kullanılır.

## Kurulum

Xcode gerekmez; Command Line Tools yeterlidir.

```bash
xcode-select --install
git clone https://github.com/TheWinderst/Bruecke.git
cd Bruecke
bash build.sh
```

Betik uygulamayı release modunda derler ve `/Applications` altına kurar. macOS 14 ve üzeri desteklenir.

İlk açılışta Erişilebilirlik (Accessibility) izni istenir. Bu izin, seçili metnin okunabilmesi için gereklidir; izin verilmeden `⌘⇧D` çalışmaz. İzni Sistem Ayarları > Gizlilik ve Güvenlik > Erişilebilirlik altından bir kez vermek yeterlidir.

Çeviri motoru Ayarlar bölümünden seçilebilir.

## Veri kaynakları ve atıf

Uygulamada gömülü sözlük verisi yoktur. Bütün içerik, arama anında ilgili sunuculardan canlı olarak çekilir.

- [de.wiktionary.org](https://de.wiktionary.org): artikel, çekim, çoğul ve anlamlar. (CC BY-SA)
- [Tatoeba](https://tatoeba.org): kullanıcıların yazıp çevirdiği örnek cümleler. (CC BY)
- [OpenThesaurus](https://www.openthesaurus.de): Almanca eş anlamlılar. (CC BY-SA)
- Çeviri için varsayılan kaynak, Google'ın anahtar gerektirmeyen halka açık ucudur. Bu resmi bir Google servisi değildir ve önceden haber verilmeden değişebilir. Ayarlar bölümünden açık kaynak [LibreTranslate](https://libretranslate.com) seçeneğine geçilebilir.

İçeriğin telif hakkı ilgili kaynaklara aittir. Bu depo yalnızca uygulama kodunu içerir, sözlük verisini barındırmaz.

## Gizlilik

Brücke'nin kendi sunucusu yoktur. Aranan kelime yalnızca yukarıda listelenen sözlük ve çeviri sunucularına HTTPS üzerinden gönderilir, başka hiçbir yere veri iletilmez. Hesap, kullanıcı takibi ve reklam yoktur.

## Lisans

Telif hakkı © 2026 thewinderst. GNU General Public License v3 (GPL-3.0) altında dağıtılır.

Kodu inceleyebilir, çalıştırabilir ve üzerine geliştirme yapabilirsiniz. Ancak değiştirilmiş bir sürümü dağıtırsanız, onu da aynı GPL-3.0 lisansıyla ve açık kaynak olarak yayımlamanız, telif sahibini belirtmeniz gerekir. Kod kapatılıp özel mülk hâline getirilemez ya da kapalı kaynak bir üründe satılamaz. Ayrıntılar [LICENSE](LICENSE) dosyasındadır.

Geliştiren: thewinderst

---

# Brücke (English)

Brücke is a free, open-source, native macOS German dictionary that lives in the menu bar. Select a German word (or a whole paragraph) in any app, press `⌘⇧D`, and a card pops up with the translation, grammar details, example sentences and pronunciation.

It was designed for Turkish speakers learning German: the default language pair is **German → Turkish**, with a full Turkish → German reverse mode and a curated set of verb+preposition patterns in Turkish. From **Settings → Translation language** you can switch the cards to **German → English**.

**Highlights**

- Instant card next to the cursor: article (color-coded der/die/das), plural, verb forms (gehen → ging → gegangen), IPA, other meanings and German synonyms — all clickable, so you can jump from meaning to meaning and walk back with the card's back button.
- Long-text translation: select a paragraph and it is translated sentence by sentence into a readable card.
- Pronunciation tools: Apple German voices (normal / slow / syllable-by-syllable) plus a microphone practice mode that scores your pronunciation, also inside the flashcard review.
- Flashcards from saved words (flip cards, know/again loop, round summary), lookup history, offline cache for previously looked-up words, Anki-compatible CSV export.
- A right-click "Brücke'de çevir" service, a type-and-translate box (works without Accessibility permission), and a re-bindable global hotkey.

**Build & install** (no Xcode needed, Command Line Tools suffice):

```bash
xcode-select --install
git clone https://github.com/TheWinderst/Bruecke.git
cd Bruecke
bash build.sh
```

The script builds in release mode and installs to `/Applications`. macOS 14+. On first launch macOS asks for Accessibility access (needed to read the selected text for `⌘⇧D`); grant it once in System Settings → Privacy & Security → Accessibility. The app is signed with a local certificate (not notarized), so on first open right-click the app and choose **Open**.

**Data & privacy.** Brücke has no server of its own. The looked-up word is sent over HTTPS only to the public data sources listed above (Wiktionary, Tatoeba, OpenThesaurus, and the chosen translation provider); nothing else leaves the Mac. No accounts, no tracking, no ads. All content is fetched live at lookup time — the repo ships no dictionary data.

**License.** © 2026 thewinderst, GPL-3.0. You may study, run and modify the code; if you distribute a modified version you must publish it under the same license. See [LICENSE](LICENSE).
