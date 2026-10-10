"""Allinea le scansioni italiane delle missioni ai fogli inglesi del mod (stessa geometria),
così le coordinate degli esagoni Impatto restano valide.

Uso: python3 tools/allinea_missioni.py "<Missioni Italiano.pdf>" "<cartella Mods>" [cartella progetto]
Scrive assets/missions/m1..m10.jpg (al posto delle inglesi) e assets/rules/zone_it.jpg, scenari_it.jpg.
"""
import os
import re
import sys

import cv2
import numpy as np
import pymupdf

PDF, MODS = sys.argv[1], os.path.expanduser(sys.argv[2])
PROJ = sys.argv[3] if len(sys.argv) > 3 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
IMAGES = os.path.join(MODS, "Images")
MISSION_IMG = {1: "56BF2B11", 2: "EF7AAEA5", 3: "6EAD8FB7", 4: "573103D4", 5: "D7B615F1", 6: "62A14DC8",
               7: "6DDBA2FD", 8: "990F1CDB", 9: "DCEB2449", 10: "8E72070B"}
OUT_W = 2400

files = {}
for f in os.listdir(IMAGES):
    m = re.search(r"([0-9A-F]{40})\.", f)
    if m:
        files[m.group(1)[:8]] = os.path.join(IMAGES, f)

doc = pymupdf.open(PDF)
pages = []
for p in doc:
    x = p.get_images()[0][0]
    data = doc.extract_image(x)["image"]
    pages.append(cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR))

sift = cv2.SIFT_create(6000)
os.makedirs(os.path.join(PROJ, "assets", "missions"), exist_ok=True)
os.makedirs(os.path.join(PROJ, "assets", "rules"), exist_ok=True)


def gray_small(img, w):
    k = w / img.shape[1]
    return cv2.cvtColor(cv2.resize(img, None, fx=k, fy=k, interpolation=cv2.INTER_AREA), cv2.COLOR_BGR2GRAY), k


for mid in range(1, 11):
    ref = cv2.imread(files[MISSION_IMG[mid]])
    H_ref, W_ref = ref.shape[:2]
    out_h = round(OUT_W * H_ref / W_ref)
    scan = pages[mid - 1]
    best = None
    for rot in (cv2.ROTATE_90_CLOCKWISE, cv2.ROTATE_90_COUNTERCLOCKWISE):
        s = cv2.rotate(scan, rot)
        g1, k1 = gray_small(ref, 1600)
        g2, k2 = gray_small(s, 1600)
        kp1, d1 = sift.detectAndCompute(g1, None)
        kp2, d2 = sift.detectAndCompute(g2, None)
        matches = cv2.FlannBasedMatcher({"algorithm": 1, "trees": 5}, {"checks": 64}).knnMatch(d1, d2, k=2)
        good = [m for m, n in matches if m.distance < 0.72 * n.distance]
        if len(good) < 30:
            continue
        a = np.float32([kp1[m.queryIdx].pt for m in good]) / k1
        b = np.float32([kp2[m.trainIdx].pt for m in good]) / k2
        H, mask = cv2.findHomography(b, a, cv2.RANSAC, 4.0)
        inl = int(mask.sum())
        if best is None or inl > best[0]:
            best = (inl, H, s)
    inl, H, s = best
    S = np.diag([OUT_W / W_ref, OUT_W / W_ref, 1.0])
    warped = cv2.warpPerspective(s, S @ H, (OUT_W, out_h), flags=cv2.INTER_AREA, borderMode=cv2.BORDER_REPLICATE)
    cv2.imwrite(os.path.join(PROJ, "assets", "missions", "m%d.jpg" % mid), warped, [cv2.IMWRITE_JPEG_QUALITY, 88])
    print("missione %d: %d punti in comune" % (mid, inl))

for i, name in ((10, "zone_it"), (11, "scenari_it")):
    if i < len(pages):
        cv2.imwrite(os.path.join(PROJ, "assets", "rules", name + ".jpg"), pages[i], [cv2.IMWRITE_JPEG_QUALITY, 88])
