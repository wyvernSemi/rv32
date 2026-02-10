# =============================================================
#
#  Copyright (c) 2026 Simon Southwell. All rights reserved.
#
#  Date: 9th Feb 2026
#
#  Test program to measure ISS vs RTL performance
#
#  This file is part of the base RISC-V instruction set simulator
#  (rv32_cpu).
#
#  This code is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This code is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this code. If not, see <http://www.gnu.org/licenses/>.
#
# =============================================================

        .file   "test.s"
        .text
        .org 0

        .equ     HALT_ADDR,            0x00000040
        .equ     SIM_FINISH_ADDR,      0xaffffff8
        .equ     RWADDRBASE,           0x00001000
        .equ     MEMLOOPCOUNT,         100
        .equ     COMPLOOPCOUNT,        1000
        .equ     TESTFINISHED,         93

# Program reset point
_start: .global _start
        .global main

         # Jump to reset code
         jal      reset_vector

         .org HALT_ADDR
halt:
         li a7, 1
         la a1, SIM_FINISH_ADDR
         sw a7, 0(a1)
idle:
         j  idle


# Reset routine
reset_vector:
         li      ra, 0
         li      sp, 0
         li      gp, 0
         li      tp, 0
         li      t0, 0
         li      t1, 0
         li      t2, 0
         li      s0, 0
         li      s1, 0
         li      a0, 0
         li      a1, 0
         li      a2, 0
         li      a3, 0
         li      a4, 0
         li      a5, 0
         li      a6, 0
         li      a7, 0
         li      s2, 0
         li      s3, 0
         li      s4, 0
         li      s5, 0
         li      s6, 0
         li      s7, 0
         li      s8, 0
         li      s9, 0
         li      s10,0
         li      s11,0
         li      t3, 0
         li      t4, 0
         li      t5, 0
         li      t6, 0
         jal main

# Main test code
main:
         li     t0, MEMLOOPCOUNT
         la     a0, RWADDRBASE
         la     a1, RWADDRBASE
mainmemloop:
         sw     t0, 0(a0)
         addi   a0, a0, 4
         lw     t1, 0(a1)
         bne    t0, t1, fail
         addi   a1, a1, 4
         addi   t0, t0, -1
         li     t3, COMPLOOPCOUNT
         jal    compute

compute:
         addi   t3, t3, -1
         bnez   t3, compute
         bnez   t0, mainmemloop
         jal    pass


# Fail routine (after riscv-test-env standard)
fail:
         sll    gp, gp, 1
         or     gp, gp, 1
         li     a7, TESTFINISHED
         mv     a0, gp
         jal    halt
         
# Pass routine (after riscv-test-env standard)
pass:
         li     gp, 1
         li     a7, TESTFINISHED
         li     a0, 0
         jal    halt
