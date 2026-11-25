## Golden Model

- Bit-exact software reference for the RTL, used to check every output pixel
- A second, ideal floating-point reference (in `compare.py`) to measure the cost of fixed-point choices

**Inputs and outputs**
- Input: 64×64, 8-bit grayscale test image, generated in code (horizontal ramp, 20×20 checker block, bright disc)
- Outputs written to `data/`:
  - `input.hex`: pixel stream in row-major order, one hex byte per line
  - `expected_gauss.hex` and `expected_sobel.hex`: 62×62 valid-only results
- Also saves `input.png`, `golden_gauss.png`, `golden_sobel.png` in `figures/`

**Algorithm**
- Walks every 3×3 window in the same order the RTL emits them (row-major, valid positions only, no padding)
- Gaussian: `(sum(window × [1 2 1; 2 4 2; 1 2 1]) + 8) >> 4`
- Sobel: `min(255, abs(Gx) + abs(Gy))`, with Gx and Gy from the standard Sobel kernels
- All arithmetic uses integers, so rounding and clamping match the hardware exactly

**Design choices**
- Explicit per-window loops instead of a vectorized convolution, so each step mirrors one RTL window and mismatches are easy to trace
- Same output order and size as the RTL, so files compare byte for byte with no reindexing

**Comparison script (`compare.py`)**
- Reads RTL output hex files from `sim/` and compares them to the golden files
- Reports mismatch count per run (Gaussian and Sobel, with and without stalls); exits nonzero on any mismatch
- Builds an ideal float reference (Gaussian without rounding, Sobel with `sqrt(Gx² + Gy²)`) and reports PSNR and max absolute error against it
- Generates `before_after.png`, `sobel_vs_golden.png`, `approx_error.png`, and `results.md`

**Verification role**
- Layer 1: testbench checks each output against the golden value on the fly
- Layer 2: `cmp` compares the written RTL output with the golden hex files
- Layer 3: `compare.py` quantifies fixed-point error against the float reference
- Result: 0 mismatches out of 3844 pixels in all four configurations