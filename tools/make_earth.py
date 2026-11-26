#!/usr/bin/env python3
"""2526 Dünyası dokusu (eşdikdörtgen, 1024x512): yanık kıtalar, daralmış buzullar, bulutlar.
Çıktı: assets/textures/earth.png  (Godot'ta ETC2 ile sıkıştırılır)
Kullanım: python3 tools/make_earth.py
"""
import os
import numpy as np
from PIL import Image

W, H = 1024, 512
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rng = np.random.default_rng(2526)

lon = np.linspace(-np.pi, np.pi, W, endpoint=False)
lat = np.linspace(np.pi / 2, -np.pi / 2, H)
LON, LAT = np.meshgrid(lon, lat)
# Küre üzerindeki nokta (dikiş izi olmasın diye 3B gürültü)
P = np.stack([np.cos(LAT) * np.cos(LON), np.sin(LAT), np.cos(LAT) * np.sin(LON)], -1)


def value_noise3(p, freq, seed):
    r = np.random.default_rng(seed)
    n = 64
    grid = r.random((n, n, n)).astype(np.float32)
    q = (p * freq + 32.0)
    i = np.floor(q).astype(int)
    f = q - i
    f = f * f * (3 - 2 * f)
    def g(dx, dy, dz):
        return grid[(i[..., 0] + dx) % n, (i[..., 1] + dy) % n, (i[..., 2] + dz) % n]
    x00 = g(0, 0, 0) * (1 - f[..., 0]) + g(1, 0, 0) * f[..., 0]
    x10 = g(0, 1, 0) * (1 - f[..., 0]) + g(1, 1, 0) * f[..., 0]
    x01 = g(0, 0, 1) * (1 - f[..., 0]) + g(1, 0, 1) * f[..., 0]
    x11 = g(0, 1, 1) * (1 - f[..., 0]) + g(1, 1, 1) * f[..., 0]
    y0 = x00 * (1 - f[..., 1]) + x10 * f[..., 1]
    y1 = x01 * (1 - f[..., 1]) + x11 * f[..., 1]
    return y0 * (1 - f[..., 2]) + y1 * f[..., 2]


def fbm(p, base, octaves, seed):
    total = np.zeros(p.shape[:-1], np.float32)
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        total += amp * value_noise3(p, base * 2 ** o, seed + o)
        norm += amp
        amp *= 0.5
    return total / norm


land_n = fbm(P, 1.6, 6, 10)
land = land_n > 0.545
height = np.clip((land_n - 0.545) / 0.2, 0, 1)
dry = fbm(P, 3.0, 4, 40)
cloud = fbm(P, 3.2, 5, 70)
absl = np.abs(LAT)

img = np.zeros((H, W, 3), np.float32)
# Okyanus: derin lacivert -> sığ turkuaz
ocean_shallow = np.clip(1.0 - (0.545 - land_n) / 0.08, 0, 1)[..., None]
img[:] = np.array([0.04, 0.12, 0.28]) * (1 - ocean_shallow) + np.array([0.08, 0.32, 0.42]) * ocean_shallow
# Kara: yanık kahverengi / kızıl çöl, az yeşil
desert = np.array([0.55, 0.38, 0.22])
burnt = np.array([0.36, 0.22, 0.13])
green = np.array([0.22, 0.32, 0.16])
mix = np.clip((dry[..., None] - 0.35) * 3.0, 0, 1)
landc = burnt * (1 - mix) + desert * mix
greenness = np.clip((0.45 - dry[..., None]) * 4.0, 0, 1) * 0.6
landc = landc * (1 - greenness) + green * greenness
landc = landc * (0.85 + 0.3 * height[..., None])
img = np.where(land[..., None], landc, img)
# Küçülmüş kutup buzulları
ice = np.clip((absl - 1.32) * 8.0, 0, 1)[..., None]
img = img * (1 - ice) + np.array([0.85, 0.88, 0.92]) * ice
# Bulutlar (seyrek, kuru bir gezegen)
c = np.clip((cloud - 0.56) * 4.0, 0, 0.85)[..., None]
img = img * (1 - c) + np.array([0.92, 0.92, 0.94]) * c

out = (np.clip(img, 0, 1) * 255).astype(np.uint8)
os.makedirs(os.path.join(ROOT, "assets", "textures"), exist_ok=True)
Image.fromarray(out).save(os.path.join(ROOT, "assets", "textures", "earth.png"))
print("yazıldı: assets/textures/earth.png")
