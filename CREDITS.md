# Kaynaklar ve Lisanslar

Oyunda kullanılan hazır 3D varlıkların tümü **CC0 1.0 (kamu malı)** lisanslıdır: ücretsiz, ticari kullanım dahil serbesttir.

| Varlık | Yazar | Lisans | Konum |
|---|---|---|---|
| Universal Base Characters (gövdeler, saçlar) | [Quaternius](https://quaternius.com) | CC0 1.0 | `assets/characters/` |
| Universal Animation Library (UAL1, UAL2) | [Quaternius](https://quaternius.com) | CC0 1.0 | `assets/animations/` |
| Modular Sci-Fi Pack (gemi iç mekânı) | [Quaternius](https://quaternius.com), Godot uyarlaması: Malcolm Nixon | CC0 1.0 | `addons/quaternius-modular-scifi-pack/` |

Quaternius'u desteklemek için: https://www.patreon.com/quaternius

## Projede yapılan değişiklikler
- Üniforma dokuları (`assets/characters/textures/*_body.png`) orijinal gövde dokularından `tools/paint_uniform.py` ile üretilmiştir.
- Sci-fi paketi Godot 3'ten Godot 4'e dönüştürülmüş; eski "occluder" düğümleri kaldırılmış ve çarpışma kutularının boyutları (`extents` → `size`) düzeltilmiştir.
