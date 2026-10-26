///MUX2
module Mux2(sel2,A2,B2,Mux2_out);
input sel2;
input [31:0] A2,B2;
output [31:0] Mux2_out;	

assign Mux2_out = (sel2==1'b0) ? A2 : B2;
endmodule


/// Program Counter Module
module Program_Counter(PC_out,PC_in,clk,reset,PCWrite);

input clk,reset,PCWrite;
input  [31:0] PC_in;
output reg [31:0] PC_out;

always @(posedge clk or posedge reset)
begin
if (reset) begin
PC_out <= 32'b00; 
end
else if (PCWrite) begin
PC_out <= PC_in;
end
end
endmodule


// PC+4 Module 
module PC_plus_4(NextoPC,fromPC);
input [31:0] fromPC;
output reg [31:0] NextoPC;

always @(*)
begin 
NextoPC =  4 + fromPC;
end
endmodule
  
  
// Instruction Memory Module
module Instruction_Mem(instruction_out,read_address);

input [5:0] read_address;
output reg [31:0] instruction_out;

always @(*)
begin

    case(read_address) 

        // I-type
        6'd0 : instruction_out = 32'b00000000000000000000000000000000;

        6'd1 : instruction_out = 32'b000000001111_00000_000_10000_0010011; // addi x16,x0,15
		  
        6'd2 : instruction_out = 32'b000000001010_00000_000_11001_0010011; // addi x25,x0,10
		  
        6'd3 : instruction_out = 32'b000000000001_00000_110_01001_0010011; // ori x9,x0,1


        // R-type
        6'd4 : instruction_out = 32'b0000000_11001_10000_000_01101_0110011; // add x13,x16,x25

        6'd5 : instruction_out = 32'b0100000_11001_10000_000_01011_0110011; // sub x11,x16,x25

        6'd6 : instruction_out = 32'b0000000_11001_10000_111_01000_0110011; // and x8,x16,x25
		  
        6'd7 : instruction_out = 32'b0000000_11001_10000_110_01001_0110011; // or x9,x16,x25


        // Load
        6'd8 : instruction_out = 32'b000000001111_00000_010_01011_0000011; // lw x11,15(x0)

        6'd9 : instruction_out = 32'b000000001011_10000_010_01110_0000011; // lw x14,11(x25)


        // Store
        6'd10 : instruction_out = 32'b0000000_01100_10000_010_01100_0100011; // sw x12,12(x16)

        6'd11 : instruction_out = 32'b0000000_01010_10000_010_01000_0100011; // sw x10,10(x16)


        // Branch
        6'd12 : instruction_out = 32'h00948663; // beq x9,x9,12


        default : instruction_out = 32'b00000000000000000000000000010011; // nop

    endcase

end

endmodule


/////////////////////////////////////////////////////////////////////////////////
/////////               IF/ID Stage: Start                           /////////////
/////////////////////////////////////////////////////////////////////////////////

module IFID_Reg(IFPC_in, IFInstrMEM_in, IDPC_out, IDInstrMEM_out, clk, reset, IFIDWrite);

input clk,reset,IFIDWrite;
input [31:0] IFPC_in;
input [31:0] IFInstrMEM_in;

output reg [31:0] IDPC_out;
output reg [31:0] IDInstrMEM_out;

always @(posedge clk or posedge reset)
begin 
if(reset)
begin
    IDPC_out       <= 32'b00;
    IDInstrMEM_out <= 32'b00;
end 
else if(IFIDWrite)
begin 
    IDPC_out       <= IFPC_in;
    IDInstrMEM_out <= IFInstrMEM_in; 
end
end 

endmodule


/////////////////////////////////////////////////////////////////////////////////
/////////               IF/ID Stage: End                           ///////////////
/////////////////////////////////////////////////////////////////////////////////


///Register File 
module Reg_File(read_data1,read_data2,Regwrite,Rs1,Rs2,Write_data,Rd,clk,reset);

input clk,reset,Regwrite;
input [4:0]  Rs1,Rs2,Rd;
input [31:0] Write_data;

output [31:0] read_data1,read_data2;

reg [31:0] Registers[31:0];
integer k;


assign read_data1 = (Rs1 == 5'b00000) ? 32'b0 : Registers[Rs1];
assign read_data2 = (Rs2 == 5'b00000) ? 32'b0 : Registers[Rs2];


always @(posedge clk or posedge reset)
begin 

if (reset)
begin 
    for(k=0; k<32; k=k+1) 
    begin
        Registers[k] <= 32'b00;
    end
end

else if((Regwrite) && (Rd != 5'b00000)) 
begin
    Registers[Rd] <= Write_data;
end

end

endmodule


//Control Unit
module Control_Unit(Branch, MemRead, MemtoReg, ALUOp,MemWrite, ALUSrc, RegWrite,instruction);

input [6:0] instruction;

output reg Branch, MemRead, MemtoReg,MemWrite, ALUSrc, RegWrite;
output reg [1:0] ALUOp;

always @(*)
begin 

    Branch   = 1'b0;
    MemRead  = 1'b0;
    MemtoReg = 1'b0;
    MemWrite = 1'b0;
    ALUSrc   = 1'b0;
    RegWrite = 1'b0;
    ALUOp    = 2'b00;

    case(instruction)
        7'b0110011 : 
        begin 
            {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00100010; 
        end

        7'b0010011 : 
        begin 
            {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b10100010; 
        end

        7'b0000011 : 
        begin 
            {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b11110000; 
        end

        7'b0100011 : 
        begin 
            {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b10001000; 
        end

        7'b1100011 : 
        begin 
            {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00000101;  
        end

        default : 
        begin 
            {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} = 8'b00000000; 
        end

    endcase

end

endmodule


//Immidiate Generator
module ImmGen(ImmExt,instruction);

input [31:0] instruction;
output reg [31:0] ImmExt;

always @(*)
begin 

case(instruction[6:0])

    7'b0010011: 
    ImmExt = {{20{instruction[31]}}, instruction[31:20]}; // I-type  

    7'b0000011: 
    ImmExt = {{20{instruction[31]}}, instruction[31:20]}; // Load-type

    7'b0100011: 
    ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // Store-type

    7'b1100011: 
    ImmExt = {{19{instruction[31]}}, instruction[31], instruction[7], 
              instruction[30:25], instruction[11:8], 1'b0}; // B-type 

    7'b0110111: 
    ImmExt = {instruction[31:12], 12'b0}; // U-type

    7'b0010111: 
    ImmExt = {instruction[31:12], 12'b0}; // U-type

    7'b1101111: 
    ImmExt = {{11{instruction[31]}}, instruction[31], instruction[19:12], 
              instruction[20], instruction[30:21], 1'b0}; // J-type

    default: 
    ImmExt = 32'b0;

endcase 

end 

endmodule 


///////////////////////////////////////////////////////////////////////
///////             ID/EXE Stage: Start               ////////////////
///////////////////////////////////////////////////////////////////////		

module IDEXE_Reg(IDBranch_in, IDMemRead_in, IDMemtoReg_in, IDALUOp_in,
                IDMemWrite_in, IDALUSrc_in, IDRegWrite_in, IDPCout_in,IDread_data1_in,
				IDread_data2_in, IDImmExt_in, IDInstrMEM_out_in3, IDInstrMEM_out_in6,
				IDInstrMEM_out_in7, IDInstrMEM_out_in1, IDInstrMEM_out_in2, ID_EX_Flush,
		        
		        EXEBranch_out, EXEMemRead_out, EXEMemtoReg_out, EXEALUOp_out,
                EXEMemWrite_out, EXEALUSrc_out, EXERegWrite_out, EXEPCout_out,EXEread_data1_out,
				EXEread_data2_out, EXEImmExt_out, EXEInstrMEM_out3, EXEInstrMEM_out6,
				EXEInstrMEM_out7, EXEInstrMEM_out1, EXEInstrMEM_out2, clk, reset);
					 
input clk, reset, IDBranch_in, IDMemRead_in, IDMemtoReg_in,IDMemWrite_in, IDALUSrc_in, IDRegWrite_in;

input ID_EX_Flush;

input [1:0] IDALUOp_in;

input [31:0] IDPCout_in;
input [31:0] IDread_data1_in, IDread_data2_in;
input [31:0] IDImmExt_in;

input [2:0] IDInstrMEM_out_in3;
input [4:0] IDInstrMEM_out_in6;
input [6:0] IDInstrMEM_out_in7;

input [4:0] IDInstrMEM_out_in1;
input [4:0] IDInstrMEM_out_in2;


output reg EXEBranch_out, EXEMemRead_out, EXEMemtoReg_out,EXEMemWrite_out, EXEALUSrc_out, EXERegWrite_out;

output reg [1:0] EXEALUOp_out;

output reg [31:0] EXEPCout_out;
output reg [31:0] EXEread_data1_out, EXEread_data2_out;
output reg [31:0] EXEImmExt_out;

output reg [2:0] EXEInstrMEM_out3;
output reg [4:0] EXEInstrMEM_out6;
output reg [6:0] EXEInstrMEM_out7;

output reg [4:0] EXEInstrMEM_out1;
output reg [4:0] EXEInstrMEM_out2;


always @(posedge clk or posedge reset)
begin 

if(reset)
begin

    EXEBranch_out        <= 1'b0;
    EXEMemRead_out       <= 1'b0;
    EXEMemtoReg_out      <= 1'b0;
    EXEMemWrite_out      <= 1'b0;
    EXEALUSrc_out        <= 1'b0;
    EXERegWrite_out      <= 1'b0;
    EXEALUOp_out         <= 2'b00;

    EXEPCout_out         <= 32'b00;
    EXEread_data1_out    <= 32'b00;
    EXEread_data2_out    <= 32'b00;
    EXEImmExt_out        <= 32'b00;

    EXEInstrMEM_out3     <= 3'b000;
    EXEInstrMEM_out6     <= 5'b00000;
    EXEInstrMEM_out7     <= 7'b0000000;

    EXEInstrMEM_out1     <= 5'b00000;
    EXEInstrMEM_out2     <= 5'b00000;

end

else if(ID_EX_Flush)
begin

    EXEBranch_out        <= 1'b0;
    EXEMemRead_out       <= 1'b0;
    EXEMemtoReg_out      <= 1'b0;
    EXEMemWrite_out      <= 1'b0;
    EXEALUSrc_out        <= 1'b0;
    EXERegWrite_out      <= 1'b0;
    EXEALUOp_out         <= 2'b00;

    EXEPCout_out         <= 32'b00;
    EXEread_data1_out    <= 32'b00;
    EXEread_data2_out    <= 32'b00;
    EXEImmExt_out        <= 32'b00;

    EXEInstrMEM_out3     <= 3'b000;
    EXEInstrMEM_out6     <= 5'b00000;
    EXEInstrMEM_out7     <= 7'b0000000;

    EXEInstrMEM_out1     <= 5'b00000;
    EXEInstrMEM_out2     <= 5'b00000;

end

else 
begin

    EXEBranch_out        <= IDBranch_in;
    EXEMemRead_out       <= IDMemRead_in;
    EXEMemtoReg_out      <= IDMemtoReg_in;
    EXEMemWrite_out      <= IDMemWrite_in;
    EXEALUSrc_out        <= IDALUSrc_in;
    EXERegWrite_out      <= IDRegWrite_in;
    EXEALUOp_out         <= IDALUOp_in;

    EXEPCout_out         <= IDPCout_in;
    EXEread_data1_out    <= IDread_data1_in;
    EXEread_data2_out    <= IDread_data2_in;
    EXEImmExt_out        <= IDImmExt_in;

    EXEInstrMEM_out3     <= IDInstrMEM_out_in3;
    EXEInstrMEM_out6     <= IDInstrMEM_out_in6;
    EXEInstrMEM_out7     <= IDInstrMEM_out_in7;

    EXEInstrMEM_out1     <= IDInstrMEM_out_in1;
    EXEInstrMEM_out2     <= IDInstrMEM_out_in2;

end	

end 

endmodule 	  	

///////////////////////////////////////////////////////////////////////
///////             ID/EXE Stage: End              ////////////////
///////////////////////////////////////////////////////////////////////		




//// Multiplexers 		

///MUX1
module Mux1(sel1,A1,B1,Mux1_out);

input sel1;
input [31:0] A1,B1;

output [31:0] Mux1_out;	

assign Mux1_out = (sel1==1'b0) ? A1 : B1;

endmodule


//Adder
module Adder(in_1,in_2,Sum_out);

input [31:0] in_1,in_2;
output [31:0] Sum_out;

assign Sum_out = in_1 + in_2;

endmodule


// ALU Control Module
module ALU_Control(Control_out, ALUOp, fun7,fun3);

input [6:0] fun7;
input [2:0] fun3;
input [1:0] ALUOp; 

output reg [3:0] Control_out;

always @(*)
begin     

case(ALUOp)

    2'b00:
    begin
        Control_out = 4'b0000; // ADD for LW/SW
    end

    2'b01:
    begin
        Control_out = 4'b0001; // SUB for Branch
    end

    2'b10:
    begin

        case({fun7,fun3})

            10'b0000000_000 : Control_out = 4'b0000;    // ADD / ADDI 
            10'b0100000_000 : Control_out = 4'b0001;    // SUB 
            10'b0000000_111 : Control_out = 4'b0010;    // AND
            10'b0000000_110 : Control_out = 4'b0011;    // OR
            10'b0000000_100 : Control_out = 4'b0100;    // XOR
            10'b0000000_001 : Control_out = 4'b0101;    // SLL
            10'b0000000_101 : Control_out = 4'b0110;    // SRL
            10'b0100000_101 : Control_out = 4'b0111;    // SRA
            10'b0000000_010 : Control_out = 4'b1000;    // SLT

            default : Control_out = 4'b0000;

        endcase

    end

    default:
    begin
        Control_out = 4'b0000;
    end

endcase

end

endmodule


// ALU Module
module ALU_Unit(ALU_result,Zero,A,B,Control_in);

input [31:0] A,B;
input [3:0] Control_in;

output reg Zero;
output reg [31:0] ALU_result;

always @(*)
begin 

case(Control_in) 

    4'b0000: ALU_result = A + B;           		// ADD
    4'b0001: ALU_result = A - B;           		// SUB
    4'b0010: ALU_result = A & B;           		// AND
    4'b0011: ALU_result = A | B;           		// OR
    4'b0100: ALU_result = A ^ B;           		// XOR
    4'b0101: ALU_result = A << B[4:0];     		// SLL
    4'b0110: ALU_result = A >> B[4:0];     		// SRL
    4'b0111: ALU_result = $signed(A) >>> B[4:0]; // SRA

    4'b1000: 
    ALU_result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0;

    default: 
    ALU_result = 32'b0;          	

endcase

Zero = (ALU_result == 32'b0) ? 1'b1 : 1'b0;

end 

endmodule


///////////////////////////////////////////////////////////////////////
///////             EXE/MEM Stage: Start               ////////////////
///////////////////////////////////////////////////////////////////////	

module EXEMEM_Reg(EXEBranch_in, EXEMemRead_in, EXEMemtoReg_in, EXEMemWrite_in, EXERegWrite_in, 
               EXESum_out_in, EXEALU_result_in, EXEZero_in, EXEread_data2_in, EXEInstrMEM_in6,	MEMBranch_out,
				MEMMemRead_out, MEMMemtoReg_out, MEMMemWrite_out, MEMRegWrite_out, 
               MEMSum_out_out, MEMALU_result_out, MEMZero_out, MEMread_data2_out, MEMInstrMEM_out6, clk, reset);

input clk, reset;

input EXEBranch_in, EXEMemRead_in, EXEMemtoReg_in, EXEMemWrite_in, EXERegWrite_in, EXEZero_in;

input [31:0] EXESum_out_in, EXEALU_result_in, EXEread_data2_in;

input [4:0] EXEInstrMEM_in6;


output reg MEMBranch_out, MEMMemRead_out, MEMMemtoReg_out, MEMMemWrite_out, MEMRegWrite_out, MEMZero_out;

output reg [31:0] MEMSum_out_out, MEMALU_result_out, MEMread_data2_out;

output reg [4:0] MEMInstrMEM_out6;


always @(posedge clk or posedge reset)
begin 

if(reset) 
begin

    MEMBranch_out     <= 1'b0;
    MEMMemRead_out    <= 1'b0;
    MEMMemtoReg_out   <= 1'b0;
    MEMMemWrite_out   <= 1'b0;
    MEMRegWrite_out   <= 1'b0;
    MEMZero_out       <= 1'b0;

    MEMSum_out_out    <= 32'b00;
    MEMALU_result_out <= 32'b00;
    MEMread_data2_out <= 32'b00;

    MEMInstrMEM_out6  <= 5'b00;

end

else 
begin

    MEMBranch_out     <= EXEBranch_in;
    MEMMemRead_out    <= EXEMemRead_in;
    MEMMemtoReg_out   <= EXEMemtoReg_in;
    MEMMemWrite_out   <= EXEMemWrite_in;
    MEMRegWrite_out   <= EXERegWrite_in;
    MEMZero_out       <= EXEZero_in;

    MEMSum_out_out    <= EXESum_out_in;
    MEMALU_result_out <= EXEALU_result_in;
    MEMread_data2_out <= EXEread_data2_in;

    MEMInstrMEM_out6  <= EXEInstrMEM_in6;

end

end 

endmodule 				

///////////////////////////////////////////////////////////////////////
///////             EXE/MEM Stage: End               ////////////////
///////////////////////////////////////////////////////////////////////	



// Data Memory 
module Data_Memory(MemData_out, MemRead, MemWrite, read_address, Write_data,clk);

input clk,MemRead, MemWrite;
input [5:0] read_address;
input [31:0] Write_data;

output [31:0] MemData_out;

reg [31:0] D_Memory[63:0];


always @(posedge clk)
begin 

if(MemWrite)
begin
    D_Memory[read_address] <= Write_data;
end

end


assign MemData_out = (MemRead) ? D_Memory[read_address] :  32'b00;

endmodule			


//AND Logic 
module AND_logic(branch, Zero, and_out);

input branch, Zero;
output and_out;

assign and_out = branch & Zero;

endmodule


///////////////////////////////////////////////////////////////////////
///////             MEM/WB Stage: Start              ////////////////
///////////////////////////////////////////////////////////////////////	

module MEMWB_Reg( MEMMemtoReg_in, MEMRegWrite_in, MemData_out_in, MEMALU_result_in, 
              MEMInstrMEM_in6, WBMemtoReg_out, WBRegWrite_out, WBData_out_out,
			  WBALU_result_out, WBInstrMEM_out6, clk, reset);

input clk, reset;

input MEMMemtoReg_in, MEMRegWrite_in;

input [31:0] MemData_out_in, MEMALU_result_in;

input [4:0] MEMInstrMEM_in6;


output reg WBMemtoReg_out, WBRegWrite_out;

output reg [31:0] WBData_out_out, WBALU_result_out;

output reg [4:0] WBInstrMEM_out6;


always @(posedge clk or posedge reset)
begin

if(reset)
begin
     
    WBMemtoReg_out   <= 1'b0;
    WBRegWrite_out   <= 1'b0;

    WBData_out_out   <= 32'b00;
    WBALU_result_out <= 32'b00;
		  
    WBInstrMEM_out6  <= 5'b00;

end

else 
begin
		  
    WBMemtoReg_out   <= MEMMemtoReg_in;
    WBRegWrite_out   <= MEMRegWrite_in;

    WBData_out_out   <= MemData_out_in;
    WBALU_result_out <= MEMALU_result_in;
		  
    WBInstrMEM_out6  <= MEMInstrMEM_in6;

end

end 

endmodule		  


///////////////////////////////////////////////////////////////////////
///////             MEM/WB Stage: End               ////////////////
///////////////////////////////////////////////////////////////////////	




///MUX3
module Mux3(sel3,A3,B3,Mux3_out);

input sel3;
input [31:0] A3,B3;

output [31:0] Mux3_out;	

assign Mux3_out = (sel3==1'b0) ? A3 : B3;

endmodule		  



///////////////////////////////////////////////////////////////////////
///////             Forwarding Unit                 /////////////////
///////////////////////////////////////////////////////////////////////

module Forwarding_Unit(
ForwardA,
ForwardB,
EXE_rs1,
EXE_rs2,
MEM_rd,
WB_rd,
MEM_RegWrite,
WB_RegWrite
);

input [4:0] EXE_rs1;
input [4:0] EXE_rs2;

input [4:0] MEM_rd;
input [4:0] WB_rd;

input MEM_RegWrite;
input WB_RegWrite;

output reg [1:0] ForwardA;
output reg [1:0] ForwardB;


always @(*)
begin

    ForwardA = 2'b00;
    ForwardB = 2'b00;


    // MEM to EXE forwarding
    if((MEM_RegWrite) &&
       (MEM_rd != 5'b00000) &&
       (MEM_rd == EXE_rs1))
    begin
        ForwardA = 2'b10;
    end

    // WB to EXE forwarding
    else if((WB_RegWrite) &&
            (WB_rd != 5'b00000) &&
            (WB_rd == EXE_rs1))
    begin
        ForwardA = 2'b01;
    end


    // MEM to EXE forwarding
    if((MEM_RegWrite) &&
       (MEM_rd != 5'b00000) &&
       (MEM_rd == EXE_rs2))
    begin
        ForwardB = 2'b10;
    end

    // WB to EXE forwarding
    else if((WB_RegWrite) &&
            (WB_rd != 5'b00000) &&
            (WB_rd == EXE_rs2))
    begin
        ForwardB = 2'b01;
    end

end

endmodule



///////////////////////////////////////////////////////////////////////
///////             Hazard Detection Unit              ////////////////
///////////////////////////////////////////////////////////////////////

module Hazard_Detection_Unit(
PCWrite,
IFIDWrite,
ID_EX_Flush,
EXE_MemRead,
EXE_rd,
ID_rs1,
ID_rs2,
ID_uses_rs2
);

input EXE_MemRead;

input [4:0] EXE_rd;
input [4:0] ID_rs1;
input [4:0] ID_rs2;

input ID_uses_rs2;

output reg PCWrite;
output reg IFIDWrite;
output reg ID_EX_Flush;


always @(*)
begin

    PCWrite     = 1'b1;
    IFIDWrite   = 1'b1;
    ID_EX_Flush = 1'b0;


    // Load-Use Hazard Detection
    if(EXE_MemRead &&
       (EXE_rd != 5'b00000) &&
       ((EXE_rd == ID_rs1) ||
        (ID_uses_rs2 && (EXE_rd == ID_rs2))))
    begin

        PCWrite     = 1'b0;
        IFIDWrite   = 1'b0;
        ID_EX_Flush = 1'b1;

    end

end

endmodule



// All Module Instantiate Here....

module top(clk,reset,PC_debug,instruction_debug,ALU_result_debug, WB_result_debug);

input clk, reset;

output [31:0] PC_debug, instruction_debug, ALU_result_debug, WB_result_debug;


//module top(clk,reset,LED);
//input clk, reset;
//
//output [7:0] LED;


wire [31:0] PC_top, instruction_top, Rd1_top, Rd2_top, ImmExt_top, Mux1_out_top, 
          Sum_out_top, NextoPC_top, PC_in_top, ALU_result_top, MemData_out_top, Mux3_out_top;

wire RegWrite_top, ALUSrc_top, branch_top, Zero_top, sel2_top, MemtoReg_top, MemWrite_top, MemRead_top;

wire [1:0] ALUOp_top;

wire [3:0] Control_out_top;


//IFID Register wires 
wire [31:0] IDPC_out_wire, IDInstrMEM_out_wire;



// IDEXE Register Wires
wire EXEBranch_out_wire, EXEMemRead_out_wire, EXEMemtoReg_out_wire, EXEMemWrite_out_wire, 
     EXEALUSrc_out_wire, EXERegWrite_out_wire; 

wire [1:0] EXEALUOp_out_wire;

wire [31:0] EXEread_data1_out_wire, EXEread_data2_out_wire, EXEPCout_out_wire, EXEImmExt_out_wire;

wire [2:0] EXEInstrMEM_out3_wire;

wire [4:0] EXEInstrMEM_out6_wire;

wire [6:0] EXEInstrMEM_out7_wire;


// EXE rs1 and rs2 wires
wire [4:0] EXEInstrMEM_out1_wire;
wire [4:0] EXEInstrMEM_out2_wire;


// EXEMEM Register Wires
wire MEMBranch_out_wire, MEMMemRead_out_wire, MEMMemtoReg_out_wire,
     MEMMemWrite_out_wire, MEMRegWrite_out_wire, MEMZero_out_wire;

wire [31:0] MEMSum_out_out_wire, MEMALU_result_out_wire, MEMread_data2_out_wire;		

wire [4:0] MEMInstrMEM_out6_wire;


// MEMWB Register Wires--------------
wire WBRegWrite_out_wire, WBMemtoReg_out_wire;

wire [31:0] WBData_out_out_wire, WBALU_result_out_wire;

wire [4:0] WBInstrMEM_out6_wire;


// Forwarding wires
wire [1:0] ForwardA_top;
wire [1:0] ForwardB_top;

wire [31:0] ForwardA_data_top;
wire [31:0] ForwardB_data_top;


// Hazard Detection wires
wire PCWrite_top;
wire IFIDWrite_top;
wire ID_EX_Flush_top;

wire ID_uses_rs2_top;



// Adder MUX2
Mux2 adder_Mux2(
.sel2(sel2_top), 
.A2(NextoPC_top), 
.B2(MEMSum_out_out_wire), 
.Mux2_out(PC_in_top)
);


// Program Counter 
Program_Counter PC(
.PC_out(PC_top), 
.PC_in(PC_in_top), 
.clk(clk), 
.reset(reset),
.PCWrite(PCWrite_top)
);


// PC Adder
PC_plus_4 PCAdder(
.NextoPC(NextoPC_top), 
.fromPC(PC_top)
);


// Instruction Memory 
Instruction_Mem Inst_Memory(
.instruction_out(instruction_top), 
.read_address(PC_top[7:2])
);



/////IF-ID PIPELINE REGISTER----------------------------------------------------------------
IFID_Reg IFID_Reg(
.IFPC_in(PC_top), 
.IFInstrMEM_in(instruction_top), 

.IDPC_out(IDPC_out_wire), 
.IDInstrMEM_out(IDInstrMEM_out_wire), 

.clk(clk), 
.reset(reset),
.IFIDWrite(IFIDWrite_top)
);
//-------------------------------------------------------------------------------------------



//Control Unit
Control_Unit CU(
.Branch(branch_top), 
.MemRead(MemRead_top), 
.MemtoReg(MemtoReg_top), 
.ALUOp(ALUOp_top), 
.MemWrite(MemWrite_top), 
.ALUSrc(ALUSrc_top), 
.RegWrite(RegWrite_top), 

.instruction(IDInstrMEM_out_wire[6:0])
);	


// Register File
Reg_File Reg_File(
.read_data1(Rd1_top), 
.read_data2(Rd2_top), 

.Regwrite(WBRegWrite_out_wire), 

.Rs1(IDInstrMEM_out_wire[19:15]),
.Rs2(IDInstrMEM_out_wire[24:20]), 

.Write_data(Mux3_out_top), 
.Rd(WBInstrMEM_out6_wire), 

.clk(clk), 
.reset(reset)
);


//Immidiate Generator
ImmGen ImmGen(
.ImmExt(ImmExt_top), 
.instruction(IDInstrMEM_out_wire)
);



// Hazard Detection
assign ID_uses_rs2_top =
    (IDInstrMEM_out_wire[6:0] == 7'b0110011) || // R-type
    (IDInstrMEM_out_wire[6:0] == 7'b0100011) || // Store
    (IDInstrMEM_out_wire[6:0] == 7'b1100011);   // Branch


Hazard_Detection_Unit Hazard_Detection_Unit(

.PCWrite(PCWrite_top),

.IFIDWrite(IFIDWrite_top),

.ID_EX_Flush(ID_EX_Flush_top),

.EXE_MemRead(EXEMemRead_out_wire),

.EXE_rd(EXEInstrMEM_out6_wire),

.ID_rs1(IDInstrMEM_out_wire[19:15]),

.ID_rs2(IDInstrMEM_out_wire[24:20]),

.ID_uses_rs2(ID_uses_rs2_top)

);
		   

/// ID-EXE PIPELINE REGISTER----------------------------------------------------------
IDEXE_Reg IDEXE_Reg(

.IDBranch_in(branch_top),
.IDMemRead_in(MemRead_top), 
.IDMemtoReg_in(MemtoReg_top), 
.IDALUOp_in(ALUOp_top),

.IDMemWrite_in(MemWrite_top),
.IDALUSrc_in(ALUSrc_top),
.IDRegWrite_in(RegWrite_top),

.IDPCout_in(IDPC_out_wire),

.IDread_data1_in(Rd1_top),
.IDread_data2_in(Rd2_top),

.IDImmExt_in(ImmExt_top), 

.IDInstrMEM_out_in3(IDInstrMEM_out_wire[14:12]),
.IDInstrMEM_out_in6(IDInstrMEM_out_wire[11:7]),
.IDInstrMEM_out_in7(IDInstrMEM_out_wire[31:25]),

.IDInstrMEM_out_in1(IDInstrMEM_out_wire[19:15]),
.IDInstrMEM_out_in2(IDInstrMEM_out_wire[24:20]),

.ID_EX_Flush(ID_EX_Flush_top),


.EXEBranch_out(EXEBranch_out_wire),
.EXEMemRead_out(EXEMemRead_out_wire),
.EXEMemtoReg_out(EXEMemtoReg_out_wire),

.EXEALUOp_out(EXEALUOp_out_wire),

.EXEMemWrite_out(EXEMemWrite_out_wire),
.EXEALUSrc_out(EXEALUSrc_out_wire), 
.EXERegWrite_out(EXERegWrite_out_wire),

.EXEPCout_out(EXEPCout_out_wire),

.EXEread_data1_out(EXEread_data1_out_wire),
.EXEread_data2_out(EXEread_data2_out_wire), 

.EXEImmExt_out(EXEImmExt_out_wire), 

.EXEInstrMEM_out3(EXEInstrMEM_out3_wire),
.EXEInstrMEM_out6(EXEInstrMEM_out6_wire),
.EXEInstrMEM_out7(EXEInstrMEM_out7_wire), 

.EXEInstrMEM_out1(EXEInstrMEM_out1_wire),
.EXEInstrMEM_out2(EXEInstrMEM_out2_wire),

.clk(clk), 
.reset(reset)
);
//-------------------------------------------------------------------------------					 



// Forwarding Unit
Forwarding_Unit Forwarding_Unit(

.ForwardA(ForwardA_top),

.ForwardB(ForwardB_top),

.EXE_rs1(EXEInstrMEM_out1_wire),

.EXE_rs2(EXEInstrMEM_out2_wire),

.MEM_rd(MEMInstrMEM_out6_wire),

.WB_rd(WBInstrMEM_out6_wire),

.MEM_RegWrite(MEMRegWrite_out_wire),

.WB_RegWrite(WBRegWrite_out_wire)

);



// Forwarding MUX for ALU inputs
assign ForwardA_data_top =
    (ForwardA_top == 2'b10) ?
        (MEMMemtoReg_out_wire ? MemData_out_top : MEMALU_result_out_wire) :

    (ForwardA_top == 2'b01) ?
        Mux3_out_top :

        EXEread_data1_out_wire;


assign ForwardB_data_top =
    (ForwardB_top == 2'b10) ?
        (MEMMemtoReg_out_wire ? MemData_out_top : MEMALU_result_out_wire) :

    (ForwardB_top == 2'b01) ?
        Mux3_out_top :

        EXEread_data2_out_wire;



// ALU Mux1
Mux1 Mux1(
.sel1(EXEALUSrc_out_wire), 

.A1(ForwardB_data_top), 
.B1(EXEImmExt_out_wire), 

.Mux1_out(Mux1_out_top)
); 
			

// ALU Control Module
ALU_Control ALU_Control(
.Control_out(Control_out_top), 

.ALUOp(EXEALUOp_out_wire), 

.fun7(EXEInstrMEM_out7_wire), 

.fun3(EXEInstrMEM_out3_wire)
);


// ALU Module
ALU_Unit ALU(
.ALU_result(ALU_result_top), 
.Zero(Zero_top), 

.A(ForwardA_data_top), 

.B(Mux1_out_top), 

.Control_in(Control_out_top)
);
 

//Adder
Adder Adder(
.in_1(EXEPCout_out_wire), 
.in_2(EXEImmExt_out_wire), 

.Sum_out(Sum_out_top)
);


/// EXE-MEM PIPELINE REGISTER--------------------------------------
EXEMEM_Reg EXEMEM_Reg(

.EXEBranch_in(EXEBranch_out_wire),

.EXEMemRead_in(EXEMemRead_out_wire),

.EXEMemtoReg_in(EXEMemtoReg_out_wire),

.EXEMemWrite_in(EXEMemWrite_out_wire),

.EXERegWrite_in(EXERegWrite_out_wire), 

.EXESum_out_in(Sum_out_top),

.EXEALU_result_in(ALU_result_top),

.EXEZero_in(Zero_top),

.EXEread_data2_in(ForwardB_data_top), 

.EXEInstrMEM_in6(EXEInstrMEM_out6_wire),


.MEMBranch_out(MEMBranch_out_wire),

.MEMMemRead_out(MEMMemRead_out_wire), 

.MEMMemtoReg_out(MEMMemtoReg_out_wire),

.MEMMemWrite_out(MEMMemWrite_out_wire), 

.MEMRegWrite_out(MEMRegWrite_out_wire), 

.MEMSum_out_out(MEMSum_out_out_wire),

.MEMALU_result_out(MEMALU_result_out_wire),

.MEMZero_out(MEMZero_out_wire), 

.MEMread_data2_out(MEMread_data2_out_wire), 

.MEMInstrMEM_out6(MEMInstrMEM_out6_wire), 

.clk(clk), 
.reset(reset)
);
//----------------------------------------------------------------------						 



//AND Logic 
AND_logic AND(
.branch(MEMBranch_out_wire), 
.Zero(MEMZero_out_wire), 

.and_out(sel2_top)
);


// Data Memory 
Data_Memory Data_Memory(

.MemData_out(MemData_out_top), 

.MemRead(MEMMemRead_out_wire), 

.MemWrite(MEMMemWrite_out_wire), 

.read_address(MEMALU_result_out_wire[7:2]), 

.Write_data(MEMread_data2_out_wire), 

.clk(clk)
);



// MEM-WB PIPELINE REGISTER--------------------------------------------------
MEMWB_Reg MEMWB_Reg(

.MEMMemtoReg_in(MEMMemtoReg_out_wire),

.MEMRegWrite_in(MEMRegWrite_out_wire),

.MemData_out_in(MemData_out_top),

.MEMALU_result_in(MEMALU_result_out_wire), 
						  
.MEMInstrMEM_in6(MEMInstrMEM_out6_wire), 
				        
.WBMemtoReg_out(WBMemtoReg_out_wire),

.WBRegWrite_out(WBRegWrite_out_wire),

.WBData_out_out(WBData_out_out_wire),

.WBALU_result_out(WBALU_result_out_wire),
						  
.WBInstrMEM_out6(WBInstrMEM_out6_wire), 

.clk(clk), 

.reset(reset)
);
//---------------------------------------------------------------------------------------



/// Data Memory MUX3 
Mux3 DM_Mux3(

.sel3(WBMemtoReg_out_wire), 

.A3(WBALU_result_out_wire), 

.B3(WBData_out_out_wire), 

.Mux3_out(Mux3_out_top)
);



//DEBUG OUTPUTS
assign PC_debug = PC_top;

assign instruction_debug = instruction_top;

assign ALU_result_debug = ALU_result_top;

assign WB_result_debug = Mux3_out_top;


//assign LED = ALU_result_top[7:0];

endmodule 


/// Testbench
module tb_top;

reg clk, reset;

wire [31:0] PC_debug,instruction_debug,ALU_result_debug, WB_result_debug;
 

top uut(
.clk(clk), 
.reset(reset), 

.PC_debug(PC_debug), 

.instruction_debug(instruction_debug), 

.ALU_result_debug(ALU_result_debug), 

.WB_result_debug(WB_result_debug)
);


initial 
begin 

clk = 0;

reset = 1;

#5;

reset = 0;

#400;

$finish;

end


always 
begin 

#5 clk = ~clk;

end

endmodule