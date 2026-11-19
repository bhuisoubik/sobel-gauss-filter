IVFLAGS = -g2012 -Wall

golden:
	python model/golden.py

sim/tb_line_buffer.vvp: tb/tb_line_buffer.v rtl/line_buffer.v
	iverilog $(IVFLAGS) -o $@ $^

sim/tb_window.vvp: tb/tb_window.v rtl/window_3x3.v rtl/line_buffer.v
	iverilog $(IVFLAGS) -o $@ $^

sim_unit: sim/tb_line_buffer.vvp sim/tb_window.vvp
	python -c "import subprocess, pathlib; pathlib.Path('sim').mkdir(exist_ok=True); [pathlib.Path(log).write_bytes(subprocess.run(cmd, stdout=subprocess.PIPE).stdout) for cmd, log in [(['vvp', 'sim/tb_line_buffer.vvp'], 'sim/lb.log'), (['vvp', 'sim/tb_window.vvp'], 'sim/win.log'), (['vvp', 'sim/tb_window.vvp', '+GAPS'], 'sim/win_gaps.log')]]; logs = ''.join(pathlib.Path(p).read_text() for p in ['sim/lb.log', 'sim/win.log', 'sim/win_gaps.log']); print(logs); exit(1) if 'FAIL' in logs else print('ALL UNIT TESTS PASSED')"

RTL = rtl/top_filter.v rtl/window_3x3.v rtl/line_buffer.v \
      rtl/conv3x3.v rtl/sobel_mag.v rtl/saturate.v

sim/tb_top.vvp: tb/tb_top.v $(RTL)
	@if not exist sim mkdir sim
	iverilog $(IVFLAGS) -o $@ $^

sim_top: sim/tb_top.vvp
	vvp $< +MODE=0 +OUT=sim/out_gauss.hex      +VCD=sim/top_gauss.vcd      > sim/top_gauss.log
	vvp $< +MODE=1 +OUT=sim/out_sobel.hex      +VCD=sim/top_sobel.vcd      > sim/top_sobel.log
	vvp $< +MODE=0 +GAPS +OUT=sim/out_gauss_gaps.hex +VCD=sim/top_gauss_gaps.vcd > sim/top_gauss_gaps.log
	vvp $< +MODE=1 +GAPS +OUT=sim/out_sobel_gaps.hex +VCD=sim/top_sobel_gaps.vcd > sim/top_sobel_gaps.log
	@findstr /C:"FAIL" sim\top_*.log >nul && exit /b 1 || exit /b 0
	fc /b sim\out_gauss.hex data\expected_gauss.hex >nul
	fc /b sim\out_sobel.hex data\expected_sobel.hex >nul
	fc /b sim\out_gauss_gaps.hex data\expected_gauss.hex >nul
	fc /b sim\out_sobel_gaps.hex data\expected_sobel.hex >nul
	@echo ALL TOP TESTS PASSED

compare: sim_top
	python model/compare.py

test: sim_unit sim_top compare
	@echo "ALL TESTS PASSED"

stats:
	yosys -q -p "read_verilog $(RTL); synth -top top_filter -flatten; tee -o sim/yosys_generic.txt stat"
	yosys -q -p "read_verilog $(RTL); synth_xilinx -top top_filter -flatten; tee -o sim/yosys_xilinx.txt stat"


clean:
	python -c "import shutil; shutil.rmtree('sim', ignore_errors=True)"
