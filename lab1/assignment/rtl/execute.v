// vhdl: sudhakar yalamanchili
// translated to verilog by yehowshua with vhd2l and manual tuning
// https://github.com/ldoolitt/vhd2vl

//execution unit. only a subset of instructions are supported in this
//model, specifically add, sub, lw, sw, beq, and, or

module execute(
input wire [31:0] pc4,
input wire [31:0] register_rs,
input wire [31:0] register_rt,
input wire [5:0] function_opcode,
input wire [31:0] sign_extend,
input wire [4:0] wreg_rd,
input wire [4:0] wreg_rt,
input wire [1:0] aluop,
input wire branch,
input wire alusrc,
input wire regdst,

output reg [31:0] alu_result,
output wire [31:0] branch_addr,
output wire [4:0] wreg_address,
output wire do_branch
);

//internals
wire zero;
wire [31:0] ainput;
wire [31:0] binput;
reg [2:0] alu_ctl;

  // compute the two alu inputs
  assign ainput = register_rs;
  assign binput = (alusrc == 1'b1) ?  sign_extend : register_rt;

  // compute alu_ctl from function_opcode
  // and alu_op 
  always @(*) begin
    // r type instructions
    if ((aluop == 2'b10) & (function_opcode == 6'b100000))
      alu_ctl = 3'b010; // add
    else if ((aluop == 2'b10) & (function_opcode == 6'b100010))
      alu_ctl = 3'b110; // subtract
    else if ((aluop == 2'b10) & (function_opcode == 6'b100100))
      alu_ctl = 3'b000; // and
    else if ((aluop == 2'b10) & (function_opcode == 6'b100101))
      alu_ctl = 3'b001; // or
    else if ((aluop == 2'b10) & (function_opcode == 6'b101010))
      alu_ctl = 3'b111; // slt


    // for lw, sw, and beq
    else if (aluop == 2'b00)
      alu_ctl = 3'b010; // add
    else if (aluop == 2'b01)
      alu_ctl = 3'b110; // subtract

  end

  // use alu_ctl to set alu_result
  always @(*) begin
    if (alu_ctl == 3'b010)
      alu_result = ainput + binput;
    else if (alu_ctl == 3'b110)
      alu_result = ainput - binput;
    else if (alu_ctl == 3'b000)
      alu_result = ainput & binput;
    else if (alu_ctl == 3'b001)
      alu_result = ainput | binput;
    else if (alu_ctl == 3'b111)
      alu_result = (ainput < binput) ? 32'b1 : 32'b0;

  end


  assign zero = (alu_result == 32'h00000000) ? 1'b1 : 1'b0;
  assign do_branch = (branch & zero);
  assign wreg_address = regdst == 1'b1 ? wreg_rd : wreg_rt;
  assign branch_addr = pc4 + {sign_extend[29:0],2'b00};


endmodule
