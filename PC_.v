/// Program Counter Module
module Program_Counter(PC_out,PC_in,clk,reset);

input clk,reset;
input  [31:0] PC_in;
output reg [31:0] PC_out;

always @(posedge clk or posedge reset)
begin
if (reset) begin
PC_out <= 32'b00; end
else begin
PC_out <= PC_in;end
end
endmodule


// PC+4 Module 
module PC_plus_4(NextoPC,fromPC);
input [31:0] fromPC;
output reg [31:0]  NextoPC;

always @(*)
begin NextoPC =  4 + fromPC ;end
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

        6'd8 : instruction_out = 32'b000000001111_00000_010_01011_0000011; // lw x13,15(x0)

        6'd9 : instruction_out = 32'b000000001011_10000_010_01110_0000011; // lw x14,11(x25)


        // Store

        6'd10 : instruction_out = 32'b0000000_10010_10000_010_01100_0100011; // sw x18,12(x16)

        6'd11 : instruction_out = 32'b0000000_01010_10000_010_01000_0100011; // sw x10,10(x16)


        // Branch

        6'd12 : instruction_out = 32'h00948663; // beq x9,x9,12


        default : instruction_out = 32'b00000000000000000000000000010011; // addi x0,x0,0

    endcase

end

endmodule




///Register File 
module Reg_File(read_data1,read_data2,Regwrite,Rs1,Rs2,Write_data,Rd,clk,reset);
input clk,reset,Regwrite;
input [4:0]  Rs1,Rs2,Rd;
input [31:0] Write_data;
output  [31:0] read_data1,read_data2;
reg [31:0] Registers[31:0];
integer k;


//initial 

assign read_data1 = Registers[Rs1];
assign read_data2 = Registers[Rs2];


always @(posedge clk or posedge reset)
begin 
if (reset)
        begin 
		       for(k=0; k<32; k=k+1) begin
				 Registers[k] <= 32'b00;
				 end
		 end
else if((Regwrite) && (Rd != 5'b00)) 
begin
       Registers[Rd] <= Write_data;
end
end
endmodule

//Immidiate Generator
module ImmGen(ImmExt,instruction);

input [31:0] instruction;
output reg [31:0] ImmExt;

always @(*)
begin 
      case(instruction[6:0])
		      7'b0010011: ImmExt <= {{20{instruction[31]}}, instruction[31:20]}; // I-type  
            7'b0000011: ImmExt <= {{20{instruction[31]}}, instruction[31:20]}; // Load-type
            7'b0100011: ImmExt <= {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // Store-type
            7'b1100011: ImmExt <= {{19{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type 
            7'b0110111: ImmExt <= {instruction[31:12], 12'b0}; // U-type
	         7'b0010111: ImmExt <= {instruction[31:12], 12'b0}; // U-type
            7'b1101111: ImmExt <= {{11{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
		      default    : ImmExt <= 32'b0;
		endcase 
end 
endmodule 

//Control Unit
module Control_Unit(Branch, MemRead, MemtoReg, ALUOp,MemWrite, ALUSrc, RegWrite,instruction);
input [6:0] instruction;
output reg Branch, MemRead, MemtoReg,MemWrite, ALUSrc, RegWrite;
output reg [1:0] ALUOp;

always @(*)
begin 
      case(instruction)
		7'b0110011 : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b001000_10; end   // R-type
		7'b0010011 : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b101000_10; end   // I-type
		7'b0000011 : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b111100_00; end   // LW-type
		7'b0100011 : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b100010_00; end   // SW-type
		7'b1100011 : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b000001_01;  end   // BEQ-type
		7'b1101111 : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b001000_10; end   // JUMP
		7'b0110111 : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b001000_10;  end   // LUI
		default    : begin {ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, ALUOp} <= 8'b000000_00; end
		endcase
end
endmodule
		
		
// ALU Module
module ALU_Unit(ALU_result,Zero,A,B,Control_in);
input [31:0] A,B;
input [3:0] Control_in;
output reg Zero;
output reg [31:0] ALU_result;

always @(Control_in or A or B or ALU_result)
begin 
        case(Control_in) 
		      4'b0000:   ALU_result <= A + B;           		// ADD
            4'b0001: ALU_result <= A - B;           		// SUB
            4'b0010: ALU_result <= A & B;           		// AND
            4'b0011: ALU_result <= A | B;           		// OR
            4'b0100: ALU_result <= A ^ B;           		// XOR
            4'b0101: ALU_result <= A << B[4:0];     		// SLL (Shift Left Logical)
            4'b0110: ALU_result <= A >> B[4:0];     		// SRL (Shift Right Logical)
            4'b0111: ALU_result <= $signed(A) >>> B[4:0];    // SRA (Shift Right Arithmetic)
            4'b1000: ALU_result <=($signed(A) < $signed(B)) ? 32'b1 : 32'b0;
            default: ALU_result <= 32'b0;          	
		  
        endcase
		  Zero <= (ALU_result == 32'b0) ? 1'b1 : 1'b0;
end 
endmodule


// ALU Control Module
module ALU_Control(Control_out, ALUOp, fun7,fun3);
input [6:0] fun7;
input [2:0] fun3;
input [1:0] ALUOp; 
output reg [3:0] Control_out;

always @(*)
begin     
           
         case({ALUOp, fun7,fun3})
	  12'b10_0000000_000 : Control_out <= 4'b0000;    // ADD 
    12'b00_0000000_000 : Control_out <= 4'b0000;    // ADD 
    12'b00_0000000_001 : Control_out <= 4'b0000;    // ADD 
    12'b00_0000000_010 : Control_out <= 4'b0000;    // ADD 
    12'b10_0100000_000 : Control_out <= 4'b0001;    // SUB 
    12'b10_0000000_111 : Control_out <= 4'b0010;    // AND
    12'b10_0000000_110 : Control_out <= 4'b0011;    // OR
    12'b10_0000000_100 : Control_out <= 4'b0100;    // XOR
    12'b10_0000000_001 : Control_out <= 4'b0101;    // SLL
    12'b10_0000000_101 : Control_out <= 4'b0110;    // SRL
    12'b10_0100000_101 : Control_out <= 4'b0111;    // SRA
    12'b10_0000000_010 : Control_out <= 4'b1000;    // SLT
    default            : Control_out <= 4'b0000;
//			12'b00_0000000_000: Control_out <= 4'b0010;  //LW/SW type
//			12'b01_0000000_000: Control_out <= 4'b0110;   // BEQ type
//			12'b10_0000000_000: Control_out <= 4'b0010;    // ADD/ADDI type
//			12'b10_0100000_000: Control_out <= 4'b0110;   // SUB type
//			12'b10_0000000_111: Control_out <= 4'b0000;   // AND type
//			12'b10_0000000_110: Control_out <= 4'b0001;   // OR type
//			default    : Control_out <= 4'b0000;
			endcase
end
endmodule

// Data Memory 
module Data_Memory(MemData_out, MemRead, MemWrite, read_address, Write_data,clk);
input clk,MemRead, MemWrite;
input [5:0] read_address;
input [31:0] Write_data;
output [31:0] MemData_out;
integer k;
reg [31:0] D_Memory[63:0];

always @(posedge clk)
begin 
//if(reset)
//        begin 
//		        for(k=0; k<64; k=k+1)begin
//				  D_Memory[k] <= 32'b00;
//				  end
//				  end
if(MemWrite)begin
         D_Memory[read_address] <= Write_data;
         end
end
assign MemData_out = (MemRead) ? D_Memory[read_address] :  32'b00;
endmodule			

//// Multiplexers 		
///MUX1
module Mux1(sel1,A1,B1,Mux1_out);
input sel1;
input [31:0] A1,B1;
output [31:0] Mux1_out;	

assign Mux1_out = (sel1==1'b0) ? A1 : B1;
endmodule

///MUX2
module Mux2(sel2,A2,B2,Mux2_out);
input sel2;
input [31:0] A2,B2;
output [31:0] Mux2_out;	

assign Mux2_out = (sel2==1'b0) ? A2 : B2;
endmodule

///MUX3
module Mux3(sel3,A3,B3,Mux3_out);
input sel3;
input [31:0] A3,B3;
output [31:0] Mux3_out;	

assign Mux3_out = (sel3==1'b0) ? A3 : B3;
endmodule		  
		
	
//AND Logic 
module AND_logic(branch, Zero, and_out);
input branch, Zero;
output and_out;

assign and_out = branch & Zero;
endmodule

//Adder
module Adder(in_1,in_2,Sum_out);
input [31:0] in_1,in_2;
output [31:0] Sum_out;

assign Sum_out = in_1 + in_2;
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


// Program Counter 
Program_Counter PC( .PC_out(PC_top), .PC_in(PC_in_top), .clk(clk), .reset(reset));

// PC Adder
PC_plus_4 PCAdder( .NextoPC(NextoPC_top), .fromPC(PC_top));

// Instruction Memory 
Instruction_Mem Inst_Memory( .instruction_out(instruction_top), .read_address(PC_top[7:2]));

//Control Unit
Control_Unit CU( .Branch(branch_top), .MemRead(MemRead_top), .MemtoReg(MemtoReg_top), .ALUOp(ALUOp_top), 
.MemWrite(MemWrite_top), .ALUSrc(ALUSrc_top), .RegWrite(RegWrite_top), .instruction(instruction_top[6:0]));	


//Immidiate Generator
ImmGen ImmGen( .ImmExt(ImmExt_top), .instruction(instruction_top));
		   
// Register File
Reg_File Reg_File( .read_data1(Rd1_top), .read_data2(Rd2_top), .Regwrite(RegWrite_top), .Rs1(instruction_top[19:15]),
 .Rs2(instruction_top[24:20]), .Write_data(Mux3_out_top), .Rd(instruction_top[11:7]), .clk(clk), .reset(reset));


//AND Logic 
AND_logic AND( .branch(branch_top), .Zero(Zero_top), .and_out(sel2_top));

// ALU Mux1
Mux1 Mux1( .sel1(ALUSrc_top), .A1(Rd2_top), .B1(ImmExt_top), .Mux1_out( Mux1_out_top)); 
			

// ALU Control Module
ALU_Control ALU_Control( .Control_out(Control_out_top), .ALUOp(ALUOp_top), .fun7(instruction_top[31:25]), 
.fun3(instruction_top[14:12]));


// ALU Module
ALU_Unit ALU( .ALU_result(ALU_result_top), .Zero(Zero_top), .A(Rd1_top), .B( Mux1_out_top), 
.Control_in(Control_out_top));
 



//Adder
Adder Adder( .in_1(PC_top), .in_2(ImmExt_top), .Sum_out(Sum_out_top));


/// Adder MUX2
Mux2 adder_Mux2( .sel2(sel2_top), .A2(NextoPC_top), .B2(Sum_out_top), .Mux2_out(PC_in_top));

// Data Memory 
Data_Memory Data_Memory( .MemData_out(MemData_out_top), .MemRead(MemRead_top), .MemWrite(MemWrite_top), 
.read_address(ALU_result_top[7:2]), .Write_data(Rd2_top), .clk(clk));

/// Data Memory MUX3 
Mux3 DM_Mux3( .sel3(MemtoReg_top), .A3(ALU_result_top), .B3(MemData_out_top), .Mux3_out(Mux3_out_top));


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
 
top uut(.clk(clk), .reset(reset), .PC_debug(PC_debug), .instruction_debug(instruction_debug), 
           .ALU_result_debug(ALU_result_debug), .WB_result_debug(WB_result_debug));

initial 
begin 
clk = 0;
reset = 1;
#5;
reset = 0;
#400;
end

always begin 
#5 clk = ~clk;
end
endmodule
