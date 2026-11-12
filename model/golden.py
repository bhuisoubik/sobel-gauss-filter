import numpy as np
from PIL import Image

W = H = 64

GAUSS = np.array([[1, 2, 1], [2, 4, 2], [1, 2, 1]], dtype=np.int32)
GX = np.array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]], dtype=np.int32)
GY = np.array([[-1, -2, -1], [0, 0, 0], [1, 2, 1]], dtype=np.int32)


def make_test_image():
    """Synthetic image: gradient + checker block + circle + noise-free edges."""
    img = np.zeros((H, W), dtype=np.uint8)
    img[:, :] = np.linspace(0, 160, W, dtype=np.uint8)[None, :]      # horizontal ramp
    img[8:28, 8:28] = (((np.indices((20, 20)).sum(axis=0) // 4) % 2) * 255)  # checker
    yy, xx = np.ogrid[:H, :W]
    img[(yy - 44) ** 2 + (xx - 44) ** 2 < 14 ** 2] = 230             # bright disc
    return img


def windows(img):
    """Yield 3x3 windows in the same order the RTL emits them (row-major, valid only)."""
    for r in range(H - 2):
        for c in range(W - 2):
            yield img[r:r + 3, c:c + 3].astype(np.int32)


def gaussian(img):
    out = [(int((w * GAUSS).sum()) + 8) >> 4 for w in windows(img)]
    return np.array(out, dtype=np.uint8).reshape(H - 2, W - 2)


def sobel(img):
    out = []
    for w in windows(img):
        gx = int((w * GX).sum())
        gy = int((w * GY).sum())
        out.append(min(255, abs(gx) + abs(gy)))
    return np.array(out, dtype=np.uint8).reshape(H - 2, W - 2)


def write_hex(path, arr):
    with open(path, "w") as f:
        for v in arr.flatten():
            f.write(f"{int(v):02x}\n")


if __name__ == "__main__":
    img = make_test_image()
    write_hex("data/input.hex", img)
    write_hex("data/expected_gauss.hex", gaussian(img))
    write_hex("data/expected_sobel.hex", sobel(img))
    Image.fromarray(img).save("figures/input.png")
    Image.fromarray(gaussian(img)).save("figures/golden_gauss.png")
    Image.fromarray(sobel(img)).save("figures/golden_sobel.png")
    print("wrote data/ and figures/")