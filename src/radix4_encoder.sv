/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 2/5/2026
 * 
 ********************************************************************
 * 
 * Description:
 * This module encodes a multiplicand based on radix-4 modified
 * booth.
 * 
 ********************************************************************
 * 
 * Modification history:
 *    Ver   |  Who       |  Date	    |  Changes
 *  ------- + ---------- + ------------ + --------------------------
 *    1.00  |  Jonathan  |  2/5/2026    |  Birth of this file
 * 
 *******************************************************************/


module radix4_encoder #(
  parameter int EX_MAN_BITS_128   = 113
) (
  input logic [EX_MAN_BITS_128-1 : 0]   i_multiplicand,

  input logic [2 : 0]                   i_a,  // a_-1

  output logic [EX_MAN_BITS_128+1 : 0]  o_encoded_multiplicand
);

logic [EX_MAN_BITS_128 : 0]   s_x_ex;
logic [EX_MAN_BITS_128+1 : 0] s_2x;

always_comb begin : radix4_lookuptable
  s_x_ex  = {1'b0, i_multiplicand};
  s_2x    = {1'b0, i_multiplicand, 1'b0};

  unique case (i_a)
    3'b000: begin
      // 0
      o_encoded_multiplicand = '0;
    end // 3'b000

    3'b001: begin
      // X
      o_encoded_multiplicand = {1'b0, s_x_ex};
    end // 3'b001

    3'b010: begin
      // X
      o_encoded_multiplicand = {1'b0, s_x_ex};
    end // 3'b010

    3'b011: begin
      // 2X: X << 1
      o_encoded_multiplicand = s_2x;
    end // 3'b011

    3'b100: begin
      // -2X: (~X+1) << 1
      o_encoded_multiplicand = {~s_2x + 1'b1};
    end // 3'b100

    3'b101: begin
      // -X: ~X+1
      o_encoded_multiplicand = ~{1'b0, s_x_ex} + 1'b1;
    end // 3'b101

    3'b110: begin
      // -X: ~X+1
      o_encoded_multiplicand = ~{1'b0, s_x_ex} + 1'b1;
    end // 3'b110

    3'b111: begin
      // 0
      o_encoded_multiplicand = '0;
    end // 3'b111

    default: begin
      // 0
      o_encoded_multiplicand = '0;
    end // default
  endcase
end // radix4_lookuptable
endmodule // radix4_encoder