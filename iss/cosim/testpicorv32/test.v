//=============================================================
//
// Copyright (c) 2016 Simon Southwell. All rights reserved.
//
// Date: 8th Feb 2026
//
// Test bench for PicoRV32 and VProc+rv32
//
// This code is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The code is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this code. If not, see <http://www.gnu.org/licenses/>.
//
//=============================================================

`timescale 1ns / 1ps

//-------------------------------------------------------------
// Top level test module
//-------------------------------------------------------------
module test
#(
  parameter VCD_DUMP           = 0,
  parameter DEBUG_STOP         = 0,
  parameter GUI_RUN            = 0,
  parameter RV32               = 1,
  parameter USE_MEM_MODEL      = 0
);

//-------------------------------------------------------------
// Local parameter definitions
//-------------------------------------------------------------

localparam  CLK_PERIOD         = 10;
localparam  TIMEOUT_COUNT      = 20 * (1000000/ CLK_PERIOD);
localparam  RESET_CYCLES       = 10;

localparam  MEMSEG             = 4'h0;
localparam  UARTSEG            = 4'h8;

localparam  TIMERSTARTADDR     = 32'hAFFFFFE0;
localparam  TIMERENDADDR       = 32'hAFFFFFEC;

localparam  HALT_ADDR          = 32'hAFFFFFF8;
localparam  INT_ADDR           = 32'hAFFFFFFC;

localparam  MEM_BYTES_SIZE     = 65536;

localparam  CLKFREQMHZ         = 1000 / CLK_PERIOD;

//-------------------------------------------------------------
// Signal declarations
//-------------------------------------------------------------

// State signals
reg         clk;
reg         swirq;
integer     count;

// Wire signals
wire        resetn;

wire        mem_valid;
wire        mem_instr;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire [31:0] mem_rdata;
wire        mem_ready;

wire        trap;

wire        readdatavalid;
wire [31:0] memmodelrdata;
wire [31:0] timreaddata;
wire [31:0] uartreaddata;

wire        cs1;
wire        cs2;
wire        cs3;
wire        cs4;
wire        cs5;

wire        timirq;
wire [31:0] irq;
wire        halt;

//-------------------------------------------------------------
// Combinatorial logic
//-------------------------------------------------------------

// Generate the reset signal
assign resetn    = (count > RESET_CYCLES);

// Always ready on writes, or mem_model readdatavalid on reads
assign mem_ready = (mem_valid & |mem_wstrb) | readdatavalid;

// Address decode
assign cs1       = (mem_valid == 1'b1) && mem_addr < MEM_BYTES_SIZE;
assign cs2       = (mem_valid == 1'b1) && mem_addr >= TIMERSTARTADDR && mem_addr <= TIMERENDADDR;
assign cs3       = (mem_valid == 1'b1) && mem_addr[31:28] == UARTSEG;
assign cs4       = (mem_valid == 1'b1) && mem_addr == INT_ADDR;
assign cs5       = (mem_valid == 1'b1) && mem_addr == HALT_ADDR;

// Read data mux
assign mem_rdata = cs1 ? memmodelrdata :
                   cs2 ? timreaddata   :
                   cs3 ? uartreaddata  :
                         32'hXXXXXXXX;
// IRQ generation
assign irq       = {32'h00000000, timirq, swirq};

// Simulation halt request
assign halt      = cs5 & mem_valid & mem_wstrb[0] & mem_wdata[0];

// -----------------------------------------------
// IRQ generation process
// -----------------------------------------------

always @(posedge clk)
begin
  if (cs4 == 1'b1 && mem_wstrb[0] == 1'b1)
  begin
    swirq        <= mem_wdata[0];
  end
end

//-------------------------------------------------------------
// Initialisation and clock generation
//-------------------------------------------------------------

initial
begin
  // If specified, dump a VCD file
  if (VCD_DUMP != 0)
  begin
    $dumpfile("waves.vcd");
    $dumpvars(0, test);
  end

  clk = 1;

`ifndef VERILATOR
  #0                  // Ensure first x->1 clock edge is complete before initialisation
`endif

  // If specified, stop for debugger attachment
  if (DEBUG_STOP != 0)
  begin
    $display("\n***********************************************");
    $display("* Stopping simulation for debugger attachment *");
    $display("***********************************************\n");
    $stop;
  end

  count = 0;
  forever # (CLK_PERIOD/2) clk = ~clk;
end

//-------------------------------------------------------------
// Simulation timeout and halt control
//-------------------------------------------------------------

always @(posedge clk)
begin
  count = count + 1;
  if ((TIMEOUT_COUNT != 0 && count == TIMEOUT_COUNT) || halt == 1'b1)
  begin
    if (count == TIMEOUT_COUNT)
    begin
      $display("***FATAL ERROR...simulation timed out!");
    end
    if (GUI_RUN == 0)
    begin
      $finish;
    end
    else
    begin
      $stop;
    end
  end
end

generate
if (RV32 == 0)
begin

    //-------------------------------------------------------------
    // PicoRV32
    //-------------------------------------------------------------
    picorv32 #(
        .ENABLE_COUNTERS       (1),
        .ENABLE_COUNTERS64     (1),
        .ENABLE_REGS_16_31     (1),
        .ENABLE_REGS_DUALPORT  (1),
        .TWO_STAGE_SHIFT       (1),
        .BARREL_SHIFTER        (1),
        .TWO_CYCLE_COMPARE     (1),
        .TWO_CYCLE_ALU         (1),
        .COMPRESSED_ISA        (0),
        .CATCH_MISALIGN        (1),
        .CATCH_ILLINSN         (1),
        .ENABLE_PCPI           (0),
        .ENABLE_MUL            (1),
        .ENABLE_FAST_MUL       (0),
        .ENABLE_DIV            (1),
        .ENABLE_IRQ            (1),
        .ENABLE_IRQ_QREGS      (0),
        .ENABLE_IRQ_TIMER      (0),
        .ENABLE_TRACE          (0),
        .REGS_INIT_ZERO        (0),
        .MASKED_IRQ            (32'hfffffffc),
        .LATCHED_IRQ           (32'hffffffff),
        .PROGADDR_RESET        (32'h00000000),
        .PROGADDR_IRQ          (32'h00000004),
        .STACKADDR             (32'h0000ffff)
    ) picorv32_i (
        // Clock and reset
        .clk                   (clk),
        .resetn                (resetn),

        // Address bus
        .mem_valid             (mem_valid),
        .mem_addr              (mem_addr),
        .mem_wdata             (mem_wdata),
        .mem_wstrb             (mem_wstrb),
        .mem_instr             (mem_instr),
        .mem_ready             (mem_ready),
        .mem_rdata             (mem_rdata),

        // Unused ports
        .mem_la_read           (),
        .mem_la_write          (),
        .mem_la_addr           (),
        .mem_la_wdata          (),
        .mem_la_wstrb          (),

        .trap                  (trap),

        .pcpi_valid            (),
        .pcpi_insn             (),
        .pcpi_rs1              (),
        .pcpi_rs2              (),
        .pcpi_wr               (1'b0),
        .pcpi_rd               (32'h00000000),
        .pcpi_wait             (1'b0),
        .pcpi_ready            (1'b0),

        .irq                   (irq),
        .eoi                   (),

        .trace_valid           (),
        .trace_data            ()
    );
end
else
begin

    wire        WE;
    wire        RD;
    wire        Update;
    wire  [3:0] BE;

    //-------------------------------------------------------------
    // Virtual Processor
    //-------------------------------------------------------------
    VProc vp
    (
        .Clk                   (clk),
        .Addr                  (mem_addr),
        .WE                    (WE),
        .RD                    (RD),
        .DataOut               (mem_wdata),
        .DataIn                (mem_rdata),
        .BE                    (BE),
        .WRAck                 (1'b1),
        .RDAck                 (mem_ready),
        .Interrupt             (irq[2:0]),
        .Update                (Update),
        .UpdateResponse        (Update),
        .Node                  (4'h0)
    );

  assign mem_valid = WE | RD;
  assign mem_wstrb = BE & {4{WE}};
  assign mem_instr = mem_valid && ~|mem_wstrb && mem_addr < 32'h00001000;
  assign trap      = 1'b0;

end
endgenerate

generate
if (USE_MEM_MODEL == 1)
begin
  //-------------------------------------------------------------
  // Memory model
  //-------------------------------------------------------------

  mem_model mem
  (
    .clk                       (clk),
    .rst_n                     (resetn),

    .address                   ({mem_addr[31:2], 2'b00}),
    .write                     (mem_valid & |mem_wstrb & cs1),
    .writedata                 (mem_wdata),
    .byteenable                (mem_wstrb),
    .read                      (mem_valid & ~|mem_wstrb),
    .readdata                  (memmodelrdata),
    .readdatavalid             (readdatavalid),

    // Unused ports
    .rx_waitrequest            (),
    .rx_burstcount             (),
    .rx_address                (),
    .rx_read                   (1'b0),
    .rx_readdata               (),
    .rx_readdatavalid          (),

    .tx_waitrequest            (),
    .tx_burstcount             (),
    .tx_address                (),
    .tx_write                  (1'b0),
    .tx_writedata              (),

    .wr_port_valid             (1'b0),
    .wr_port_data              (),
    .wr_port_addr              ()

  );
end
else
begin

  ram mem (
    .clk                      (clk),
    .WE                       (mem_valid & |mem_wstrb),
    .CS                       (cs1),
    .BE                       (mem_wstrb),
    .DI                       (mem_wdata),
    .A                        (mem_addr[15:2]),
    .DO                       (mem_rdata)
  );
  assign readdatavalid = mem_valid & ~|mem_wstrb;
end

endgenerate

 // ---------------------------------------------------------
 // Timer
 // ---------------------------------------------------------

 mtimer #(.CLKFREQMHZ (CLKFREQMHZ)) timer
   (
     .clk                      (clk),
     .nreset                   (resetn),

     .cs                       (cs2),
     .addr                     (mem_addr[3:2]),
     .wr                       (mem_valid & |mem_wstrb& cs2),
     .wdata                    (mem_wdata),
     .rd                       (mem_valid & ~|mem_wstrb),
     .rdata                    (timreaddata),
     .rvalid                   (),

     .irq                      (timirq)
   );

 // ---------------------------------------------------------
 // UART
 // ---------------------------------------------------------

  uart_model console
  (
    .clk                       (clk),
    .nreset                    (resetn),

    .cs                        (cs3),
    .addr                      (mem_addr[4:0]),
    .wr                        (mem_valid & |mem_wstrb & cs3),
    .wdata                     (mem_wdata),
    .rd                        (mem_valid & ~|mem_wstrb),
    .rdata                     (uartreaddata),
    .rvalid                    ()
  );

endmodule

// =========================================================
// Simple 64K byte (default) memory model with byte enables
// =========================================================

module ram 
#(parameter MEMWORDS          = 16384
)
(
    input         clk,
    input         WE,
    input         CS,
    input   [3:0] BE,
    input  [31:0] DI,
    input  [13:0] A,
    output [31:0] DO
);

reg [31:0] Mem [0:MEMWORDS-1];

initial
begin
  $readmemh("test.hex", Mem);
end

assign DO    = Mem[A];

always @(posedge clk)
begin
    if (WE && CS)
    begin
      Mem[A] <= {BE[3] ? DI[31:24] : Mem[A][31:24],
                 BE[2] ? DI[23:16] : Mem[A][23:16],
                 BE[1] ? DI[15:8]  : Mem[A][15:8],
                 BE[0] ? DI[7:0]   : Mem[A][7:0]};
    end
    
end

endmodule