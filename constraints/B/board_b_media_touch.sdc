create_clock -name {board_clk_50m} -period 20.000 -waveform {0.000 10.000} [get_ports {clk}]
create_generated_clock -name {lcd_core_51m25} -source [get_ports {clk}] -master_clock {board_clk_50m} -multiply_by 1.025 -add [get_nets {core_clk}]
create_generated_clock -name {lcd_forward_51m25} -source [get_ports {clk}] -master_clock {board_clk_50m} -multiply_by 1.025 -phase 180.000 -add [get_ports {lcd_pclk}]
create_clock -name {ethernet_rx_125m} -period 8.000 -waveform {0.000 4.000} [get_ports {phy1_rgmii_rx_clk}]
create_generated_clock -name {ethernet_62m5} -source [get_ports {clk}] -master_clock {board_clk_50m} -multiply_by 1.250 -add [get_nets {net_clk}]
create_generated_clock -name {temac_125m} -source [get_ports {clk}] -master_clock {board_clk_50m} -multiply_by 2.500 -add [get_nets {network/temac_clk}]
create_generated_clock -name {temac_125m_90} -source [get_ports {clk}] -master_clock {board_clk_50m} -multiply_by 2.500 -phase 90.000 -add [get_nets {network/temac_clk90}]
set_clock_groups -asynchronous -group [get_clocks {ethernet_rx_125m}] -group [get_clocks {ethernet_62m5 temac_125m temac_125m_90}] -group [get_clocks {lcd_core_51m25 lcd_forward_51m25 board_clk_50m}]


create_generated_clock -name {skin_mem_41m} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 1.200 -add [get_nets {skin_mem_clk}]
create_generated_clock -name {skin_mem_41m_shift} -source [get_ports {clk}] -master_clock {board_clk_50m} -divide_by 1.200 -phase 180.000 -add [get_nets {skin_mem_shift}]
set_clock_groups -asynchronous -group [get_clocks {skin_mem_41m skin_mem_41m_shift}] -group [get_clocks {lcd_core_51m25 lcd_forward_51m25 board_clk_50m ethernet_62m5 temac_125m temac_125m_90 ethernet_rx_125m}]

# Positive hold margin for real FF-to-BRAM data/address paths; no false paths.
set_clock_uncertainty -hold 0.100 [get_clocks {board_clk_50m lcd_core_51m25 lcd_forward_51m25 ethernet_rx_125m ethernet_62m5 temac_125m temac_125m_90 skin_mem_41m skin_mem_41m_shift}]

# EK79001 Rev1.1 p32 requires 5ns setup AND hold in TTL mode.
# Add 0.5ns provisional interconnect skew allowance. Actual PCB/FPC skew
# and loading must still be checked on the finished adapter.
set_output_delay -clock [get_clocks {lcd_forward_51m25}] -max 5.500 [get_ports {lcd_red[*] lcd_green[*] lcd_blue[*] lcd_hsync lcd_vsync lcd_de}]
set_output_delay -clock [get_clocks {lcd_forward_51m25}] -min -5.500 [get_ports {lcd_red[*] lcd_green[*] lcd_blue[*] lcd_hsync lcd_vsync lcd_de}]
