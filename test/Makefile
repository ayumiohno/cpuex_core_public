sv:
	verilator --cc test_with_server.sv -I ../io/*.sv ../core/*.sv ../FPU-Memory/fpu/pipeline/f*.sv test_top.sv ../FPU-Memory/cache/set_associative/cache_controller_word.sv mock_dram.sv ../FPU-Memory/cache/master_fifo_slave.sv
sim:
	verilator --cc test_with_server.sv -exe test_with_server.cpp  -I ../io/*.sv ../core/*.sv ../FPU-Memory/fpu/pipeline/f*.sv test_top.sv ../FPU-Memory/cache/set_associative/cache_controller_word.sv mock_dram.sv ../FPU-Memory/cache/master_fifo_slave.sv
gen:
	make -C obj_dir -f Vtest_with_server.mk
verilog:
	make sv
	make sim
	make gen

# SIM ?= verilator
# TOPLEVEL_LANG ?= verilog

# VERILOG_SOURCES += $(PWD)/mock_dram.sv
# VERILOG_SOURCES += $(PWD)/test_top.sv
# VERILOG_SOURCES += $(PWD)/../io/*.sv
# VERILOG_SOURCES += $(PWD)/../core/*.sv
# VERILOG_SOURCES += $(PWD)/../FPU-Memory/fpu/pipeline/f*.sv
# VERILOG_SOURCES += $(PWD)/../FPU-Memory/cache/cache_controller_word.sv
# VERILOG_SOURCES += $(PWD)/../FPU-Memory/cache/master_fifo_slave.sv
# # use VHDL_SOURCES for VHDL files

# # TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# TOPLEVEL = test_top

# # MODULE is the basename of the Python test file
# MODULE = test

# # include cocotb's make rules to take care of the simulator setup
# include $(shell cocotb-config --makefiles)/Makefile.sim
