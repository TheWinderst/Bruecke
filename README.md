# Brücke 🌉

> Almanca → Türkçe, native bir macOS menü-çubuğu sözlüğü.
> *A native macOS menu-bar dictionary that translates German into Turkish.*

**Brücke** ("köprü") iki dili birbirine bağlar: herhangi bir uygulamada bir Almanca
kelime seç, **⌘⇧D**'ye bas — anlamı, cinsiyeti (der/die/das), çoğulu, fiil çekimi,
örnek cümleleri ve telaffuzuyla şık bir kart açılır. Telaffuzunu mikrofona söyleyip
puan da alabilirsin.

macOS 26'nın gerçek **Liquid Glass** malzemesi, Apple sistem yazı tipleri ve TTS
sesleriyle yazılmıştır — taklit değil, native.

---

## Özellikler

- 🔎 **Seçili kelimeyi anında çevir** — global kısayol **⌘⇧D** veya sağ tık → "Brücke'de çevir"
- 🇩🇪 **Dilbilgisi kartı** — artikel (renk kodlu der/die/das), tür, çoğul, fiil çekimi (mastar → Präteritum → Perfekt)
- 🔊 **Seslendirme** — kelime ve örnek cümleler için Apple TTS (yavaş / hece-hece seçenekleri)
- 🎤 **Telaffuz pratiği** — söyle, Siri tarzı dalga + benzerlik puanı al
- ⭐ **Kaydet & tekrar et** — favori kelimeler ayrı pencerede
- 🌐 **Çeviri motoru seçilebilir** — Google (varsayılan) veya açık kaynak LibreTranslate
- 🪶 Menü çubuğunda yaşar (Dock'ta yer kaplamaz), girişte otomatik başlar

## Kurulum

Xcode gerekmez — yalnızca Command Line Tools yeterli.

```bash
git clone https://github.com/TheWinderst/Bruecke.git
cd Bruecke
bash build.sh
```

`build.sh` uygulamayı derler, `Bruecke.app` paketini oluşturur ve `/Applications`'a
kurar. İlk çalıştırmada macOS, seçili metni okuyabilmesi için **Erişilebilirlik** izni
ister: *Sistem Ayarları → Gizlilik ve Güvenlik → Erişilebilirlik* → Brücke'yi aç.

## Kaynaklar ve atıf

Brücke kendi başına bir sözlük verisi **barındırmaz**; her şeyi senin bilgisayarında,
canlı olarak şu açık kaynaklardan çeker:

| Kaynak | Ne sağlar | Lisans |
|---|---|---|
| [de.wiktionary.org](https://de.wiktionary.org) | tür, cinsiyet, çoğul, fiil biçimleri, örnekler | CC BY-SA |
| [Tatoeba](https://tatoeba.org) | örnek cümleler | CC BY 2.0 FR |
| [OpenThesaurus](https://www.openthesaurus.de) | Almanca eş anlamlılar | CC BY-SA 4.0 / LGPL |
| Google Translate | çeviri (resmî değil — aşağıdaki nota bak) | — |

Bu kaynaklara teşekkürler. İçerikleri kendi lisansları altındadır; bu depo yalnızca
**kodu** MIT altında dağıtır.

## Çeviri motoru hakkında not

Varsayılan çeviri, Google Translate'in **anahtarsız/halka açık** ucunu kullanır. Bu
**resmî bir API değildir**, Google ile bir bağlantımız yoktur ve her an değişebilir/
durabilir. Yalnızca kişisel/eğitim amaçlıdır. Tamamen açık bir alternatif istersen
*Ayarlar → Çeviri motoru → LibreTranslate*'i seçebilir, kendi sunucu adresini
girebilirsin.

## Gizlilik

- **Erişilebilirlik:** ⌘⇧D'ye bastığında seçili metni okumak için sentetik bir ⌘C
  gönderir; panonun eski içeriğini hemen geri yükler. Hiçbir şey kaydedilmez.
- **Ağ:** Seçtiğin kelime, çeviri/sözlük sunucularına **HTTPS** ile gider. Başka hiçbir
  yere veri gönderilmez; uygulamanın kendi sunucusu yoktur.
- **Mikrofon:** Yalnızca telaffuz pratiği sırasında, Apple konuşma tanıma ile kullanılır.
- **Kayıtlı kelimeler** yalnızca yerel `UserDefaults`'ta tutulur.

## Lisans

Kod [MIT Lisansı](LICENSE) altındadır — © 2026 **thewinderst**.

## Katkı

Hata bildirimi ve öneriler için Issues/PR açabilirsiniz. Geliştirme yol haritası için
[ROADMAP.md](ROADMAP.md) dosyasına bakın.
