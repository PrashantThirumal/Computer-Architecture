// vhdl: sudhakar yalamanchili
// translated to verilog by yehowshua with vhd2l and manual tuning
// https://github.com/ldoolitt/vhd2vl

// instruction fetch behavioral model. instruction memory is
// provided within this model. if increments the pc,  
// and writes the appropriate output signals. 


module fetch(
input wire clock,
input wire reset,
input wire [31:0] branch_addr,
input wire do_branch,

output wire [31:0] instruction,
output wire [31:0] pc4
);

// internals
reg [31:0] pc;
wire [31:0] next_pc;


  // load the program into the memory
  // a better way to do this is with gnu-as
  // and verilog primitive ``readmemh``.
  // note we use [0:31]. This allows us to 
  // paste instructions from big-endian
  // assemblers lik gnu-as in big-endian
  // mode and most online mips assemblers
  reg [0:31] iram [0:10];
    initial begin 
      iram[0] = 32'hac030000; // sw	$3, 0x0
      iram[1] = 32'h8c040000; // lw	$4, 0x0
      iram[2] = 32'h00832820; // add $5, $4, $3
      iram[3] = 32'h00e52822; // sub $5, $7, $5
      iram[4] = 32'h00a12824; // and $5, $5, $1
      iram[5] = 32'h00a12825; // or $5, $5, $1
      iram[6] = 32'h0089402a; // slt $8, $4, $9 -> if 8 = 1, slt instr works
      iram[7] = 32'h10a1fff9; // beq $5, $1, _start
      iram[8] = 32'h00000000; // nop - branch delay slot
    end 


  // access instruction pointed to by current pc
  assign instruction = iram[pc[4:2]];

  // compute value of next pc
  assign next_pc = do_branch == 1'b1 ? branch_addr : pc+4;

  // update the pc on the next clock			   
  always @(posedge clock) begin
    if(reset == 1'b1)
      pc <= 32'h00000000;
    else
      pc <= next_pc;
  end

  assign pc4 = pc + 4;

endmodule