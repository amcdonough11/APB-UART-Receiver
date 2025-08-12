USER ?= aidan
VERSION ?= 1.0.0
LIB ?= APB_UART
TARGET ?= sim
WAVE_FILE_NAME ?= sim.vcd
TOOL ?= verilator
GTKW ?= waves/$*.gtkw

WAVE_FILE = build/$(USER)_$(LIB)_$*_$(VERSION)/$(TARGET)-$(TOOL)/$(WAVE_FILE_NAME)

%_sim:
	@echo "Running FuseSoC for '$*'"
	fusesoc --verbose run --target=$(TARGET) $(USER):$(LIB):$*:$(VERSION)

%_gtkwaves:
	@echo "Running FuseSoC for '$*'"
	fusesoc --verbose run --target=$(TARGET) $(USER):$(LIB):$*:$(VERSION)

	@echo "Looking for wave files"
	@test -s "$(WAVE_FILE)" || { \
	  echo "Wave file not found or empty: $(WAVE_FILE)"; \
	  echo "  - Did your TB call $$dumpfile(\"$(WAVE_FILE_NAME)\") and $$dumpvars?"; \
	  echo "  - For Verilator, did you enable --trace / --trace-fst in the .core?"; \
	  exit 1; \
	}

	@echo "Running gtkwave"
	gtkwave $(WAVE_FILE) -a $(GTKW)