# Brücke

Brücke, menü çubuğunda çalışan, Almancadan Türkçeye native bir macOS sözlüğüdür. Herhangi bir uygulamada bir Almanca kelimeyi seçip `⌘⇧D` kısayoluna basıldığında, kelimenin Türkçe karşılığını ve dil bilgisi ayrıntılarını gösteren bir kart açılır.

Türkçe konuşan ve Almanca öğrenen kullanıcılar için tasarlandı. Anlam doğrudan Türkçe verilir, İngilizce üzerinden geçmek gerekmez. Sözlük sayfaları arasında dolaşmak yerine, çeviriye okunan yerden ulaşılır.

## Özellikler

Bir kelime seçilip kart açıldığında şunlar görünür:

- **Türkçe anlam.** Kartın en üstünde, vurgulu biçimde.
- **Artikel.** der, die, das. Renk kodludur; üç artikel bir bakışta ayırt edilir.
- **Tür ve çoğul.** Kelimenin türü (isim, fiil vb.) ve isimlerde çoğul biçim.
- **Fiil çekimi.** Mastar, Präteritum ve Perfekt biçimleri (örneğin gehen, ging, gegangen).
- **İngilizce karşılık.** Türkçe karşılığın yetersiz kaldığı durumlarda ikinci bir referans.
- **Diğer anlamlar** ve **Almanca eş anlamlılar.**
- **İki örnek cümle**, Türkçe çevirisiyle birlikte.

Kelime ve örnek cümleler Apple'ın Almanca seslendirmesiyle dinlenebilir; normal hız, yavaş veya hece hece seçenekleri vardır. Mikrofona söylenen telaffuz için puan alınabilir. Kaydedilen kelimeler ayrı bir pencerede toplanır ve sonradan tekrar edilebilir.

Elde metin seçili değilse de çeviri yapılabilir. Menü çubuğundaki **Kelime yaz ve çevir…** ile ya da hiçbir yer seçili değilken `⌘⇧D`'ye basınca küçük bir yazma kutusu açılır; kelime yazılıp Enter'a basıldığında aynı kart görünür. Bu yol Erişilebilirlik iznine ihtiyaç duymaz.

Sağ tık menüsünde "Brücke'de çevir" servisi de bulunur.

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
