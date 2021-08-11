// vhdl: sudhakar yalamanchili
// translated to verilog by yehowshua with vhd2l and manual tuning
// https://github.com/ldoolitt/vhd2vl

// control unit. simply implements the truth table for a small set of
// instructions 

module control(
input wire [5:0] opcode,

output wire regdst,
output wire memread,
output wire memtoreg,
output wire memwrite,
output wire alusrc,
output wire regwrite,
output wire branch,
output wire [1:0] aluop
);

//internals
wire rformat;
wire lw;
wire sw;
wire beq;

//immediate instructions
wire andi;
wire ori;
wire addi;
wire slti;

  // recognize opcode for each instruction type
  assign rformat = opcode == 6'b000000 ? 1'b1 : 1'b0;
  assign lw = opcode == 6'b100011 ? 1'b1 : 1'b0;
  assign sw = opcode == 6'b101011 ? 1'b1 : 1'b0;
  assign beq = opcode == 6'b000100 ? 1'b1 : 1'b0;

  // implement each output signal as the column of the truth
  // table which defines the control
  assign regdst = rformat;
  assign alusrc = lw | sw;
  assign memtoreg = lw;
  assign regwrite = rformat | lw;
  assign memread = lw;
  assign memwrite = sw;
  assign branch = beq;
  assign aluop[1:0] = {rformat,beq};

endmodule