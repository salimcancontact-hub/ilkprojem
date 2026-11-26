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
- `assets/` – karakter modelleri, animasyonlar, üniforma dokuları
- `addons/quaternius-modular-scifi-pack/` – gemi iç mekânı parçaları
- `tools/` – yardımcı araçlar (ör. üniforma boyayıcı)

Kullanılan hazır varlıkların lisansları: [`CREDITS.md`](CREDITS.md)
