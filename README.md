# İlk Projem

Godot 4 ile geliştirilen 3D mobil, tek oyunculu aksiyon/macera oyunu.

## Oynanış (prototip)
EMANET gemisinin hangarında Deniz'i yönet: Ada ile konuş, HAKEM'in güvenlik dronlarını etkisiz hale getir ve enerji hücrelerini topla.

## Kontroller
| Eylem   | Mobil                     | Klavye (test)        |
|---------|---------------------------|----------------------|
| Hareket | Sol alttaki joystick      | WASD / ok tuşları    |
| Kamera  | Ekranın boş yerinde sürükle | Fareyle sürükle    |
| Zıpla   | ZIPLA düğmesi             | Boşluk               |
| Saldır  | SALDIR düğmesi            | J veya F             |
| Konuş   | KONUŞ düğmesi (yakındayken) | E                  |
| Diyalog | Ekrana dokun / seçeneğe dokun | Boşluk, Enter / 1-4 |

## Çalıştırma
1. [Godot 4.3](https://godotengine.org/download) indirin.
2. Godot'da **Import** ile bu klasördeki `project.godot` dosyasını açın.
3. F5 ile oyunu başlatın.

## Android APK üretme
1. Godot 4.3 Android dışa aktarma şablonlarını kurun (Editor → Manage Export Templates).
2. Editor Settings → Export → Android: Android SDK ve Java yolu ile debug keystore'u ayarlayın.
3. Project → Export → **Android** ön ayarı → Export Project (çıktı: `build/emanet.apk`).
   Komut satırı: `godot --headless --path . --export-debug "Android" build/emanet.apk`

## Hikâye ve diyaloglar
- Hikâye belgesi: [`docs/HIKAYE.md`](docs/HIKAYE.md)
- Diyalog yazma rehberi: [`docs/DIYALOG_SOZDIZIMI.md`](docs/DIYALOG_SOZDIZIMI.md)
- Diyalog dosyaları: `dialogs/*.dlg`

> Not: Android/iOS'a dışa aktarırken export ayarlarında "Filters to export non-resource files" alanına `*.dlg` eklenmelidir.

## Proje yapısı
- `scenes/` – sahneler (ana harita, oyuncu, düşman, kristal, arayüz)
- `scripts/` – GDScript kodları (`scripts/dialog/` diyalog sistemi)
- `dialogs/` – diyalog metinleri
- `docs/` – hikâye ve rehber belgeleri
- `assets/` – karakter modelleri, animasyonlar, üniforma dokuları, MegaKit gemi parçaları (`assets/megakit/`)
- `scenes/levels/` – seviyeler (EMANET hangarı)
- `shaders/` – uzay gökyüzü ve gezegen shader'ları
- `tools/` – yardımcı araçlar:
  - `paint_uniform.py` – karakter üniformalarını boyar
  - `convert_megakit.py` – MegaKit USD → glTF (Blender Python modülü gerekir)
  - `build_hangar.gd` – hangarı ASCII haritadan kurar: `godot --headless --path . --script res://tools/build_hangar.gd`

Kullanılan hazır varlıkların lisansları: [`CREDITS.md`](CREDITS.md)
