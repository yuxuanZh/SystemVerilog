TIMESCALE=include/timescale.sv

SRC_DIR=src
TEST_DIR=test

TOP=$(TEST_DIR)/top.sv
IFC=$(SRC_DIR)/ifc_test.sv
DUT=unknown
BENCH=$(TEST_DIR)/testbench.sv

SRC_ALL=$(SRC_DIR)/*.sv $(TEST_DIR)/*.sv

.PHONY: help

help:
	@echo "The following make targets are supported:" ;\
	echo " bench  - builds the testbench";\
	echo " exec   - execute and transform vcd";\
	echo " run    - builds the tessbench and exec test";\
	echo " wave   - convert vcd to vpd";\
	echo " draw   - builds the testbench, runs and show the wave";\
	echo " expand - expands veritedium directives (autoargs, inst etc.)";\
	echo " indent - automatically indents verilog and c files" ;\
	echo " clean  - cleans testbench and intermediate files" ;\
	echo " help   - show this information";\

indent:
	emacs --batch *.sv -f verilog-batch-indent
	indent -linux *.c *.h
	rm *~

dut:
	vcs -full64 -PP -sverilog +define+SV +define+VPD +lint=all,noVCDE -notice $(IFC) $(DUT)

bench:
	vcs -full64 -PP -sverilog +define+SV +define+VPD +lint=all,noVCDE -notice $(TIMESCALE) $(SRC_ALL) -o testbench.exe

exec:
	./testbench.exe
	vcs -vpd2vcd vcdplus.vpd waveform.vcd

run:
	make bench
	make exec

wave:
	vcs -vpd2vcd vcdplus.vpd waveform.vcd
	gtkwave waveform.vcd &

draw:
	make run wave

clean:
	rm -rf *.o *~ *.vpd sim* csrc DVEfiles *daidir *exe *.key *.vdb *.vcd *.cst
