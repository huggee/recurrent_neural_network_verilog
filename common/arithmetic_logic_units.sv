`ifndef DEFMACRO
    `include "def.sv"
    `define DEFMACRO
`endif

// 各フォーマット
/*
8bit →  8'b0_00_00000 符号_整数_小数  // 1_2_5
16bit   16'b0_00_0000000000000    //  1_2_13
20bit   20'b0_000000_0000000000000  // 1_6_13
*/

/******************************/
/******* SHIFTER    ***********/
/******************************/
module right_shifter_16(
    input  [15:0] IN,
    output [15:0] OUT
);
    assign OUT = {{`N_SHIFT{IN[15]}}, IN[15:`N_SHIFT]};
endmodule

/******************************/
/******* SUBTRACTER ***********/
/******************************/
module subtracter_8_8_8(
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] OUT
);
    wire [8:0] extA;
    wire [8:0] extB;
    wire [8:0] SUB;
    wire [1:0] carry;

    assign extA  = {A[7],A};
    assign extB  = {B[7],B};
    assign SUB   = extA - extB;
    assign carry = SUB[8:7];
    assign OUT   = (carry == 2'b01) ? {1'b0,{7{1'b1}}} :
                   (carry == 2'b10) ? {1'b1,{7{1'b0}}} :
                   {SUB[8],SUB[6:0]};
endmodule

module subtracter_8_12_12(
    input  [7:0]  A,
    input  [11:0] B,
    output [11:0] OUT
);
    wire [12:0] extA;
    wire [12:0] extB;
    wire [12:0] SUB;
    wire [1:0] carry;

    assign extA  = {{5{A[7]}}, A};
    assign extB  = {B[11], B};
    assign SUB   = extA - extB;
    assign carry = SUB[12:11];
    assign OUT   = (carry == 2'b01) ? {1'b0,{11{1'b1}}} :
                   (carry == 2'b10) ? {1'b1,{11{1'b0}}} :
                   SUB[11:0];
endmodule

module subtracter_12_8_12(
    input  [11:0] A,
    input  [7:0]  B,
    output [11:0] OUT
);
    wire [12:0] extA;
    wire [12:0] extB;
    wire [12:0] SUB;
    wire [1:0] carry;

    assign extA  = {A[11], A};
    assign extB  = {{5{B[7]}}, B};
    assign SUB   = extA - extB;
    assign carry = SUB[12:11];
    assign OUT   = (carry == 2'b01) ? {1'b0,{11{1'b1}}} :
                   (carry == 2'b10) ? {1'b1,{11{1'b0}}} :
                   SUB[11:0];
endmodule

module subtracter_16_16_16(
    input  [15:0] A,
    input  [15:0] B,
    output [15:0] OUT
);
    wire [16:0] extA;
    wire [16:0] extB;
    wire [16:0] SUB;
    wire [1:0] carry;

    assign extA  = {A[15], A};
    assign extB  = {B[15], B};
    assign SUB   = extA - extB;
    assign carry = SUB[16:15];
    assign OUT   = (carry == 2'b01) ? {1'b0,{15{1'b1}}} :
                   (carry == 2'b10) ? {1'b1,{15{1'b0}}} :
                   SUB[15:0];
endmodule

/******************************/
/******* ADDER      ***********/
/******************************/
module adder_20_20_20(
    input     [19:0] A,
    input     [19:0] B,
    output    [19:0] OUT
  );
  wire [20:0] extA;
  wire [20:0] extB;
  wire [20:0] ADD;
  wire [1:0] carry;

  assign extA = {A[19],A};
  assign extB = {B[19],B};
  assign ADD = extA + extB;
  assign carry = ADD[20:19];

  assign OUT = (carry == 2'b01) ? {1'b0,{19{1'b1}}} :
               (carry == 2'b10) ? {1'b1,{19{1'b0}}} :
               {ADD[19:0]};
endmodule

module adder_16_20_20(
    input     [15:0] A,
    input     [19:0] B,
    output    [19:0] OUT
  );
  wire [20:0] extA;
  wire [20:0] extB;
  wire [20:0] ADD;
  wire [1:0] carry;

  assign extA = {{4{A[15]}}, A};
  assign extB = {B[19], B};
  assign ADD = extA + extB;
  assign carry = ADD[20:19];

  assign OUT = (carry == 2'b01) ? {1'b0,{19{1'b1}}} :
               (carry == 2'b10) ? {1'b1,{19{1'b0}}} :
               {ADD[19:0]};
endmodule

module adder_16_16_16(
    input     [15:0] A,
    input     [15:0] B,
    output    [15:0] OUT
  );
  wire [16:0] extA;
  wire [16:0] extB;
  wire [16:0] ADD;
  wire [1:0] carry;

  assign extA = {A[15],A};
  assign extB = {B[15],B};
  assign ADD = extA + extB;
  assign carry = ADD[16:15];

  assign OUT = (carry == 2'b01) ? {1'b0,{15{1'b1}}} :
               (carry == 2'b10) ? {1'b1,{15{1'b0}}} :
               {ADD[16],ADD[14:0]};

endmodule


module adder_8_16_16(
    input  [7:0] A,
    input  [15:0] B,
    output [15:0] OUT
);
    wire [16:0] extA;
    wire [16:0] extB;
    wire [16:0] ADD;
    wire [1:0]  carry;

    assign extA  = {{8{A[7]}}, A};
    assign extB  = {B[15], B};
    assign ADD   = extA + extB;
    assign carry = ADD[16:15];
    assign OUT = (carry == 2'b01)? {1'b0, {15{1'b1}}} :
                 (carry == 2'b10)? {1'b1, {15{1'b0}}} :
                 ADD[15:0];
endmodule

module adder_8_8_8(
    input  [7:0] A,
    input  [7:0] B,
    output [7:0] OUT
);
    wire [8:0] extA;
    wire [8:0] extB;
    wire [8:0] ADD;
    wire [1:0]  carry;

    assign extA  = {A[7], A};
    assign extB  = {B[7], B};
    assign ADD   = extA + extB;
    assign carry = ADD[8:7];
    assign OUT = (carry == 2'b01)? {1'b0, {7{1'b1}}} :
                 (carry == 2'b10)? {1'b1, {7{1'b0}}} :
                 ADD[7:0];

endmodule

module adder_8_8_12(
    input  [7:0] A,
    input  [7:0] B,
    output [11:0] OUT
);
    wire [12:0] extA;
    wire [12:0] extB;
    wire [12:0] ADD;
    wire [1:0]  carry;

    assign extA  = {{5{A[7]}}, A};
    assign extB  = {{5{B[7]}}, B};
    assign ADD   = extA + extB;
    assign carry = ADD[12:11];
    assign OUT = (carry == 2'b01)? {1'b0, {11{1'b1}}} :
                 (carry == 2'b10)? {1'b1, {11{1'b0}}} :
                 ADD[11:0];

endmodule

module adder_8_12_12(
    input  [7:0] A,
    input  [11:0] B,
    output [11:0] OUT
);
    wire [12:0] extA;
    wire [12:0] extB;
    wire [12:0] ADD;
    wire [1:0]  carry;

    assign extA  = {{5{A[7]}}, A};
    assign extB  = {B[11], B};
    assign ADD   = extA + extB;
    assign carry = ADD[12:11];
    assign OUT = (carry == 2'b01)? {1'b0, {11{1'b1}}} :
                 (carry == 2'b10)? {1'b1, {11{1'b0}}} :
                 ADD[11:0];

endmodule

/******************************/
/******* MULTIPLIER ***********/
/******************************/
module multiplier_8_8_8(
    input [7:0] A,
    input [7:0] B,
    output [7:0] OUT
);

    wire [15:0] extA;
    wire [15:0] extB;
    wire [15:0] MUL;

    assign extA = {{8{A[7]}}, A};
    assign extB = {{8{B[7]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[15], MUL[11:10], MUL[9:5]};
endmodule


module multiplier_8_16_16(
	input  [7:0]  A,
    input  [15:0] B,
	output [15:0] OUT
);
    wire [23:0] extA;
    wire [23:0] extB;
    wire [23:0] MUL;

    assign extA = {{16{A[7]}}, A};
    assign extB = {{8{B[15]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[23], MUL[19:18], MUL[17:5]};
endmodule

module multiplier_8_12_16(
	input  [7:0]  A,
    input  [11:0] B,
	output [15:0] OUT
);
    wire [19:0] extA;
    wire [19:0] extB;
    wire [19:0] MUL;

    assign extA = {{12{A[7]}}, A};
    assign extB = {{8{B[11]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[19], MUL[17:16], MUL[15:3]};
endmodule

module multiplier_8_20_16(
	input  [7:0]  A,
    input  [19:0] B,
	output [15:0] OUT
);
    wire [27:0] extA;
    wire [27:0] extB;
    wire [27:0] MUL;

    assign extA = {{20{A[7]}}, A};
    assign extB = {{8{B[19]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[27], MUL[19:18], MUL[17:5]};
endmodule


module multiplier_12_16_20(
	input  [11:0] A,
    input  [15:0] B,
	output [19:0] OUT
);
    wire [27:0] extA;
    wire [27:0] extB;
    wire [27:0] MUL;

    assign extA = {{16{A[11]}}, A};
    assign extB = {{12{B[15]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[27], MUL[23:18], MUL[17:5]};
endmodule


module multiplier_16_8_8(
    input  [15:0] A,
    input  [7:0]  B,
    output [7:0]  OUT
);

    wire [23:0] extA;
    wire [23:0] extB;
    wire [23:0] MUL;

    assign extA = {{8{A[15]}}, A};
    assign extB = {{16{B[7]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[23], MUL[19:18], MUL[17:13]};
endmodule

module multiplier_16_16_16(
	input  [15:0] A,
    input  [15:0] B,
	output [15:0] OUT
);
    wire [31:0] extA;
    wire [31:0] extB;
    wire [31:0] MUL;

    assign extA = {{16{A[15]}}, A};
    assign extB = {{16{B[15]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[31], MUL[27:26], MUL[25:13]};
endmodule

module multiplier_16_20_20(
	input  [15:0] A,
    input  [19:0] B,
	output [19:0] OUT
);
    wire [35:0] extA;
    wire [35:0] extB;
    wire [35:0] MUL;

    assign extA = {{20{A[15]}}, A};
    assign extB = {{16{B[19]}}, B};
    assign MUL  = extA * extB;
    assign OUT  = {MUL[35], MUL[31:26], MUL[25:13]};
endmodule

module multiplier_20_16_16(
	input  [19:0] A,
  input  [15:0]B,
	output [15:0] OUT
	);

  wire [35:0] extA;
  wire [35:0] extB;
  wire [35:0] MUL;

  assign extA = {{16{A[19]}}, A};
  assign extB = {{20{B[15]}}, B};
  assign MUL  = extA * extB;

  assign OUT = {MUL[35], MUL[27:13]};

endmodule

// module multiplier_8_8_8(
//     input [7:0] A,
//     input [7:0] B,
//     output [7:0] OUT
// );
// 
//     wire signed [15:0] extA;
//     wire signed [15:0] extB;
//     wire signed [15:0] MUL;
// 
//     assign extA = {{8{A[7]}}, A};
//     assign extB = {{8{B[7]}}, B};
//     assign MUL  = extA * extB;
//     assign OUT  = {MUL[15], MUL[11:10], MUL[9:5]};
// endmodule
// 
// module multiplier_8_16_16(
// 	input  [7:0]  A,
//     input  [15:0] B,
// 	output [15:0] OUT
// );
//   wire signed [23:0] extA;
//   wire signed [23:0] extB;
//   wire signed [23:0] MUL;
// 
//   assign extA = {{16{A[7]}}, A};
//   assign extB = {{8{B[15]}}, B};
//   assign MUL  = extA * extB;
//   assign OUT  = {MUL[23], MUL[19:18], MUL[17:5]};
// endmodule
// 
// module multiplier_16_16_16(
// 	input  [15:0] A,
//     input  [15:0] B,
// 	output [15:0] OUT
// );
//   wire signed [31:0] extA;
//   wire signed [31:0] extB;
//   wire signed [31:0] MUL;
// 
//   assign extA = {{16{A[15]}}, A};
//   assign extB = {{16{B[15]}}, B};
//   assign MUL  = extA * extB;
// 	assign OUT  = {MUL[31], MUL[27:26], MUL[25:13]};
// endmodule
// 
