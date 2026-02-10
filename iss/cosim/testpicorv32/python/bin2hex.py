# =============================================================
#
#  Copyright (c) 2026 Simon Southwell. All rights reserved.
#
#  Date: 9th Feb 2026
#
#  Script to convert from binary to 32-bit hex number strings
#  suitable for Verilog $readmemh system task.
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

import sys
 
if len(sys.argv) == 1 :
  # If no command line arguments, set a default file name
  fname = "tests/test.bin"
else :
  # Use first command line argument as the input file name 
  fname = sys.argv[1]

# Open the input file for reading
with open(fname, mode="rb") as hexfile:
    bin_data_list = hexfile.read()

# Initialise count data for constructing words from bytes
count = 0

# Initialise word data
data  = 0

# Loop through all the binary bytes in the input file
for byte in bin_data_list:
  # Add current byte to the top of the word, shifting down
  # already accumulated bytes
  data = (data >> 8) + (byte << 24)
  
  # When the fourth byte is processed, print the word in hex
  # and clear the byte counter and data word value
  if count == 3:
      print(f"{data:08x}")
      count = 0
      data  = 0
  # When the word is not yet completed, increment the count
  else :
      count = count + 1
 