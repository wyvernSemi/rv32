onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /test/CLK_PERIOD
add wave -noupdate -radix unsigned /test/TIMEOUT_COUNT
add wave -noupdate -radix decimal /test/VCD_DUMP
add wave -noupdate -radix unsigned /test/DEBUG_STOP
add wave -noupdate -radix unsigned /test/RV32
add wave -noupdate /test/clk
add wave -noupdate /test/resetn
add wave -noupdate -radix unsigned /test/count
add wave -noupdate /test/mem_addr
add wave -noupdate /test/mem_instr
add wave -noupdate /test/mem_rdata
add wave -noupdate /test/mem_ready
add wave -noupdate /test/mem_valid
add wave -noupdate /test/mem_wdata
add wave -noupdate /test/mem_wstrb
add wave -noupdate /test/trap
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1120000 ps} 0} {{Cursor 2} {1130000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1088634 ps} {1230018 ps}
