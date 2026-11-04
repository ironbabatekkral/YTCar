# YTCar

Reklam engelli YouTube tarayıcısı (iPhone) + araba ekranı sahnesi (CarPlay, Apple entitlement'ı gerektirir). Kişisel kullanım için, App Store'a gönderilmez.

## Ne çalışır, ne çalışmaz

| Özellik | Durum |
| --- | --- |
| Telefonda YouTube (`m.youtube.com`), Google hesabıyla giriş | Çalışması beklenir (derlenip cihazda denenmedi) |
| Reklam engeli: ağ kuralları + sayfa scripti | Strip mantığı Node'da test edildi; gerçek YouTube'da denenmedi. YouTube sık değiştirir, script güncellemesi gerekebilir |
| Arka planda ses | `UIBackgroundModes: audio` ayarlı, denenmedi |
| AirPlay butonu (araca yansıtma denemesi) | Deneysel; araç/YouTube desteğine bağlı |
| **Araba ekranında tarayıcı** | **Apple'ın `com.apple.developer.carplay-video` entitlement'ı olmadan çalışmaz.** Ücretsiz Apple ID ile alınamaz, TrollStore iOS 27'de yok |

Araba sahnesi (`CarSceneDelegate`) kodda hazır; entitlement olmadığında iOS sahneyi hiç oluşturmaz, uygulama zararsızca sadece telefonda çalışır.

## Windows'ta derleme ve kurulum

1. Bu klasörü GitHub'da (özel) bir repoya push edin.
2. Actions sekmesi > **Build IPA** otomatik çalışır (veya *Run workflow*). Bitince `YTCar-ipa` artifact'ını indirip zip'ten `YTCar.ipa`'yı çıkarın.
3. [Sideloadly](https://sideloadly.io) ile ücretsiz Apple ID kullanarak iPhone'a kurun (USB). Ücretsiz imza 7 gün geçerli, süre dolunca aynı IPA'yı yeniden kurun.
4. iPhone'da Ayarlar > Gizlilik ve Güvenlik > Geliştirici Modu açık olmalı; Ayarlar > Genel > VPN ve Aygıt Yönetimi'nden profile güvenin.

IPA imzasız üretilir; imzayı Sideloadly atar.

## Araba entitlement'ı (ileride)

Ücretli hesap + Apple onayı gelirse: `Entitlements/CarPlay.entitlements.example` dosyasını `CarPlay.entitlements` olarak kopyalayın, `project.yml`'de `CODE_SIGN_ENTITLEMENTS` değerine yolunu yazın ve kendi hesabınızla imzalayın. iOS 26.3'ten beri bu entitlement başka CarPlay entitlement'larıyla birleştirilemez.

## Yapı

- `Sources/BrowserViewController.swift`: WKWebView + araç çubuğu, telefon ve araba penceresi ortak.
- `Sources/AdBlocker.swift`: kural listesini bir kez derler, script'i yükler.
- `Resources/AdRules.json`: ağ engelleme kuralları.
- `Resources/AdBlock.js`: oynatıcı verisinden reklam alanlarını siler, kalan reklamı sessize alıp sona sarar.
- `project.yml`: XcodeGen tanımı (`.xcodeproj` CI'da üretilir).
