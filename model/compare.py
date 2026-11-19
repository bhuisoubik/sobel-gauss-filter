import sys
import numpy as np
from PIL import Image
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

W = H = 64
OW, OH = W - 2, H - 2


def read_hex(path, shape):
    vals = [int(line, 16) for line in open(path).read().split()]
    if len(vals) != shape[0] * shape[1]:
        sys.exit(f"{path}: expected {shape[0]*shape[1]} values, got {len(vals)}")
    return np.array(vals, dtype=np.uint8).reshape(shape)


def psnr(a, b):
    mse = np.mean((a.astype(np.float64) - b.astype(np.float64)) ** 2)
    return float("inf") if mse == 0 else 10 * np.log10(255.0 ** 2 / mse)


def float_refs(img):
    f = img.astype(np.float64)
    p = lambda r, c: f[r:r + OH, c:c + OW]
    gauss = (p(0,0) + 2*p(0,1) + p(0,2) + 2*p(1,0) + 4*p(1,1) + 2*p(1,2)
             + p(2,0) + 2*p(2,1) + p(2,2)) / 16.0
    gx = (p(0,2) - p(0,0)) + 2*(p(1,2) - p(1,0)) + (p(2,2) - p(2,0))
    gy = (p(2,0) - p(0,0)) + 2*(p(2,1) - p(0,1)) + (p(2,2) - p(0,2))
    sobel = np.clip(np.sqrt(gx ** 2 + gy ** 2), 0, 255)
    return gauss, sobel


img = np.array(Image.open("figures/input.png"), dtype=np.uint8)
ref_gauss, ref_sobel = float_refs(img)

runs = {
    "Gaussian":        ("sim/out_gauss.hex",       "data/expected_gauss.hex"),
    "Gaussian (gaps)": ("sim/out_gauss_gaps.hex",  "data/expected_gauss.hex"),
    "Sobel":           ("sim/out_sobel.hex",       "data/expected_sobel.hex"),
    "Sobel (gaps)":    ("sim/out_sobel_gaps.hex",  "data/expected_sobel.hex"),
}

rows, total_bad, hw = [], 0, {}
for name, (hw_path, gold_path) in runs.items():
    out = read_hex(hw_path, (OH, OW))
    gold = read_hex(gold_path, (OH, OW))
    bad = int(np.count_nonzero(out != gold))
    total_bad += bad
    ref = ref_gauss if name.startswith("Gaussian") else ref_sobel
    rows.append((name, bad, psnr(out, ref), float(np.max(np.abs(out - ref)))))
    hw[name] = (out, gold)

with open("figures/results.md", "w") as f:
    f.write("| Run | Mismatches vs golden | PSNR vs float ref (dB) | Max abs error |\n")
    f.write("|---|---|---|---|\n")
    for name, bad, p, mx in rows:
        f.write(f"| {name} | {bad} / {OH*OW} | {p:.2f} | {mx:.2f} |\n")
print(open("figures/results.md").read())

# ---- Figure 1: before / after ----
g, _ = hw["Gaussian"]
s, _ = hw["Sobel"]
fig, ax = plt.subplots(1, 3, figsize=(10, 3.6))
for a, im, t in zip(ax, (img, g, s), ("Input (64x64)", "Gaussian (RTL)", "Sobel (RTL)")):
    a.imshow(im, cmap="gray", vmin=0, vmax=255, interpolation="nearest")
    a.set_title(t); a.axis("off")
plt.tight_layout(); plt.savefig("figures/before_after.png", dpi=150); plt.close()

# ---- Figure 2: RTL vs golden ----
s_out, s_gold = hw["Sobel"]
diff = np.abs(s_out.astype(int) - s_gold.astype(int))
fig, ax = plt.subplots(1, 3, figsize=(10, 3.6))
ax[0].imshow(s_out, cmap="gray", interpolation="nearest"); ax[0].set_title("Sobel: RTL")
ax[1].imshow(s_gold, cmap="gray", interpolation="nearest"); ax[1].set_title("Sobel: golden model")
ax[2].imshow(diff, cmap="gray", vmin=0, vmax=1, interpolation="nearest")
ax[2].set_title(f"|difference|  ({int(np.count_nonzero(diff))} mismatches)")
for a in ax: a.axis("off")
plt.tight_layout(); plt.savefig("figures/sobel_vs_golden.png", dpi=150); plt.close()

# ---- Figure 3: cost of |Gx|+|Gy| vs true magnitude ----
err = s_out.astype(np.float64) - ref_sobel
fig, ax = plt.subplots(1, 3, figsize=(10, 3.6))
ax[0].imshow(ref_sobel, cmap="gray", vmin=0, vmax=255, interpolation="nearest")
ax[0].set_title("Sobel: float sqrt(Gx²+Gy²)")
ax[1].imshow(s_out, cmap="gray", vmin=0, vmax=255, interpolation="nearest")
ax[1].set_title("Sobel: RTL |Gx|+|Gy|")
m = ax[2].imshow(err, cmap="coolwarm", vmin=-100, vmax=100, interpolation="nearest")
ax[2].set_title("Error (RTL - float)")
for a in ax: a.axis("off")
fig.colorbar(m, ax=ax[2], fraction=0.046)
plt.tight_layout(); plt.savefig("figures/approx_error.png", dpi=150); plt.close()

sys.exit(1 if total_bad else 0)