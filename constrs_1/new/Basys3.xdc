# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
	
# LEDs
#set_property PACKAGE_PIN U16 	 [get_ports {f_enable}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {f_enable}]
#set_property PACKAGE_PIN E19 	 [get_ports {random_enable}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {random_enable}]
#set_property PACKAGE_PIN U19 	 [get_ports {data_rx[2]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[2]}]
#set_property PACKAGE_PIN V19 	 [get_ports {data_rx[3]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[3]}]
#set_property PACKAGE_PIN W18 	 [get_ports {data_rx[4]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[4]}]
#set_property PACKAGE_PIN U15 	 [get_ports {data_rx[5]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[5]}]


#set_property PACKAGE_PIN U14 	 [get_ports {data_rx[6]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[6]}]
#set_property PACKAGE_PIN V14 	 [get_ports {data_rx[7]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {data_rx[7]}]

#7 segment display
#set_property PACKAGE_PIN W7 	 [get_ports {seg[0]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]
#set_property PACKAGE_PIN W6 	 [get_ports {seg[1]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]
#set_property PACKAGE_PIN U8 	 [get_ports {seg[2]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]
#set_property PACKAGE_PIN V8 	 [get_ports {seg[3]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]
#set_property PACKAGE_PIN U5 	 [get_ports {seg[4]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]
#set_property PACKAGE_PIN V5 	 [get_ports {seg[5]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]
#set_property PACKAGE_PIN U7 	 [get_ports {seg[6]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]

#set_property PACKAGE_PIN U2 	 [get_ports {an[0]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
#set_property PACKAGE_PIN U4 	 [get_ports {an[1]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
#set_property PACKAGE_PIN V4 	 [get_ports {an[2]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
#set_property PACKAGE_PIN W4 	 [get_ports {an[3]}]					
#set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]

##Buttons
## btnL
#set_property PACKAGE_PIN W19 	 [get_ports btn]						
#set_property IOSTANDARD LVCMOS33 [get_ports btn]

set_property PACKAGE_PIN V17 	 [get_ports random_enable]						
set_property IOSTANDARD LVCMOS33 [get_ports random_enable]
set_property PACKAGE_PIN V16 	 [get_ports f_enable]						
set_property IOSTANDARD LVCMOS33 [get_ports f_enable]
set_property PACKAGE_PIN W16 	 [get_ports g_enable]						
set_property IOSTANDARD LVCMOS33 [get_ports g_enable]
#set_property PACKAGE_PIN W17 	 [get_ports h_enable]						
#set_property IOSTANDARD LVCMOS33 [get_ports h_enable]
## btnR
set_property PACKAGE_PIN T17 	 [get_ports reset]						
set_property IOSTANDARD LVCMOS33 [get_ports reset]


set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets random_inst/rng_bit_generator/ro1/ring1]

##USB-RS232 Interface
set_property PACKAGE_PIN B18 [get_ports rx]						
set_property IOSTANDARD LVCMOS33 [get_ports rx]
set_property PACKAGE_PIN A18 [get_ports tx]						
set_property IOSTANDARD LVCMOS33 [get_ports tx]