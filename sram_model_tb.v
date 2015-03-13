`timescale 1ns/100ps
module sram_controller_tb();
  `define SRAM_ADDR_WIDTH 20
  `define SRAM_DATA_WIDTH 16
  reg [`SRAM_ADDR_WIDTH - 1: 0] sram_addr_reg;
  reg oe_n_reg, ce_n_reg, we_n_reg;
  // bidirectional data bus
  wire [`SRAM_DATA_WIDTH - 1: 0] sram_data_inout;
  reg [`SRAM_DATA_WIDTH - 1: 0] data_to_write;
  
  reg data_we;
  assign sram_data_inout = data_we? data_to_write: `SRAM_DATA_WIDTH'hzzzz;
  
  initial
  begin
    data_we = 1'b0;
    dut.mem_array[`SRAM_ADDR_WIDTH'haaaaa] = `SRAM_DATA_WIDTH'h1111;
	 dut.mem_array[`SRAM_ADDR_WIDTH'h55555] = `SRAM_DATA_WIDTH'haaaa;
    oe_n_reg = 1;
	 ce_n_reg = 1;
	 we_n_reg = 1;
    sram_addr_reg = `SRAM_ADDR_WIDTH'haaaaa;
	 //case 1 - activate oe_n_reg, then ce_n_reg
    #10 // 10ns
	 oe_n_reg = 0;
    ce_n_reg = 1;
	 we_n_reg = 1;
	 #10 //20ns
	 oe_n_reg = 0;
	 ce_n_reg = 0;
	 we_n_reg = 1;
	 #10 //30 ns
	 if(sram_data_inout != `SRAM_DATA_WIDTH'h1111)
	 begin
	   $display("test fail");
	   $stop;  
	 end
	 #40 //70ns
	 oe_n_reg = 1;
	 ce_n_reg = 1;
	 we_n_reg = 1;
	 //case 2 - activate ce_n_reg, then oe_n_reg
	 #10 //80ns
	 ce_n_reg = 0;
	 oe_n_reg = 0;
	 we_n_reg = 1;
	 #10 //90 ns
	 if(sram_data_inout != `SRAM_DATA_WIDTH'h1111)
	 begin
	   $display("test fail");
	   $stop;  
	 end
	 #40  //130ns
	 oe_n_reg = 1;
	 ce_n_reg = 1;
	 we_n_reg = 1;
	 //case 3 - the address changes when ce_n_reg and oe_n_reg is active
	 #10  //140ns
	 oe_n_reg = 0;
	 ce_n_reg = 0;
	 we_n_reg = 1;
	 #10 //150 ns
	 if(sram_data_inout != `SRAM_DATA_WIDTH'h1111)
	 begin
	   $display("test fail");
	   $stop;  
	 end
	 #15  //165ns
	 sram_addr_reg = `SRAM_ADDR_WIDTH'h55555;
	 #10 //175
	 if(sram_data_inout != `SRAM_DATA_WIDTH'haaaa)
	 begin
	   $display("test fail");
	   $stop;  
	 end
    #15  //190ns
	 oe_n_reg = 1;
	 ce_n_reg = 1;
	 we_n_reg = 1;
	 //----------------------
	 //write test
	 #10  //200ns
	 oe_n_reg = 0;
	 ce_n_reg = 0;
	 we_n_reg = 1;
	 #10  //210ns
	 oe_n_reg = 0;
	 ce_n_reg = 0;
	 we_n_reg = 0;
	 #10  //220ns
	 data_to_write = `SRAM_DATA_WIDTH'h5555;
	 data_we = 1;
	 #1  //221
	 we_n_reg = 1; // hold data
    #1 //222
	 data_we = 0;
	 #48 ; //270
	 if(dut.mem_array[`SRAM_ADDR_WIDTH'h55555] != `SRAM_DATA_WIDTH'h5555)
	 begin
	   $display("test fail");
		$stop;
	 end
	 $display("test passed");
	 $stop;
  end
  
sram_controller dut(
  // inputs
  .sram_addr_in(sram_addr_reg),
  .oe_n(oe_n_reg),
  .ce_n(ce_n_reg),
  .we_n(we_n_reg),
  // bidirectional data bus
  .sram_data_inout(sram_data_inout)
  );
  
endmodule
