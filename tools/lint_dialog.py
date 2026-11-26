#!/usr/bin/env python3
"""Hikâye-mekanik uyum denetimi.

Kural: Bir anlatım (>) satırı fiziksel bir eylem anlatıyorsa (karakter replikleri konuşmadır, sayılmaz), aynı düğümde,
bir önceki metin satırından bu satıra kadar en az bir "@olay", "@qte" ya da "@bekle"
bulunmalıdır. Yani anlatılan hareket ekranda gerçekten canlandırılmalıdır.

Ekranda gösterilmesi gerekmeyen satırlar (ör. geçmiş zaman, hatıra, ekran dışı olaylar)
bir önceki satıra "#fiz: <neden>" yorumu yazılarak denetimden muaf tutulur.

Kullanım: python3 tools/lint_dialog.py [dosya.dlg ...]   (varsayılan: dialogs/*.dlg)
Çıkış kodu: sorun varsa 1.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Fiziksel eylem kökleri (küçük harf). Bakmak, düşünmek gibi fiziksel olmayanlar yok.
PHYSICAL = [
    r"\buzat", r"\buzan", r"\btut(an|uyor|up|tu|muş)", r"\bçek(iyor|ip|ti|erek)", r"\bit(ip|iyor|er|ti)\b",
    r"\bdüş(üyor|tü|üp|müş|er\b|en\b)", r"yığıl", r"devril", r"bastır", r"\bkoy(uyor|up|du)", r"\bver(iyor|ip|di)\b",
    r"sürük", r"kaldır", r"(^|\s)eğil", r"\bvur(uyor|up|arak|du)", r"yumruk", r"bırak(ıyor|ıp|tı)",
    r"\bkap(ıp|ıyor|tı)\b", r"sarıl", r"\biç(iyor|ip|ti)\b", r"\bye(r|di|yip)\b", r"fırlat", r"savur", r"çarp",
    r"sıçr", r"geri çekil", r"dokun", r"kavra", r"yakala", r"titre", r"\boturmuş|\boturuyor", r"\bkalk(ıyor|ıp|tı|mış)",
    r"yürü", r"koş(uyor|up|tu)", r"çırpın", r"yapış", r"\bçıkar(ıp|ıyor|dı)", r"göster", r"salla", r"parçalan",
    r"patlı", r"sendele", r"yuvarlan", r"kay(ıyor|ıp)\b",
]
PHYS_RE = re.compile("|".join(PHYSICAL))
ACTION_RE = re.compile(r"^\s*@(olay|qte|bekle)\b")
TEXT_RE = re.compile(r"^\s*(>|[A-ZÇĞİÖŞÜ]+:)")
NARR_RE = re.compile(r"^\s*>")


def check(path):
    issues = []
    lines = open(path, encoding="utf-8").read().split("\n")
    node = ""
    saw_action = False
    exempt = False
    for i, raw in enumerate(lines, 1):
        line = raw.strip()
        if line.startswith("==="):
            node = line[3:].strip()
            saw_action = False
            exempt = False
            continue
        if line.startswith("#fiz:"):
            exempt = True
            continue
        if not line or line.startswith("#"):
            continue
        if ACTION_RE.match(line):
            saw_action = True
            continue
        if TEXT_RE.match(line):
            text = line.lower()
            m = PHYS_RE.search(text) if NARR_RE.match(line) else None
            if m and not saw_action and not exempt:
                issues.append((i, node, m.group(0), line))
            saw_action = False
            exempt = False
    return issues


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(ROOT, "dialogs", "*.dlg")))
    total = 0
    for f in files:
        for (ln, node, word, line) in check(f):
            total += 1
            print(f"{os.path.relpath(f, ROOT)}:{ln}  [{node}]  '{word}'  →  {line}")
    print(f"\n{total} sahnelenmemiş fiziksel eylem." if total else "Tüm fiziksel eylemler sahnelenmiş.")
    sys.exit(1 if total else 0)


if __name__ == "__main__":
    main()
