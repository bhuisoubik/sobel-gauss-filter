# Top Level Fitler

## Hardware Interface table for `top_filter`:

### Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `W` | `64` | Input/output image width in pixels |
| `H` | `64` | Input/output image height in pixels |

### Ports

| Port | Direction | Width | Description |
| --- | --- | --- | --- |
| `clk` | Input | 1 | System clock |
| `rst_n` | Input | 1 | Active-low reset |
| `en` | Input | 1 | Module/pipeline enable signal |
| `mode` | Input | 1 | Filter select (`0` = Gaussian, `1` = Sobel) |
| `pix_in` | Input | 8 | Unsigned 8-bit grayscale input pixel |
| `valid_out` | Output | 1 | High when `pix_out` carries valid filtered pixel data |
| `pix_out` | Output | 8 | Unsigned 8-bit filtered output pixel |
