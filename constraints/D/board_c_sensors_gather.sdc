create_clock -name sys_clk -period 20.000 [get_ports sys_clk]
set_false_path -from [get_ports {rst_n replay_n fault_time_n fault_frequency_n fault_coupling_n key_next_n key_clear_n key_mode_n}]
set_output_delay -clock sys_clk -max 2.0 [get_ports {seg_data[*] seg_sel[*]}]
set_output_delay -clock sys_clk -min 0.0 [get_ports {seg_data[*] seg_sel[*]}]
create_generated_clock -name pixel_clk_12m -source [get_ports sys_clk] -master_clock sys_clk -divide_by 4.000 -add [get_nets {video_output$monitor/pixel_clk}]
set_clock_groups -asynchronous -group [get_clocks {sys_clk}] -group [get_clocks {pixel_clk_12m}]

# Board A's SCLK/MOSI are sampled by service_rpc_slave's explicit two-FF
# synchronizers, not used as FPGA clocks. 3.125MHz/50MHz oversampling is tested.
set_false_path -from [get_ports {sensor_rx rpc_sclk}]
set_output_delay -clock sys_clk -max 2.0 [get_ports {sensor_tx}]
set_output_delay -clock sys_clk -min 0.0 [get_ports {sensor_tx}]
# C launches palette/DE/VS on falling 12.5 MHz edge; A samples rising.
set_output_delay -clock pixel_clk_12m -max 10.0 [get_ports {view_color[*] view_de view_vsync}]
set_output_delay -clock pixel_clk_12m -min 1.0 [get_ports {view_color[*] view_de view_vsync}]
