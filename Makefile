IVERILOG ?= iverilog
VVP ?= vvp
SINGLE = $(filter-out RISCV_Pipeline/testbench.v,$(wildcard RISCV_Pipeline/*.v))
COMMON = RISCV_Pipeline/alu.v RISCV_Pipeline/aludec.v RISCV_Pipeline/maindec.v \
         RISCV_Pipeline/controller.v RISCV_Pipeline/extend.v RISCV_Pipeline/flopenrc.v RISCV_Pipeline/mux2.v
DUAL = $(filter-out Superscalar_Dual_Issue/tb_dual.v,$(wildcard Superscalar_Dual_Issue/*.v))

.PHONY: test single dual assemble clean

test: single dual

build:
	mkdir -p build

build/pipeline.vvp: $(SINGLE) tests/tb_pipeline.v | build
	$(IVERILOG) -g2012 -s tb_pipeline -o $@ $^

single: build/pipeline.vvp
	@set -e; for p in 1 2 3 4; do \
	  $(VVP) $< +P=$$p +VCD=build/p$$p.vcd > build/p$$p.log; \
	  cat build/p$$p.log; \
	done

build/dual.vvp: $(COMMON) $(DUAL) Superscalar_Dual_Issue/tb_dual.v | build
	$(IVERILOG) -g2012 -s tb_dual -o $@ $^

build/dual_regfile.vvp: Superscalar_Dual_Issue/dual_regfile.v tests/tb_dual_regfile.v | build
	$(IVERILOG) -g2012 -s tb_dual_regfile -o $@ $^

dual: build/dual.vvp build/dual_regfile.vvp
	$(VVP) build/dual.vvp > build/dual.log
	@cat build/dual.log
	$(VVP) build/dual_regfile.vvp > build/dual_regfile.log
	@cat build/dual_regfile.log

assemble:
	./scripts/assemble.sh

clean:
	rm -rf build

.PHONY: harris
build/harris.vvp: $(SINGLE) RISCV_Pipeline/testbench.v | build
	$(IVERILOG) -g2012 -s testbench -o $@ $^

harris: build/harris.vvp
	$(VVP) $<
