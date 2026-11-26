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

## Anlık tuşa basma (QTE)

Telltale tarzı gerilim anları. Başarıya ve başarısızlığa göre farklı düğümlere gidilir:

```
@qte bas 1.4 "İT" -> itti | itemedi              # süre dolmadan dokun
@qte vur 3.2 9 "KALDIR" -> kaldirdi | kaldiramadi  # 3.2 sn içinde 9 kez dokun
@qte kaydir sol 1.6 "EĞİL" -> egildi | vuruldu     # sola kaydır (sol, sag, yukari, asagi)
```

- Tırnak içindeki yazı halkanın içinde görünür (isteğe bağlı).
- `olumcul` eklenirse kaybedince karakter ölür ("ÖLDÜN — Tekrar dene") ve aynı an biraz kolaylaşarak tekrarlanır:
  `@qte vur 3.2 12 "İT" olumcul -> kazandi | kazandi`
- Tehlike arttıkça ekranın kenarları kırmızıya döner; hızlı dokunmada güç çubuğu görünür.
- `@olay bogusma` ile oyuncu ve konuşulan karakter karşı karşıya itişir (QTE gücüne göre öne/geri gider); `@olay bogusma_bitti` ile biter.
- Sonuç `son_qte_basarili` değişkenine de yazılır.
- Klavyede: Boşluk/Enter (bas, vur), ok tuşları (kaydır).

## Ara sahne olayları

| Olay | Anlamı |
|---|---|
| `@olay kamera ad` | Seviyede tanımlı kamera açısına geç (`oyuncu`: oyuncu kamerası, `otomatik`: konuşana göre). İnceleme düğümleri yakın çekimle başlar (mobilde yazı okunsun) |
| `@olay sarsinti 0.4 0.6` | Kamera sarsıntısı (güç, süre) |
| `@olay siyah` / `kararti 2` / `aydinlat 2` | Ekranı anında/yavaşça karart veya aç |
| `@olay baslik Metin \| Alt yazı` | Ortada sinematik başlık kartı |
| `@olay gorev Metin` | Ekranın üstündeki görev yazısı |
| `@olay anim KİŞİ Animasyon` | Karaktere tek seferlik hareket yaptır |
| `@olay esya_al kimlik` / `esya_ver kimlik` | Çantaya eşya ekle/çıkar (eşyalar `scripts/story.gd` → `ITEMS`) |
| `@bekle 1.5` | Yazı gizlenir, sahnedeki aksiyon 1,5 sn kendi başına oynar |

### Fiziksel eylem kuralı (zorunlu, araçla denetlenir)
Hikâyede bir karakter fiziksel bir şey yapıyorsa (bir şey uzatıyor, alıyor, içiyor, düşüyor, sürüklüyor) bunun ekranda da karşılığı olmalı:
önce `@olay` ile hareketi başlat, gerekirse `@bekle` ile görünmesini sağla, sonra anlatım satırını yaz.
Yere düşen/bayılan karakterler kilitli duruşta ya da ragdoll olarak kalır, konuşma bitince ayağa kalkmaz.

**Denetim:** `python3 tools/lint_dialog.py` her anlatım (`>`) satırını tarar. Fiziksel bir fiil
(uzatmak, tutmak, çekmek, düşmek, bastırmak, koymak…) geçiyorsa ve önünde `@olay`/`@qte`/`@bekle`
yoksa hata verir. Ekranda gösterilmesi gerekmeyen satırlar (hatıra, sahnede zaten kalıcı olan bir durum)
bir önceki satıra açıklamalı `#fiz: <neden>` yazılarak muaf tutulur:

```
#fiz: hatıra (geçmiş zaman)
> Bir saat önce onu kalabalığın altından çekip çıkarmıştın.
```

Yeni bir sahne yazıldıktan sonra APK çıkarmadan önce bu araç temiz geçmelidir.

## Metin yer tutucuları

- `{ad}` → oyuncunun seçtiği isim.
- `{erkek/kadın}` → cinsiyete göre: erkekse ilki, kadınsa ikincisi. Örn. `ADA: {Abi/Abla}?`, `Gururlu {adam/kadın}.`
- `{degisken}` → hikâye değişkeninin değeri.

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
