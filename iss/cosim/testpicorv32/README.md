# Test Bench for Comparing VProc with rv32 ISS and PicoRV32 HDL

*** **THIS TEST BENCH IS FOR QUESTA OR MODEL SIM SIMULATORS ONLY** ***

## Dependencies

  This test is dependent on the following repositories to be located in the same directory as this repository, as defined by
  `$(GITROOT)` make file variable:
  
* vproc    : https://github.com/wyvernSemi/vproc
* mem_model: https://github.com/wyvernSemi/mem_model
* picorv32 : https://github.com/YosysHQ/picorv32
  
The make file will attempt to clone any unfound repository into `$(GITROOT)`. Modify this variable as required.

## Test Bench Architecture

The diagram below shows a summary of the test bench architecture. The main processor can be selected between a *VProc* virtual processor running the *rv32* ISS or a PcioRV32 RTL implementation in Verilog, selected on a test bench parameter (see [next section](#user-defined-generics)). The selected processor has a genertic memory mapped address bus on which is attached a timer, a UART and some memory. The memory can be selected with a generic to be either a behavioural HDL memory (64 KBytes) or the *mem_model* co-simulation VIP. Locally, logic implements a software interrupt function, which is memory mapped on the bus, and some simulation control, where a "halt" function is mapped into the address function to allows the running RISC-V program to stop the simulation. Chip selects for all these memory mapped functions are also implemented in the top level test bench, along with functionality to generate a clock at 100MHz and an active low reset.

<p align="center"><img src="images/picorv32_tb.png"></p>

## User Defined Generics

The `$(USRSIMFLAGS)` can be overridden on the command line to change the simulation run, with the shell command:
```
  make USRSIMFLAGS="<flags>"
```

Use `USRSIMFLAGS="-gUSE_MEM_MODEL=[0|1]"` to select between HDL mem or *mem_model*, and `USRSIMFLAGS="-gRV32=[0|1]"` to select between *PicoRV32* or *VProc* with *rv32*. If *VProc* with *rv32* is selected, then it can use either HDL memory or *mem_model*. If the *PicoRV32* is selected then the HDL memory must be selected (default).


## Running the simulation

The simplest means to build and run a simulation is to execute the following command in the console:

```
  make run
```
This will run a simulation using the *VProc*/*rv32* processor and the HDL memory, executing a `test[.exe]` RISC-V programcompiled from `test/test.s`. Other options are available and can be display with a `make help` command, giving:

```
  make help          Display this message
  make               Build C/C++ and HDL code without running simulation
  make sim           Build and run command line interactive (sim not started)
  make run           Build and run batch simulation
  make rungui/gui    Build and run GUI simulation
  make clean         clean previous build artefacts

```

### vusermain.cfg

Control and configuration of the *rv32* ISS can be done in the `vusermain.cfg` file. This acts lie a virtual command line option input, and the default file has the follwing entry:

```
  vusermain0 -HT -b -A 0x00000040 -t test.exe
```

There are many more options to configure the ISS, and adding a `-h` to the `vusermain,.cfg` file will, instead of running the program, will give the following output:

```
Usage: vusermain0 -t <test executable> [-hHebdrg][-n <num instructions>]
      [-S <start addr>][-A <brk addr>][-D <debug o/p filename>][-p <port num>]
   -t specify test executable (default test.exe)
   -n specify number of instructions to run (default 0, i.e. run until unimp)
   -d Enable disassemble mode (default off)
   -r Enable run-time disassemble mode (default off. Overridden by -d)
   -C Use cycle count for internal mtime timer (default real-time)
   -a display ABI register names when disassembling (default x names)
   -T Use external memory mapped timer model (default internal)
   -H Halt on unimplemented instructions (default trap)
   -e Halt on ecall instruction (default trap)
   -E Halt on ebreak instruction (default trap)
   -b Halt at a specific address (default off)
   -A Specify halt address if -b active (default 0x00000040)
   -D Specify file for debug output (default stdout)
   -g Enable remote gdb mode (default disabled)
   -p Specify remote GDB port number (default 49152)
   -S Specify start address (default 0)
   -h display this help message

```

These option allow for such things as displaying runtime diassembled output, conditions for halting the program execution and for connecting a `gdb` debugger.

## The Test Bench Memory Map

Memory start from address `0x00000000`, with the HDL memory model top address being `0x00010000`. The diagram below shows how the peripherals are mapped into the address space.

<p align="center"><img src="images/iss_mmap.png" width=800></p>


## Files in this Directory

* **test.v**: top level test bench, incorporating the HDL memory module (`ram`)
* **test.vc**: List of HDL files to compile for the simulator
* **mtimer.v**: timer module to implemenat a RISC-V Zicsr `mtime` and `mtimecmp` registers.
* **uart.v**: An HDL model of a uart TX function, mapped into the memory space.
* **makefile**: a make file to compile and run all the necessary files for the simulation
* **vusermain.cfg**: *rv32* ISS configuration file
* **wave.do**: a default set of signals to display in the simulator GUI waveform viewer
* **test/test.s:** The default RISC-V test program assembly code
* **src/VUserMain0.cpp**: The main *VProc* node 0 program to run. This includes the fuctionality to configure and run the *rv32* ISS and interface it to the address bus in the simulation via the *VProc* API.
* **src/VUserMain0.h**: header for the above.
* **src/mem_vproc_api.cpp**: A set of wrapper functions around the *VProc* API to add simulation time for memory accesses
* **src/mem_vproc_api.h**: header for the above
* **src/getopt.c**: an implementaion of `getopt` for use on Windows
* **python/bin2hex.py**: A python script to convert a binary file from the RISC-V gcc compilation into a test hex output suitibale for use with Verilog's `$readmemh` system task.
* **README.md**: this file
* **images/\***: Images for use by this file