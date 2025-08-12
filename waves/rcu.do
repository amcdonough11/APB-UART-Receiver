onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_rcu/r0/clk
add wave -noupdate /tb_rcu/r0/n_rst
add wave -noupdate -expand -group in -color Magenta /tb_rcu/r0/new_packet_detected
add wave -noupdate -expand -group in -color Magenta /tb_rcu/r0/packet_done
add wave -noupdate -expand -group in -color Magenta /tb_rcu/r0/framing_error
add wave -noupdate /tb_rcu/r0/sbc_clear
add wave -noupdate /tb_rcu/r0/sbc_enable
add wave -noupdate /tb_rcu/r0/load_buffer
add wave -noupdate /tb_rcu/r0/enable_timer
add wave -noupdate -expand -group out -color Orange /tb_rcu/r0/state
add wave -noupdate /tb_rcu/r0/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {273 ns}
