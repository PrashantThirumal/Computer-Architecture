module mips(
    input wire clock,
    input wire reset
);

// explicit instantiation of multi-bit wires 
// connecting together different modules.
// single bit wires such as control.alusrc
// are implicitly automatically instantiated

// fetch
wire [31:0] instruction;
wire [31:0] pc4;
// decode
wire [1:0] aluop;
wire [31:0] register_rs;
wire [31:0] register_rt;
wire [31:0] sign_extend;
wire [4:0] wreg_rd;
wire [4:0] wreg_rt;
// execute
wire [31:0] alu_result;
wire [31:0] branch_addr;
wire [4:0] wreg_address;
// memory
wire [31:0] read_data;

fetch fetch(
// inputs
.clock(clock),
.reset(reset),
.branch_addr(branch_addr),
.do_branch(do_branch),

// outputs
.instruction(instruction),
.pc4(pc4)
);

control control(
// inputs
.opcode(instruction[31:26]),

// outputs
.regdst(regdst),
.memread(memread),
.memtoreg(memtoreg),
.memwrite(memwrite),
.alusrc(alusrc),
.regwrite(regwrite),
.branch(branch),
.aluop(aluop)
);

decode decode(
// inputs
.clock(clock),
.reset(reset),
.instruction(instruction),
.memory_data(read_data),
.alu_result(alu_result),
.regwrite(regwrite),
.memtoreg(memtoreg),
.wreg_address(wreg_address),

// outputs
.register_rs(register_rs),
.register_rt(register_rt),
.sign_extend(sign_extend),
.wreg_rd(wreg_rd),
.wreg_rt(wreg_rt)
);

execute execute(
// inputs
.pc4(pc4),
.register_rs(register_rs),
.register_rt(register_rt),
.function_opcode(instruction[5:0]),
.sign_extend(sign_extend),
.wreg_rd(wreg_rd),
.wreg_rt(wreg_rt),
.aluop(aluop),
.branch(branch),
.alusrc(alusrc),
.regdst(regdst),

// outputs
.alu_result(alu_result),
.branch_addr(branch_addr),
.wreg_address(wreg_address),
.do_branch(do_branch)
);

memory memory(
// inputs
.clock(clock),
.address(alu_result),
.write_data(register_rt),
.memwrite(memwrite),

// outputs
.read_data(read_data)
);
endmodule