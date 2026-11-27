# EMANET — Proje Çatısı

Bu dosya her oturumda okunur. Buradaki kurallar kullanıcıyla birlikte belirlendi; değiştirmeden önce kullanıcıya sor.

## Ne yapıyoruz
**EMANET**: Godot 4.3 ile geliştirilen, mobil (Android) için 3B, tek oyunculu, **Telltale / The Walking Dead tarzı**
hikâye oyunu. Yıl 2526; Dünya çöküyor, 500 kişilik keşif gemisi EMANET yaşanabilir bir dünya arıyor.
Kahraman (adını ve cinsiyetini oyuncu seçer, varsayılan "Evren"; metinde `{abi/abla}` gibi yer tutucular) gemiye binebilmek için Deniz Arman'ı öldürüp kimliğini alır.
Kız kardeşi Ada gemidedir. Ayrıntılı hikâye: `docs/HIKAYE.md`.

## Değişmez tasarım kuralları
1. **Dram önce gelir.** Oyun hikâye odaklıdır: konuşma, zor kararlar, sonuçları olan seçimler,
   "X bunu hatırlayacak" anları. Uzay yolculuğu, gezegen arayışı ve **gemi içi olaylar** ağırlıklıdır.
2. **Mini oyun YOK.** TWD'de olmayan hiçbir şey yok: bulmaca, beceri oyunu, kaynak mini oyunu vb. eklenmez.
   Gerilim anları yalnızca **hikâyeye bağlı QTE** ile oynanır (`@qte bas / vur / kaydir`, gerekirse `olumcul`).
3. **Dövüş sistemi YOK.** Saldır düğmesi, can barı, düşman dalgası yok. Boğuşmalar QTE ara sahnesidir.
4. **Hikâye ile mekanik birebir uyumlu olmalı.** Bir anlatım satırı fiziksel bir eylem anlatıyorsa
   (uzatmak, tutmak, düşmek, sürüklemek, içmek…) bu **ekranda canlandırılır** (`@olay` + gerekirse `@bekle`).
   Ara sahne de olsa, QTE olmasa da. `python3 tools/lint_dialog.py` temiz geçmeden sahne bitmiş sayılmaz.
   Muafiyet yalnızca hatıra/geçmiş zaman veya sahnede zaten kalıcı durum için: önceki satıra `#fiz: <neden>`.
5. **TWD sunumu:** sinema bantları, yavaş kayan kamera, konuşana göre omuz üstü çekim, aksiyon anlarında
   yazı gizlenir ve sahne oynar; parlayan inceleme noktaları (ipuçları), konuşulabilenlerin üstünde "• • •".
6. **Hikâye uzun ve akıcı olmalı.** Zaman atlamaları ani olmaz; aradaki dönem gemi içi olaylarla yaşanır.
7. Tüm karakterler 18 yaşından büyüktür.
8. Görünüm: çizgi roman stili (kontur + basamaklı gölge, `scripts/toon_style.gd`), bedava CC0 Quaternius modelleri.

## Teknik çatı
- Dil: GDScript. Diyaloglar düz metin `dialogs/*.dlg` (sözdizimi: `docs/DIYALOG_SOZDIZIMI.md`).
- `scripts/main.gd` → `GameLevel` (her seviye bundan türer): diyalog, kamera açıları (`camera_shots`), boğuşma,
  eşya kullanma, ara sahne (`live_world`, `cinematic_hold`), **gözetçi** (takılmayı kurtarır, `Game.boot_log`'a yazar).
- `scripts/character/character_model.gd`: animasyon (UAL1/UAL2), `attach/detach` (elde nesne), `reach/release`
  (kol IK'sı), `bone_marker`, `go_ragdoll` (fizik iskeleti: `ragdoll.gd`).
- `scripts/story.gd` (autoload Story): değişkenler, `{ad}` yer tutucusu, sayılı envanter, açlık/susuzluk/yorgunluk.
- Nesneler kodla üretilir: `scripts/props/props.gd`. Görüntülü arama: `holo_call.gd`.
- Seviyeler: `scripts/levels/onsoz.gd` (Bölüm 1, Dünya) → `scripts/levels/binis.gd` (Bölüm 2, gemi). Gemi iç mekânları kodla
  `scripts/levels/gemi_set.gd` (MegaKit + kod mobilya; bölge 1 iskele/meydan, bölge 2 güverte 8/kamara 412).
  Dünya: `tools/make_earth.py` → `assets/textures/earth.png` + `shaders/earth.gdshader`; uzay: `shaders/stars.gdshader`.
- Kamera: `camera_shots` içinde `[konum, hedef, true]` = kesin yakın çekim (engel denetimi yok). İncelemelerde TWD gibi elle kurulmuş açı.
- Kayıt noktası: `Game.save_checkpoint("binis")`, menüde DEVAM ET.
- Seviye kurucular: `tools/build_onsoz.gd`, `tools/build_hangar.gd` (MegaKit). Varlık dönüştürme: `tools/convert_megakit.py`.

## Hedef cihaz ve performans
Kullanıcının telefonu: **G510, PowerVR Rogue GE8320, Android** (zayıf GPU). Görüntüleyici: GL Compatibility.
Dokular ETC2/ASTC sıkıştırmalı (sıkıştırmasız doku = bellek taşması = çökme). Zayıf GPU'da otomatik düşük kalite.
Yeni nesne/malzeme eklenince sahne başındaki **ön ısıtmaya** (`_prewarm`) eklenir (gölgelendirici derleme donması).

## Her teslimattan önce zorunlu kontroller
1. `python3 tools/lint_dialog.py` → temiz.
2. Godot başsız açılış: betik hatası yok.
3. Uçtan uca test (menü → isim → hikâye → menü) ve **kaos testi** (rastgele seçimler, kaybedilen QTE'ler,
   süre aşımları, gerçek dokunma olayları; takılma dedektörü). Test betikleri `tests_tmp/` altında, APK dışında,
   depoda tutulur (silinmez). `human.gd`: insan gibi oynar, yazı kalış sürelerini ölçer. `camwalls.gd`: kamera duvar dışı.
4. Yeni fiziksel sahneler sanal ekranda (xvfb) görüntülenip gözle kontrol edilir.
5. APK: **release** dışa aktarım (daha hızlı), sürüm kodu artırılır, kullanıcıya dosya olarak gönderilir.

## Kullanıcıyla çalışma
- Türkçe, samimi ("kanka"), **kısa ve net** anlat; uzun teknik dökümlerden kaçın, önemli olanı söyle.
- Hikâyeyi kullanıcının onayı olmadan büyük ölçüde değiştirme; öneri sun, onay al.
- Mekanik oturmadan hikâyeyi ilerletme. Dürüst ol: emin değilsen "test edemedim" de.
- Geliştirme dalı: `claude/selam-gfqgge`.
