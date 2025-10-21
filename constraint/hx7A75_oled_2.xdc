#------------------------------系统时钟-----------------------------------
create_clock -period 20.000 -name sys_clk [get_ports clk_50m]
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports clk_50m]

#-----------------------------------乒乓�?�?--------------------------------------
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

# oled控制信号
set_property PACKAGE_PIN T4 [get_ports oled_clk]
set_property IOSTANDARD LVCMOS33 [get_ports oled_clk]
set_property PACKAGE_PIN T5 [get_ports oled_dat]
set_property IOSTANDARD LVCMOS33 [get_ports oled_dat]
set_property PACKAGE_PIN U5 [get_ports oled_rst]
set_property IOSTANDARD LVCMOS33 [get_ports oled_rst]
set_property PACKAGE_PIN W6 [get_ports oled_dcn]
set_property IOSTANDARD LVCMOS33 [get_ports oled_dcn]
set_property PACKAGE_PIN W5 [get_ports oled_csn]
set_property IOSTANDARD LVCMOS33 [get_ports oled_csn]





