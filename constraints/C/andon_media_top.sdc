create_clock -name c_view_clk -period 80.000 -waveform {0.000 40.000} [get_ports view_pclk]
create_clock -name {board_clk_50m} -period 20.000 -waveform {0.000 10.000} [get_ports {clk}]
create_generated_clock -name {mem_clk_41m} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 1.200 -add [get_nets {mem_clk}]
create_generated_clock -name {mem_clk_41m_shift} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 1.200 -phase 180.000 -add [get_nets {mem_clk_shift}]
create_generated_clock -name {pixel_clk_25m} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 2.000 -add [get_nets {pix_clk}]
create_generated_clock -name {serial_clk_125m} -source [get_ports {clk}] -master_clock {board_clk_50m} -multiply_by 2.500 -add [get_nets {serial_clk}]




# C uses its own oscillator. MISO enters only service_rpc_master's two-FF
# synchronizer; wire/oversampling timing is checked by the RPC simulation.
set_false_path -from [get_ports {d_rpc_miso}]
set_output_delay -clock board_clk_50m -max 2.0 [get_ports {d_rpc_mosi d_rpc_sclk}]
set_output_delay -clock board_clk_50m -min 0.0 [get_ports {d_rpc_mosi d_rpc_sclk}]

# Data changes on C falling edge, including 10 ns external route/clock skew.
set_input_delay -clock c_view_clk -clock_fall -max 10.0 [get_ports {view_color[*] view_de view_vsync}]
set_input_delay -clock c_view_clk -clock_fall -min 1.0 [get_ports {view_color[*] view_de view_vsync}]

set_clock_groups -asynchronous -group [get_clocks {c_view_clk}] -group [get_clocks {board_clk_50m}] -group [get_clocks {mem_clk_41m mem_clk_41m_shift}] -group [get_clocks {pixel_clk_25m serial_clk_125m}]

# Original 100kHz A-C clock is GPIO sampled through 3-FF synchronizers.
set_false_path -from [get_ports {rpc_sclk rpc_mosi rpc_req}]

# Retain the original three-board C card timing budget on the migrated R9
# path. SPI DIV=2 launches/captures MISO two 50MHz edges apart.
set_false_path -from [get_ports {rst_n key_next_n key_auto_n key_ack_n}]
set_input_delay -clock [get_clocks {board_clk_50m}] -max 18.000 [get_ports {sd_miso}]
set_input_delay -clock [get_clocks {board_clk_50m}] -min 0.000 [get_ports {sd_miso}]
set_multicycle_path -setup -from [get_ports {sd_miso}] 2
set_multicycle_path -hold -from [get_ports {sd_miso}] 1
set_clock_uncertainty -hold 0.100 [get_clocks {board_clk_50m mem_clk_41m pixel_clk_25m serial_clk_125m}]
