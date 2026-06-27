# Brücke

Almanca öğreniyorum. Takıldığım kelimeler için düzgün bir sözlük lazımdı. Hazır olanları denedim, hiçbiri tam aradığım şey değildi. Sonunda oturup kendiminkini yazdım.

Eskiden şöyleydi: kelimeye takılıyorum, tarayıcıda bir sözlük sitesi açıyorum, doğru sekmeyi buluyorum, bir de reklamın geçmesini bekliyorum. Bir süre sonra bıktım bundan. Brücke menü çubuğunda duruyor. Hangi uygulamada olursan ol, Almanca bir kelimeyi seçip `⌘⇧D` yapıyorsun, anlamı önüne geliyor.

Türkçe konuşup Almanca öğrendiğim için bu ikiliye göre yaptım. İngilizce üzerinden dolaşmana gerek yok.

## Kelimeyi seçince ne geliyor

Kartta göreceklerin:

- **Türkçe anlamı.** En üstte, iri puntoyla.
- **Artikel.** der / die / das. Renkli gösteriyorum, çünkü bunları sürekli karıştırıyorum; renk olunca bir bakışta ayırıyorum.
- **Tür ve çoğul.** İsim mi fiil mi, çoğulu ne.
- **Fiil çekimi.** Mastar, Präteritum, Perfekt. "gehen, ging, gegangen" gibi.
- **İngilizcesi.** Türkçe karşılık bazen tam tutmuyor, o zaman İngilizcesi kurtarıyor.
- **Diğer anlamlar** ve **Almanca eş anlamlılar.**
- **İki örnek cümle**, Türkçe çevirisiyle. Kelimeyi havada görmek bana yetmiyor, cümlenin içinde nasıl durduğunu da görmek istiyorum.

Kelimeyi ve örnek cümleleri sesli dinleyebilirsin; Apple'ın Almanca sesleri, istersen yavaşlatıp hece hece. Mikrofona söyleyip telaffuzunu puanlatabilirsin. Beğendiğin kelimeleri yıldızlayıp ayrı bir pencerede sonradan tekrar edebilirsin.

Görünüm tamamen native: macOS 26 Liquid Glass kartları, sistemin kendi yazı tipleri. Sonradan yapıştırılmış bir uygulama gibi durmuyor.

## Kurulum

Xcode gerekmiyor, Command Line Tools yetiyor (`xcode-select --install`).

```bash
git clone https://github.com/TheWinderst/Bruecke.git
cd Bruecke
bash build.sh
```

İlk açılışta Erişilebilirlik (Accessibility) izni isteyecek. Seçtiğin metni okuyabilmesi için lazım; bu izin olmadan `⌘⇧D` çalışmaz. Sistem Ayarları > Gizlilik ve Güvenlik > Erişilebilirlik altından Brücke'ye izni ver, bir kere vermen yeterli.

## Veri nereden geliyor

İçinde gömülü bir sözlük yok. Her şeyi senin bilgisayarında, o an canlı çekiyor:

- [de.wiktionary.org](https://de.wiktionary.org): artikel, çekim, çoğul, anlamlar. İskeletin çoğu burası. (CC BY-SA)
- [Tatoeba](https://tatoeba.org): örnek cümleler, gerçek insanların yazıp çevirdiği. (CC BY)
- [OpenThesaurus](https://www.openthesaurus.de): Almanca eş anlamlılar. (CC BY-SA)
- Çeviri için varsayılan, Google'ın anahtarsız halka açık ucu. Bu resmi bir Google servisi değil, her an değişebilir. İstersen Ayarlar'dan açık kaynak [LibreTranslate](https://libretranslate.com)'e geçebilirsin.

Bu kaynakları kurup ücretsiz açık tutan herkese teşekkürler. İçeriğin telifi onlara ait; bu depo yalnızca kodu (MIT) içerir, sözlük verisini barındırmaz.

## Gizlilik

Brücke'nin kendi sunucusu yok. Aradığın kelime yalnızca yukarıdaki sözlük ve çeviri sunucularına HTTPS ile gidiyor, başka hiçbir yere bir şey gitmiyor. Hesap yok, takip yok, reklam yok.

## Lisans

MIT. Dilediğin gibi kullan, değiştir, dağıt. Yapan: thewinderst.
