###################################################################
# Makefile for Virtual Processor testcode in Modelsim
#
# Copyright (c) 2005-2024 Simon Southwell.
#
# This file is part of VProc.
#
# VProc is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VProc is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VProc. If not, see <http://www.gnu.org/licenses/>.
#
###################################################################
# DEPENDENCIES:
#
#   This test is dependent on the following repositories to be
#   located in the same directory as this repository (as defined by
#   $(GITROOT)):
#   
#     vproc    : https://github.com/wyvernSemi/vproc
#     mem_model: https://github.com/wyvernSemi/mem_model
#     picorv32 : https://github.com/YosysHQ/picorv32
#   
#   The make file will attempt to clone any unfound repository
#   into $(GITROOT). Modify this variable as required.
#
# USER DEFINE GENERICS:
#
#   The $(USRSIMFLAGS) can be overridden on the command line
#   to change the simulation run, with command line
#   make USRSIMFLAGS="<flags>"
#     
#     USRSIMFLAGS="-gUSE_MEM_MODEL=[0|1]" to use HDL mem or mem_model
#     USRSIMFLAGS="-gRV32=[0|1]" to use picorv32 or VProc-rv32
#
#   If VProc-rv32 selected, then it can use the HDL or mem_model.
#   PicoRV32 must select the HDL memory (default).
#
###################################################################

#------------------------------------------------------
# User overridable definitions

# Location of the git directory containing this and the
# dependency repositories.
GITROOT            = ../../../..

# Definitions/include paths etc. to use in compiling vproc and user
# code
USRFLAGS           = -DUSE_INTERNAL_MEMORY -DINT_MEM_TOP=0x1000

# User flags for vsim, such as setting generics
USRSIMFLAGS        =

# Location of the user source code for VProc
USRCDIR            = ./src

# Location of the test directory where generated files placed and sim run
TESTDIR            = .

# Location of the rv32 RISC-V test assembly code
RV32TESTSRCDIR     = ./tests

# Prefix of the test code (with .s file extension) and used for compiled files
RV32TESTPREFIX     = test

# User VProc source code file list (in $(USRCDIR)) to compile
USER_C             = VUserMain0.cpp mem_vproc_api.cpp getopt.c

#------------------------------------------------------
# Constant definitions (but can be overridden)
#
# Simulator list of HDL files to compile
HDLFILELIST        = test.vc

# The location of the VProc repository
VPROC_TOP          = $(GITROOT)/vproc
VPROC_REPO         = https://github.com/wyvernSemi/vproc.git

# Optional Memory model definitions
MEMMODEL_TOP       = $(GITROOT)/mem_model
MEMMODEL_REPO      = https://github.com/wyvernSemi/mem_model
MEM_C              = mem.c mem_model.c
MEMMODELDIR        = $(MEMMODEL_TOP)/src

# The location of the PicoRV32 repository
PICORV32_TOP       = $(GITROOT)/picorv32
PICORV32_REPO      = https://github.com/YosysHQ/picorv32

# The rv32 ISS library
RV32LIB            = librv32.a

# Number of VProc instantiations supported
MAX_NUM_VPROC      = 2

#------------------------------------------------------
# Derived variables and simulator specific settings

SRCDIR             = $(VPROC_TOP)/code
VOBJDIR            = $(TESTDIR)/obj

# Get the help message from the simulator, filtered on Questa
SIMTYPE            = $(shell vsim -help | grep -i questa)

# If the SIMTYPE string is not empty, then this is Questa and a 64-bit compile,
# else assume it's ModelSim and do a 32-bit compile.
ifneq ("$(SIMTYPE)", "")
  ARCHFLAG         = -m64
else
  ARCHFLAG         = -m32
endif

# Simulator/Language specific C/C++ compile and link flags
OPTFLAG            = -g
SIMULATOR          = -DMODELSIM -DINCL_VLOG_MEM_MODEL
SIMINCLUDEFLAG     = -I$(MODEL_TECH)/../include -I../../src -I $(MEMMODELDIR)
SIMFLAGSSO         = -L$(MODEL_TECH) -lmtipli -L../../ -lrv32
POSTVPROCSOFLAGS   = $(WLIB)

# Common flags for vsim
SIMTOP             = test
VLOGFLAGS          = +incdir+$(VPROC_TOP) +define+VPROC_BYTE_ENABLE
VSIMFLAGS          = $(USRSIMFLAGS) -pli $(VPROC_PLI) $(SIMTOP)

# Set OS specific variables between Linux and Windows (MinGW)
ifeq (${OSTYPE}, Linux)
  WLIB             =
else
  WLIB             = -lWs2_32
endif

#------------------------------------------------------
# Calculate the MODEL_TECH path if not set

OSTYPE:=$(shell uname)

ifeq ("$(MODEL_TECH)", "")
  ifeq ($(OSTYPE), Linux)
    PLILIB         = libmtipli.so
  else
    PLILIB         = mtipli.dll
  endif

  VSIMPATH         = $(shell which vsim)
  SIMROOT          = $(shell dirname ${VSIMPATH})/..
  PLILIBPATH       = $(shell find $(SIMROOT) -name "$(PLILIB)")
  MODEL_TECH       = $(shell dirname $(PLILIBPATH))
endif

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: verilog

.PHONY: all, verilog, sim, run, rungui, gui, help, clean

# ......................................
# Include common build rules from vproc
#
include $(VPROC_TOP)/test/makefile.common
#
# ......................................

# Analyse the HDL files
verilog: $(RV32LIB) $(VPROC_TOP) $(MEMMODEL_TOP) $(PICORV32_TOP) $(VPROC_PLI)
	@if [ ! -d "./work" ]; then                            \
	      vlib work;                                       \
	fi
	@vlog $(VLOGFLAGS) -f $(HDLFILELIST)

# Compile the RISC-V assembly test code to an executable for use by rv32 ISS
$(RV32TESTPREFIX).exe: $(RV32TESTSRCDIR)/$(RV32TESTPREFIX).s
	@riscv64-unknown-elf-as.exe -fpic -march=rv32i                               \
	                            -aghlms=$(RV32TESTSRCDIR)/$(RV32TESTPREFIX).list \
	                            -o $(RV32TESTSRCDIR)/$(RV32TESTPREFIX).o         \
	                             $(RV32TESTSRCDIR)/$(RV32TESTPREFIX).s
	@riscv64-unknown-elf-ld.exe $(RV32TESTSRCDIR)/$(RV32TESTPREFIX).o            \
	                             -Ttext 0 -melf32lriscv -o $(RV32TESTPREFIX).exe

# Generate a hex file from the RISC-V executable, suitable for the Verilog $readmemh system task
$(RV32TESTPREFIX).hex: $(RV32TESTPREFIX).exe
	@riscv64-unknown-elf-objcopy -O binary $(RV32TESTPREFIX).exe $(RV32TESTSRCDIR)/$(RV32TESTPREFIX).bin
	@python python/bin2hex.py $(RV32TESTSRCDIR)/$(RV32TESTPREFIX).bin > $(RV32TESTPREFIX).hex

# Compile the rv32 ISS library
$(RV32LIB):
	@make --no-print-directory -C ../../ $(RV32LIB)
	@mv ../../$(RV32LIB) .

# Checkout vproc from github if it doesn't exist at the specified location
$(VPROC_TOP):
	git clone $(VPROC_REPO) $(VPROC_TOP) --recursive

# Checkout mem_model from github if it doesn't exist at the specified location
$(MEMMODEL_TOP):
	git clone $(MEMMODEL_REPO) $(MEMMODEL_TOP) --recursive

# Checkout picorv32 from github if it doesn't exist at the specified location
$(PICORV32_TOP):
	git clone $(PICORV32_REPO) $(PICORV32_TOP) --recursive

#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

# Elaborate and start batch simulation without running
sim: verilog $(RV32TESTPREFIX).hex
	@vsim -c -no_autoacc $(VSIMFLAGS)

# Elaborate and run batch simulation
run: verilog $(RV32TESTPREFIX).hex
	@vsim -c -no_autoacc $(VSIMFLAGS) -do "run -all" -do "quit"

# Elaborate and run GUI simulation if wave.do present, else just start
rungui: verilog $(RV32TESTPREFIX).hex
	@if [ -e wave.do ]; then                                           \
	    vsim -gui -gGUI_RUN=1 -do wave.do $(VSIMFLAGS) -do "run -all"; \
	else                                                               \
	    vsim -gui -gGUI_RUN=1 $(VSIMFLAGS);                            \
	fi

# Alias for rungui
gui: rungui

# Display help message
help:
	@$(info make help          Display this message)
	@$(info make               Build C/C++ and HDL code without running simulation)
	@$(info make sim           Build and run command line interactive (sim not started))
	@$(info make run           Build and run batch simulation)
	@$(info make rungui/gui    Build and run GUI simulation)
	@$(info make clean         clean previous build artefacts)

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

# Clean all intermediate files
clean:
	@make --no-print-directory -C ../../ clean
	@rm -rf $(VPROC_PLI) $(VLIB) $(VOBJDIR) *.wlf transcript $(RV32LIB) $(RV32TESTSRCDIR)/*.o $(RV32TESTSRCDIR)/*.bin $(RV32TESTSRCDIR)/*.list *.exe *.hex
	@if [ -d "./work" ]; then                              \
	    rm -rf work;                                       \
	fi