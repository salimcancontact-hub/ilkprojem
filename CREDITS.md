# Kaynaklar ve Lisanslar

Oyunda kullanılan hazır 3D varlıkların tümü **CC0 1.0 (kamu malı)** lisanslıdır: ücretsiz, ticari kullanım dahil serbesttir.

| Varlık | Yazar | Lisans | Konum |
|---|---|---|---|
| Universal Base Characters (gövdeler, saçlar) | [Quaternius](https://quaternius.com) | CC0 1.0 | `assets/characters/` |
| Universal Animation Library (UAL1, UAL2) | [Quaternius](https://quaternius.com) | CC0 1.0 | `assets/animations/` |
| Modular Sci-Fi MegaKit (gemi iç mekânı, 189 parça) | [Quaternius](https://quaternius.com) | CC0 1.0 | `assets/megakit/` |

Quaternius'u desteklemek için: https://www.patreon.com/quaternius

## Projede yapılan değişiklikler
- Üniforma dokuları (`assets/characters/textures/*_body.png`) orijinal gövde dokularından `tools/paint_uniform.py` ile üretilmiştir.
- MegaKit, USD (`.usda`) kaynaklarından `tools/convert_megakit.py` (Blender Python modülü) ile glTF'ye dönüştürülmüştür.
- EMANET hangarı `tools/build_hangar.gd` ile MegaKit parçalarından kurulur.
