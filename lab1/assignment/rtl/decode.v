// vhdl: sudhakar yalamanchili
// translated to verilog by yehowshua with vhd2l and manual tuning
// https://github.com/ldoolitt/vhd2vl

// instruction decode unit.
// note that this module differs from the text in the following ways
// 1. the memtoreg mux is implemented in this module instead of a (syntactically) 
// different pipeline stage. 

module decode(
input wire clock,
input wire reset,
input wire [31:0] instruction,
input wire [31:0] memory_data,
input wire [31:0] alu_result,
input wire regwrite,
input wire memtoreg,
input wire [4:0] wreg_address,

output wire [31:0] register_rs,
output wire [31:0] register_rt,
output wire [31:0] sign_extend,
output wire [4:0] wreg_rd,
output wire [4:0] wreg_rt
);

//internals
wire [31:0] write_data;
wire [4:0] read_register_1_address;
wire [4:0] read_register_2_address;
wire [15:0] instruction_immediate_value;

reg [31:0] register_array [0:31];

  integer i;
  initial begin
    for (i=0;i<32;i=i+1)
      register_array[i] = i;
  end

  assign read_register_1_address = instruction[25:21];
  assign read_register_2_address = instruction[20:16];
  assign instruction_immediate_value = instruction[15:0];

  //read both registers from register file
  assign register_rs = register_array[read_register_1_address];
  assign register_rt = register_array[read_register_2_address];

  // write to the regfile
  assign write_data = (memtoreg == 1'b1) ? memory_data : alu_result[31:0];
  always @ (posedge clock) begin
  if(regwrite == 1'b1)
  register_array[wreg_address] <= write_data;
  end

  // sign extend 16-bits to 32-bits
  assign sign_extend = { {16{instruction_immediate_value[15]}}, instruction_immediate_value};

  // move possible write destinations to execute stage                   
  assign wreg_rd = instruction[15:11];
  assign wreg_rt = instruction[20:16];

endmodule