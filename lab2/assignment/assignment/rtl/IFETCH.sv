//***********************************************************
// ECE 3058 Architecture Concurrency and Energy in Computation
//
// MIPS Processor System Verilog Behavioral Model
//
// School of Electrical & Computer Engineering
// Georgia Institute of Technology
// Atlanta, GA 30332
//
//  Engineer:   Brothers, Tim
//  Module:     IFECTCH
//  Functionality:
//      This module provides the PC and instruction memory
//  Inputs:
//      ip_branch: flag from the controller to indicate a branch operation
//      ip_stall : Flag from the Hazard Detection Unit
//      ip_zero: flag from the execute stage to indicate a zero result
//      ip_add_result: 8 bit result from the execute stage adder
//
//  Outputs:
//      op_instruction: the instruction code
//      op_PC:  the current PC location
//      op_PC_plus_4: the next PC location (PC + 4)
//
//  Version History:
//      2020.04.09      Brothers, T. Code converted from VHDL to SV
//      2020.04.27      Brothers, T. Converted to pipeline from single stage
//***********************************************************

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Module Declaration
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
module IFECTCH( 
    //Inputs
    //  --from control--
    input logic ip_branch, 
    
    //  --from Hazard Detection--
    input logic ip_stall,
    
    //  --from execute--
    input logic  [7:0]  ip_add_result,
    input logic ip_zero,
    
    //Outputs
    output logic [31:0] op_instruction,
    output logic [9:0]  op_PC,
    output logic [9:0]  op_PC_plus_4,

    
    //clock and reset signals
    input logic clock,
    input logic reset
);

//**********************************************************
//Local Params Parameters
//**********************************************************
localparam PARAM_RAM_length = 64;
localparam PARAM_RAM_addr_bits = $clog2(PARAM_RAM_length);

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Instruction Memory
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //local variables for the instruction RAM
    logic [31:0] instr_RAM [0:PARAM_RAM_length-1]; //generate a RAM that is 64 entries long and each entry is 4 bytes
    logic [PARAM_RAM_addr_bits-1 :0] instr_mem_addr;

    //Load the program into the memory
    initial begin 
        for (int i = 0; i < PARAM_RAM_length; i++) begin
            instr_RAM[i] = 0; //initialize the RAM with all zeros
        end
        
        //*
        // Test Case 6: TA provided testcase
        // Status: Verified
        instr_RAM[0] = 32'h00000000; // nop fill pipeline
        instr_RAM[1] = 32'h00000000; // nop fill pipeline
        instr_RAM[2] = 32'h00000000; // nop fill pipeline
        instr_RAM[3] = 32'h8C020000; // lw $2,0 ;memory(00)=55555555
        instr_RAM[4] = 32'h8C030004; // lw $3,4 ;memory(04)=AAAAAAAA
        instr_RAM[5] = 32'h00430820; //add $1, $2, $3
        instr_RAM[6] = 32'h00210820; //add $1, $1, $1
        instr_RAM[7] = 32'h10000001; //beq $0, $0, 1
        instr_RAM[8] = 32'h00210820; //add $1, $1, $1
        instr_RAM[9] = 32'h8C040000; //lw $4, 0($0) ;memory(00)=55555555
        instr_RAM[10] = 32'h00852820; //add $5, $4, $5
        //*/
    end 
    
    //register the output from the inst_RAM
    //  based on the address pointer.
    logic [31:0] sig_instruction;
    always @ (posedge clock)
        sig_instruction <= instr_RAM[instr_mem_addr];
    

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Program Counter (PC)
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //generate local variables
    logic [9:0] PC, Next_PC;
    
    //combinational logic to determine next PC value
    always @ (*) 
        if(ip_zero && ip_branch)
            Next_PC <= ip_add_result;
        else if (ip_stall)  //if the stall signal is high we want to stop the PC until the stall condition has passed.
            Next_PC <= PC;
        else
            Next_PC <= PC + 4;
        
    
    //Register the next PC value
    always @ (posedge clock) 
        if(reset)
            PC <= 0;
        else
            PC <= Next_PC;
        
               
    //assign the address for the instruction memory
    //  The instruction memory is 32 bits per memory location. 
    //  So it is 4 Bytes per memory location. 
    //  Due to this we drop the two least significant bits of the PC
    assign instr_mem_addr = Next_PC >> 2;
    
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Pipeline Register
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //Register Signals
    logic [31:0] reg_instruction;
    logic [9:0] reg_PC;
    
    //Register block
    always @ (posedge clock) begin
        if (reset) begin
            reg_instruction <= 0;
            reg_PC          <= 0;
            end
        else if (ip_branch && ip_zero) begin // Reset on branch being taken
            reg_instruction <= 0;
            reg_PC          <= 0;
        end
        else if (ip_stall) begin //if stall then we hold the current values
            reg_instruction <= reg_instruction;
            reg_PC          <= reg_PC;
            end
        else begin
            reg_instruction <= sig_instruction;
            reg_PC          <= PC;
            end
    end
    
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Assign the Outputs
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    assign op_instruction = reg_instruction;
    assign op_PC          = reg_PC;
    assign op_PC_plus_4   = reg_PC + 4;

endmodule

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Alternate test cases to check functionality
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//Put the program here
        // These test cases have issues DO NOT USE
        /* instr_RAM[0] = 32'h00000000;   // nop fill pipeline
        instr_RAM[1] = 32'h00000000;   // nop fill pipeline
        instr_RAM[2] = 32'h00000000;   // nop fill pipeline
        instr_RAM[3] = 32'h8C020000;   // lw $2,0 ;memory(00)=55555555
        instr_RAM[4] = 32'h8C030004;   // lw $3,4 ;memory(04)=AAAAAAAA
        instr_RAM[5] = 32'h00430820;   // add $1,$2,$3
        instr_RAM[6] = 32'hAC010008;   // sw $1,4 ;memory(08)=FFFFFFFF
        instr_RAM[7] = 32'h1022FFFF;   // beq $1,$2,-4  
        instr_RAM[8] = 32'h1021FFFA;   // beq $1,$1,-24 (Assume delay slot present, so it  
                                       // New PC = PC+4-24 = PC-20 */
        /*
        instr_RAM[0] = 32'h8C020000;    // lw $2,0 ;memory(00)=55555555
        instr_RAM[1] = 32'h8C030004;    // lw $3,4 ;memory(04)=AAAAAAAA
        instr_RAM[2] = 32'h00430820;    //add $1, $2, $3
        instr_RAM[3] = 32'h00210820;    //add $1, $1, $1
        instr_RAM[4] = 32'h10000001;    //beq $0, $0, 1
        instr_RAM[5] = 32'h00210820;    //add $1, $1, $1
        instr_RAM[6] = 32'h8C040000;    //lw $4, 0($0) ;memory(00)=55555555
        instr_RAM[7] = 32'h00852820;    //add $5, $4, $5
        */

        /*
        // Test Case 1: No Stall
        // Status: Verified Successfully
        instr_RAM[0] = 32'h00000000; // nop fill pipeline
        instr_RAM[1] = 32'h00000000; // nop fill pipeline
        instr_RAM[2] = 32'h00000000; // nop fill pipeline
        instr_RAM[3] = 32'h8C020000; // lw $2, 0 ← Memory(00) = 55555555
        instr_RAM[4] = 32'h8C020004; // lw $2, 4 ← Memory(04) = AAAAAAAA
        instr_RAM[5] = 32'h00210820; // add $1, $1, $1   
        */

        /*
        // Test Case 2: Stall 1 instruction after
        // Status: Verified Successfully
        instr_RAM[0] = 32'h00000000; // nop fill pipeline
        instr_RAM[1] = 32'h00000000; // nop fill pipeline
        instr_RAM[2] = 32'h00000000; // nop fill pipeline
        instr_RAM[3] = 32'h8C020000; // lw $2, 0 ← Memory(00) = 55555555
        instr_RAM[4] = 32'h00420820; // add $1, $2, $2
        instr_RAM[5] = 32'h00421820; // add $3, $2, $2 
        */

        /*
        // Test Case 3: Stall 2 instructions after
        // Status: Verified Successfully
        instr_RAM[0] = 32'h00000000; // nop fill pipeline
        instr_RAM[1] = 32'h00000000; // nop fill pipeline
        instr_RAM[2] = 32'h00000000; // nop fill pipeline
        instr_RAM[3] = 32'h8C020000; // lw $2, 0 ← Memory(00) = 55555555
        instr_RAM[4] = 32'h00210820; // add $1, $1, $1
        instr_RAM[5] = 32'h00420820; // add $1, $2, $2  
        */

        /*
        // Test Case 4: Forwarding 
        // Status; Verified Successfully
        instr_RAM[0] = 32'h00000000; // nop fill pipeline
        instr_RAM[1] = 32'h00000000; // nop fill pipeline
        instr_RAM[2] = 32'h00000000; // nop fill pipeline
        instr_RAM[3] = 32'h00421020; // add $2, $2, $2
        instr_RAM[4] = 32'h00420820; // add $1, $2, $2
        instr_RAM[5] = 32'h00421820; // add $3, $2, $2
        instr_RAM[6] = 32'h00422020; // add $4, $2, $2
        */

        /*
        // Test Case 5: Branch Taken
        // Status: Verified Successfully           
        instr_RAM[0] = 32'h00000000; // nop fill pipeline
        instr_RAM[1] = 32'h00000000; // nop fill pipeline
        instr_RAM[2] = 32'h00000000; // nop fill pipeline
        instr_RAM[3] = 32'h00421020; // add $2, $2, $2
        instr_RAM[4] = 32'h1082FFFE; // beq $4, $2, 0xFFFE; Branch to 3
        instr_RAM[5] = 32'h00210820; // add $1, $1, $1
        instr_RAM[6] = 32'h00631820; // add $3, $3, $3
        instr_RAM[7] = 32'h00842020; // add $4, $4, $4
        instr_RAM[8] = 32'h00A52820; // add $5, $5, $5  
        */
