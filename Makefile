# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# make.bat assembles with ..\..\Bin\beebasm.exe; run.bat launches the emulator.
.PHONY: all build help
all: build

build:
	cmd /c .\make.bat

help:
	@echo make        - build twisted.ssd (from just-rasters.asm, template.ssd) (runs make.bat)
	@echo make help   - this list
	@echo run.bat     - launch the emulator on the result (not a make target)
