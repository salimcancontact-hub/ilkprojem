# Diyalog Yazma Rehberi

Diyaloglar `dialogs/` klasöründeki `.dlg` uzantılı düz metin dosyalarıdır. Kod bilmeden yazılabilirler.

## Temel kurallar

| Satır | Anlamı | Örnek |
|---|---|---|
| `# ...` | Yorum (oyunda görünmez) | `# Sahne: hangar` |
| `=== ad` | Yeni bir **düğüm** (sahne parçası) başlatır | `=== baslangic` |
| `KİŞİ: metin` | Karakter repliği (kimlik BÜYÜK harfle) | `ADA: Merhaba.` |
| `> metin` | Anlatım (konuşmacısız) | `> Kapı açılıyor.` |
| `-> ad` | Başka bir düğüme atla. `-> SON` diyaloğu bitirir | `-> kapanis` |
| `~ değişken = değer` | Hikâye değişkeni ayarla (`=`, `+=`, `-=`) | `~ ada_guven += 1` |
| `! metin` | Sol üstte bildirim göster | `! Ada bunu hatırlayacak.` |
| `@if koşul -> ad` | Koşul doğruysa atla | `@if ada_guven >= 2 -> sicak` |
| `@sure saniye -> ad` | Sonraki seçimler zamanlı olur. Süre bitince `ad`'a gider | `@sure 7 -> sessiz` |
| `@olay ad parametreler` | Oyuna özel bir olay gönderir (kamera, animasyon, ses) | `@olay sarsinti 2` |

## Seçimler

Art arda gelen `*` satırları bir seçim grubu oluşturur (en fazla 4 önerilir):

```
@sure 8 -> sessiz
* Korkuyor musun? -> korku
* Verileri bana bırak. -> soguk
  ~ ada_guven -= 1
  ! Ada bunu hatırlayacak.
* {ada_guven >= 1} Gizli seçenek -> ozel
* [Sessiz kal] -> sessiz
```

- Seçeneğin altındaki **girintili** satırlar (boşluk veya tab ile başlayan) sadece o seçilirse çalışır. Buraya replik de yazılabilir.
- `-> hedef` yazılmazsa, seçimden sonra aynı düğümde kaldığı yerden devam eder.
- `{koşul}` ile başlayan seçenek yalnızca koşul doğruysa görünür.
- `@sure` yazılmazsa seçimin süresi yoktur. `@sure 8` yazılıp hedef verilmezse süre bitince son seçenek seçilir.

## Değişkenler ve koşullar

- Değişken adları İngiliz harfleri, rakam ve `_` içerir (`ada_guven`, `kofi_yasiyor`).
- Tanımlanmamış bir değişken `0` sayılır.
- Koşullarda `==`, `!=`, `<`, `>`, `<=`, `>=`, `and`, `or`, `not` kullanılabilir:
  `@if ada_guven >= 2 and not sir_aciga_cikti -> sahne`

## Karakter kimlikleri

`scripts/story.gd` içindeki `CHARACTERS` listesinde ekranda görünen ad ve renk tanımlıdır:
`DENIZ, ADA, MARA, KOFI, LEO, RAFAEL, BARAN, REYES, OKAFOR, HAKEM`. Yeni karakterler oraya eklenir.

## Kamera

Konuşmada kamera konuşana göre otomatik değişir: karşıdaki konuşurken Deniz'in omzunun üstünden çekim yapılır, Deniz konuşurken karşıdakinin omzunun üstünden, anlatım satırlarında ise yandan geniş çekim kullanılır.
