#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "==> Derleniyor (release)..."
swift build -c release

# Dosya adı ASCII "Bruecke" (umlaut path/codesign'da sorun çıkarmasın); kullanıcının
# gördüğü ad CFBundleDisplayName ile "Brücke".
APP=".build/Bruecke.app"
BIN=".build/release/Bruecke"

echo "==> Uygulama paketi oluşturuluyor: $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Bruecke"

# NOT: CFBundleIdentifier ve imza sertifikası KASTEN eski (com.apfel.dictionary /
# "Apfel Local Dev") bırakıldı. Bunlar görünmez ve sabit kalınca macOS Erişilebilirlik
# iznini yeniden istemiyor — kullanıcı izni bir kez verdi, öyle kalsın.
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>            <string>Brücke</string>
  <key>CFBundleDisplayName</key>     <string>Brücke</string>
  <key>CFBundleIdentifier</key>      <string>com.apfel.dictionary</string>
  <key>CFBundleExecutable</key>      <string>Bruecke</string>
  <key>CFBundlePackageType</key>     <string>APPL</string>
  <key>CFBundleShortVersionString</key> <string>1.0</string>
  <key>CFBundleVersion</key>         <string>1</string>
  <key>LSMinimumSystemVersion</key>  <string>14.0</string>
  <key>LSUIElement</key>             <true/>
  <key>NSMicrophoneUsageDescription</key>
  <string>Telaffuz alıştırması için söylediklerini dinler.</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>Telaffuzunu değerlendirmek için konuşmanı tanır.</string>
  <key>NSHumanReadableCopyright</key> <string>© 2026 thewinderst · MIT</string>
  <key>NSServices</key>
  <array>
    <dict>
      <key>NSMenuItem</key>
      <dict><key>default</key><string>Brücke'de çevir</string></dict>
      <key>NSMessage</key><string>translateService</string>
      <key>NSPortName</key><string>Bruecke</string>
      <key>NSSendTypes</key>
      <array><string>public.utf8-plain-text</string><string>NSStringPboardType</string></array>
    </dict>
  </array>
</dict>
</plist>
PLIST

CERT="Apfel Local Dev"
if security find-certificate -c "$CERT" >/dev/null 2>&1; then
  echo "==> İmzalanıyor ($CERT)..."
  codesign --force --deep --sign "$CERT" --identifier com.apfel.dictionary "$APP" || codesign --force --deep --sign - "$APP"
else
  echo "==> İmzalanıyor (ad-hoc)..."
  codesign --force --deep --sign - "$APP" || true
fi

echo "==> Eski Apfel sürümü temizleniyor..."
pkill -x Apfel 2>/dev/null || true
rm -rf "/Applications/Apfel.app" 2>/dev/null || true

echo "==> /Applications'a kuruluyor..."
rm -rf "/Applications/Bruecke.app" 2>/dev/null
if cp -R "$APP" "/Applications/Bruecke.app" 2>/dev/null; then
  echo "kuruldu: /Applications/Bruecke.app"
else
  echo "(/Applications'a kopyalanamadı — proje klasöründen çalışacak)"
fi

echo "==> macOS Hizmetler (sağ tık) menüsü tazeleniyor..."
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
"$LSREG" -f "/Applications/Bruecke.app" 2>/dev/null || true
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

echo ""
echo "✅ Bitti — /Applications/Bruecke.app (Brücke) güncellendi"
echo "   Çalıştırmak için:  open /Applications/Bruecke.app"
echo "   Not: sağ-tık menüsünü denediğin uygulamayı (ör. TextEdit, Safari) bir kapatıp yeniden aç."
