# Verification

## Run
Prerequisites: Icarus Verilog, GTKWave, Python 3 with `numpy`, `Pillow`, and `matplotlib`

```bash
make test      # golden model, unit tests, full-image tests, comparison and figures
make wave      # open the last waveform in GTKWave
make clean
```

| Target | What it does |
|---|---|
| `make golden` | Generates the test image, golden outputs, and input/golden figures |
| `make sim_unit` | Runs the unit testbenches |
| `make sim_top` | Runs four full-image tests and `cmp` checks |
| `make compare` | Runs `compare.py` and regenerates the result figures |

## Testbenches:
1. **Unit tests** (`tb_line_buffer`, `tb_window`): the line buffer is checked against a delayed copy of its own input, and every 3×3 window is checked against the neighborhood read straight from the image array. Both run with random input stalls.
2. **Full-frame test** (`tb_top`): the whole image is streamed through in both modes, with and without random stalls. Outputs are checked on the fly against golden data and written to a hex file.
3. **Independent comparison**: `cmp` compares the written hex files byte for byte against the golden files. `compare.py` then reports mismatches and error metrics.

The golden model (`model/golden.py`) uses explicit per-window loops so its arithmetic mirrors the RTL's rounding and clamping exactly.

**Result: 0 mismatches out of 3844 pixels** in all four configurations (Gaussian and Sobel, with and without stalls).

## Golden Model
Refer to [GOLDEN.md](golden.md)