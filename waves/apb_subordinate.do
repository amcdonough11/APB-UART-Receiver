onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_apb_subordinate/clk
add wave -noupdate /tb_apb_subordinate/n_rst
add wave -noupdate -divider in
add wave -noupdate /tb_apb_subordinate/psel
add wave -noupdate /tb_apb_subordinate/paddr
add wave -noupdate /tb_apb_subordinate/penable
add wave -noupdate /tb_apb_subordinate/pwrite
add wave -noupdate /tb_apb_subordinate/pwdata
add wave -noupdate /tb_apb_subordinate/rx_data
add wave -noupdate /tb_apb_subordinate/data_ready
add wave -noupdate /tb_apb_subordinate/overrun_error
add wave -noupdate /tb_apb_subordinate/framing_error
add wave -noupdate -divider out
add wave -noupdate /tb_apb_subordinate/prdata
add wave -noupdate /tb_apb_subordinate/psaterr
add wave -noupdate /tb_apb_subordinate/data_size
add wave -noupdate /tb_apb_subordinate/bit_period
add wave -noupdate /tb_apb_subordinate/data_read
add wave -noupdate -divider {test names}
add wave -noupdate /tb_apb_subordinate/test_name
add wave -noupdate /tb_apb_subordinate/DUT/state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {129666 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 188
configure wave -valuecolwidth 115
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1050 ns}
