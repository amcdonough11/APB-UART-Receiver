onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_apb_uart_rx/clk
add wave -noupdate /tb_apb_uart_rx/n_rst
add wave -noupdate -divider APB
add wave -noupdate -divider In
add wave -noupdate /tb_apb_uart_rx/psel
add wave -noupdate /tb_apb_uart_rx/paddr
add wave -noupdate /tb_apb_uart_rx/penable
add wave -noupdate /tb_apb_uart_rx/pwrite
add wave -noupdate /tb_apb_uart_rx/pwdata
add wave -noupdate -divider Out
add wave -noupdate /tb_apb_uart_rx/prdata
add wave -noupdate /tb_apb_uart_rx/psaterr
add wave -noupdate -divider {Test Name}
add wave -noupdate /tb_apb_uart_rx/test_name
add wave -noupdate -divider UART
add wave -noupdate -divider IN
add wave -noupdate /tb_apb_uart_rx/serial_in
add wave -noupdate /tb_apb_uart_rx/DUT/rcv/shift_strobe
add wave -noupdate /tb_apb_uart_rx/DUT/rcv/new_packet_detected
add wave -noupdate /tb_apb_uart_rx/DUT/rcv/packet_done
add wave -noupdate -divider out
add wave -noupdate /tb_apb_uart_rx/DUT/rcv/rx_data
add wave -noupdate /tb_apb_uart_rx/DUT/rcv/data_ready
add wave -noupdate /tb_apb_uart_rx/DUT/rcv/overrun_error
add wave -noupdate /tb_apb_uart_rx/DUT/rcv/framing_error
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {33567482 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {32529385 ps} {33975137 ps}
