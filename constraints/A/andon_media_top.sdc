create_clock -name {camera_pclk} -period 20.000 -waveform {0.000 10.000} [get_ports {cam_pclk}]
create_clock -name {board_clk_50m} -period 20.000 -waveform {0.000 10.000} [get_ports {clk}]
create_generated_clock -name {mem_clk_41m} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 1.200 -add [get_nets {mem_clk}]
create_generated_clock -name {mem_clk_41m_shift} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 1.200 -phase 180.000 -add [get_nets {mem_clk_shift}]
create_generated_clock -name {pixel_clk_25m} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 2.000 -add [get_nets {pix_clk}]
create_generated_clock -name {serial_clk_125m} -source [get_ports {clk}] -master_clock {board_clk_50m} -multiply_by 2.500 -add [get_nets {serial_clk}]

create_generated_clock -name {camera_sccb_1m} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 50 -add [get_nets {u_ov5640/i2c_dri_clk}]

set_clock_groups -asynchronous -group [get_clocks {board_clk_50m}] -group [get_clocks {camera_sccb_1m}] -group [get_clocks {camera_pclk}] -group [get_clocks {mem_clk_41m mem_clk_41m_shift}] -group [get_clocks {pixel_clk_25m serial_clk_125m}]

# SCCB divider has reset-dependent phase. Configuration/capture reset release and status crossings are explicitly synchronized.



# RPC uses 3-FF input synchronizers on local 50 MHz; 100 kHz SCLK is data.
set_false_path -from [get_ports {rpc_miso rpc_ack}]
