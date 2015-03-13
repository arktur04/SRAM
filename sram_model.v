//--------------------------
// The Verilog behavioral model 
// of the IS61WV102416 - SRAM memory 1M x 16
// inputs UB_n and LB_n are not present
// NOT synthesizable!
//---------------------------- 
`timescale 1ns/100ps
module sram_controller
  #(parameter
    SRAM_DATA_WIDTH = 16,
    SRAM_ADDR_WIDTH = 20,

    //timings for 10 ns version
    TAA = 9.9, // address access time 10 ns
    TOHA = 2.5,  //output hold time 2.5 ns
    TACE = 9.9, // ce_n access time
    TDOE = 6.4, // oe_n access time
    THZOE = 3.9, //oe_n to High-Z output
    TLZOE = 0, // oe_n to Low-Z output
    THZCE = 3.9, //ce_n to High-Z output
    TLZCE = 3, // ce_n to Low-Z output
	 THZWE = 4.9, //we_n to High-Z output
    TLZWE = 2 // we_n to Low-Z output
  )
  (
    // inputs
    input wire [SRAM_ADDR_WIDTH - 1: 0] sram_addr_in,
    input wire oe_n,
    input wire ce_n,
    input wire we_n,
    // bidirectional data bus
    inout wire [SRAM_DATA_WIDTH - 1: 0] sram_data_inout
  );
  
  localparam MEMSIZE = 2 ** SRAM_ADDR_WIDTH;
  //---------------------------------------------------------
  //  model of the device
  //
  //  sram_addr_in  +-----------+ mem_data_reg  +-----+ data_out_reg
  //  ------------->| MEM_ARRAY |-------------->|     |------------->
  //        data_in |           |               |     |              
  //        ------->|           |               |     |
  //                +-----------+               |     |   
  //                                            +--+-+|
  //                          z_state_oe ------>| &|1||
  //                          z_state_ce ------>|  | ||
  //                                            +--+ || 
  //                          z_state_we ------>|    ||
  //                                            +--+-+|
  //                       data_valid_oe ------>| &|  |
  //                       data_valid_ce ------>|  |  |
  //                                            +--+--+  
  
  reg [SRAM_DATA_WIDTH - 1: 0] mem_data_reg, data_out_reg;
  
  reg [SRAM_DATA_WIDTH - 1: 0] mem_array[0: MEMSIZE - 1];
  
  reg z_state_oe, z_state_ce, z_state_we, data_valid_oe, data_valid_ce;
  
  initial
  begin
    z_state_oe = 1'b1;
	 z_state_ce = 1'b1; 
	 z_state_we = 1'b0;
	 data_valid_oe = 1'b0;
	 data_valid_ce = 1'b0;
  end
  
  always@(sram_addr_in)
  begin
    #TOHA mem_data_reg = {SRAM_DATA_WIDTH{1'bx}};
	 #(TAA - TOHA) mem_data_reg = mem_array[sram_addr_in];
  end
 
  always@(negedge ce_n)
  begin
    #TLZCE z_state_ce = 1'b0;
  end
  
  always@(negedge ce_n)
  begin
    #TACE data_valid_ce = 1'b1;
  end
  
  always@(negedge oe_n)
  begin
    #TLZOE z_state_oe = 1'b0;
  end
  
  always@(negedge oe_n)
  begin
    #TDOE data_valid_oe = 1'b1;
  end
  
  always@(posedge ce_n)
  begin
    #THZCE z_state_ce = 1'b1;
	 data_valid_ce = 1'b0;
  end
  
  always@(posedge oe_n)
  begin
    #THZOE z_state_oe = 1'b1;
	 data_valid_oe = 1'b0;
  end
  
  always@(negedge we_n)
  begin
    #THZWE z_state_we = 1'b1;
  end
  
  always@(posedge we_n)
  begin
    mem_array[sram_addr_in] = sram_data_inout;
    #TLZWE z_state_we = 1'b0;
  end
  
  wire z_state = z_state_oe || z_state_ce || z_state_we;
  wire data_valid = data_valid_oe && data_valid_ce;
  
  always@*
  begin
    if(z_state)
      data_out_reg = {SRAM_DATA_WIDTH{1'bz}};
	 else if(!data_valid)
	   data_out_reg = {SRAM_DATA_WIDTH{1'bx}};
	 else
	   data_out_reg = mem_data_reg;
  end
  
  assign sram_data_inout = data_out_reg;
endmodule
