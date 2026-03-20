/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Description:
 * Contains module to convert a subword parallel (SP) float(s) into
 * fixed Qs10.n format, where s is the sign, and n is the number of 
 * bits for the fractional portion of the fixed point format.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
 * 
 *******************************************************************/

`include "config.svh" // Here lives a bunch of macro flags...

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;
import fixed128_pkg::*;
import fixed64_pkg::*;
import fixed32_pkg::*;
import unbiasing_pkg::*;

module float_to_fixed #(
  parameter int NUM_BITS_128              = 128,
  parameter int NUM_BITS_64               = 64,
  parameter int NUM_BITS_32               = 32,
  
  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS     = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS     = 32,

  // Do not change unless intentional:
  parameter int MODULE_LATENCY            = 1,

  // Identifier const
  parameter logic [3:0] MODULE_IDENTIFIER = 4'b0000
) (
  input   logic                                   i_clk,
  input   logic                                   i_rst_n, // Synchronous

  input   logic [NUM_BITS_128-1:0]                i_float,
  input   logic [3:0]                             i_ctrl,
  output  logic [127:0]                           o_fixed,
  output  float_metadata_t                        o_metadata,

  // Handshake
  input   logic                                   i_valid,
  output  logic                                   o_valid,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// State definition
//=====================================================================================
typedef enum logic [1:0] { 
  S0_IDLE               = 2'b00,
  S1_GET_SHIFT_AMOUNT   = 2'b01,
  S2_CONVERT            = 2'b10
} state_t;

//=====================================================================================
// Signal definitions
//=====================================================================================
binary128_t s_binary128;
binary64_t s_binary64_a;
binary64_t s_binary64_b;
binary32_t s_binary32_a;
binary32_t s_binary32_b;
binary32_t s_binary32_c;
binary32_t s_binary32_d;
logic [127:0] s_fixed_packed_q;
// Mantissa extended
logic [112:0] s_binary128_mantissa_extended;
logic [52:0]  s_binary64_a_mantissa_extended;
logic [52:0]  s_binary64_b_mantissa_extended;
logic [23:0]  s_binary32_a_mantissa_extended;
logic [23:0]  s_binary32_b_mantissa_extended;
logic [23:0]  s_binary32_c_mantissa_extended;
logic [23:0]  s_binary32_d_mantissa_extended;
// Error and debug signals
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_o_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_o_debug;

// Determine what sp (subword parallel) mode we are in based on input control signals.
// Using assign will make it "continuous assignment", so it is eval-ed before always_comb 
// blocks, usually we use assign for decoders. -ChatGPT
sp_mode_t s_current_sp;

float_metadata_t s_metadata_decoded;
assign s_current_sp =
  (i_ctrl[1:0] == 2'b00) ? SINGLE_MODE  :
  (i_ctrl[1:0] == 2'b01) ? TWO_SP_MODE  :
  (i_ctrl[1:0] == 2'b10) ? FOUR_SP_MODE : INVALID_SP_MODE;
// // Check that INVALID_SP_MODE should never be passed into this module; commented because cant do this ouside a always block or need to use property, but todo we still want to perform this check
// assert(s_current_sp != INVALID_SP_MODE && i_valid == 1'b1) else begin
//   s_o_error[2] <= 1'b1;
//  $fatal(1, "INVALID_SP_MODE detected"); // This is for simulator not synthesis
// end

// Generate a bunch of helper signals as decoders
// single mode
assign s_binary128.sign       = i_float[127];
assign s_binary128.exp        = i_float[126:112];
assign s_binary128.mantissa   = i_float[111:0];
// two sp mode
assign s_binary64_a.sign      = i_float[127];
assign s_binary64_a.exp       = i_float[126:116];
assign s_binary64_a.mantissa  = i_float[115:64];
assign s_binary64_b.sign      = i_float[63];
assign s_binary64_b.exp       = i_float[62:52];
assign s_binary64_b.mantissa  = i_float[51:0];
// four sp mode
assign s_binary32_a.sign      = i_float[127];
assign s_binary32_a.exp       = i_float[126:119];
assign s_binary32_a.mantissa  = i_float[118:96];
assign s_binary32_b.sign      = i_float[95];
assign s_binary32_b.exp       = i_float[94:87];
assign s_binary32_b.mantissa  = i_float[86:64];
assign s_binary32_c.sign      = i_float[63];
assign s_binary32_c.exp       = i_float[62:55];
assign s_binary32_c.mantissa  = i_float[54:32];
assign s_binary32_d.sign      = i_float[31];
assign s_binary32_d.exp       = i_float[30:23];
assign s_binary32_d.mantissa  = i_float[22:0];
// extended mantissa
assign s_binary128_mantissa_extended = {1'b1, s_binary128.mantissa};
assign s_binary64_a_mantissa_extended = {1'b1, s_binary64_a.mantissa};
assign s_binary64_b_mantissa_extended = {1'b1, s_binary64_b.mantissa};
assign s_binary32_a_mantissa_extended = {1'b1, s_binary32_a.mantissa};
assign s_binary32_b_mantissa_extended = {1'b1, s_binary32_b.mantissa};
assign s_binary32_c_mantissa_extended = {1'b1, s_binary32_c.mantissa};
assign s_binary32_d_mantissa_extended = {1'b1, s_binary32_d.mantissa};

// Default stuff out
always_ff @( posedge i_clk ) begin : defaulter
  if (!i_rst_n) begin
    s_o_debug <= '0;
  end
  // else begin // commented out because there are drivers of these signals in other always_ff blocks, but by commenting this part out might lead to infer latches
  //   s_o_error <= s_o_error;
  //   s_o_debug <= s_o_debug;
  // end
end

/**
 * Decoder to determine what the output float types are based on s_current_sp
 */
float_classifier #() my_float_classifier_0 (
  .i_current_sp(s_current_sp),
  .i_float(i_float),
  .o_metadata(s_metadata_decoded)
);

/**
 * 
 * State transition control
 * 
 */
logic s_S1_en;
localparam int PIPE_DEPTH = MODULE_LATENCY;
logic [PIPE_DEPTH-1 : 0] s_pipe_valid;
logic [PIPE_DEPTH-1 : 0] s_pipe_valid_next;

logic s_fire;
assign s_fire = i_valid; // "decodes" the valid bit

generate
  if (PIPE_DEPTH == 1) begin : gen_pipe_valid_depth_1
    assign s_pipe_valid_next = s_fire;
  end
  else begin : gen_pipe_valid_depth_n
    assign s_pipe_valid_next = {s_pipe_valid[PIPE_DEPTH-2 : 0], s_fire};
  end
endgenerate

assign s_S1_en = s_fire;

/**
 * FSM
 */
always_ff @( posedge i_clk ) begin : float_to_fixed_FSM
  if (!i_rst_n) begin
    s_pipe_valid <= '0;
  end
  else begin
    s_pipe_valid <= s_pipe_valid_next;
  end
end

//=====================================================================================
// Stage 1 (conversion)
//=====================================================================================
always_ff @( posedge i_clk ) begin : stage1_convert
  logic [NUM_BITS_128-1:0] fixed128_temp;
  logic [NUM_BITS_64-1:0] fixed64_a_temp;
  logic [NUM_BITS_64-1:0] fixed64_b_temp;
  logic [NUM_BITS_32-1:0] fixed32_a_temp;
  logic [NUM_BITS_32-1:0] fixed32_b_temp;
  logic [NUM_BITS_32-1:0] fixed32_c_temp;
  logic [NUM_BITS_32-1:0] fixed32_d_temp;

  logic [NUM_BITS_128-1:0] fixed128_shifted;
  logic [NUM_BITS_64-1:0] fixed64_a_shifted;
  logic [NUM_BITS_64-1:0] fixed64_b_shifted;
  logic [NUM_BITS_32-1:0] fixed32_a_shifted;
  logic [NUM_BITS_32-1:0] fixed32_b_shifted;
  logic [NUM_BITS_32-1:0] fixed32_c_shifted;
  logic [NUM_BITS_32-1:0] fixed32_d_shifted;
  sh_t shift_amount_a, shift_amount_b, shift_amount_c, shift_amount_d;

  if (!i_rst_n) begin
    s_fixed_packed_q <= '0;
    s_o_error <= '0;
  end
  else begin
    if (s_S1_en) begin
      shift_amount_a = '0;
      shift_amount_b = '0;
      shift_amount_c = '0;
      shift_amount_d = '0;

      fixed128_temp = '0;
      fixed64_a_temp = '0;
      fixed64_b_temp = '0;
      fixed32_a_temp = '0;
      fixed32_b_temp = '0;
      fixed32_c_temp = '0;
      fixed32_d_temp = '0;

      // Map extended mantissa(s) of input to fixed temporarily
      fixed128_temp[117:5] = s_binary128_mantissa_extended;
      fixed64_a_temp[53:1] = s_binary64_a_mantissa_extended;
      fixed64_b_temp[53:1] = s_binary64_b_mantissa_extended;
      fixed32_a_temp[21:0] = s_binary32_a_mantissa_extended[23:2]; // should be good not tested yet
      fixed32_b_temp[21:0] = s_binary32_b_mantissa_extended[23:2]; // should be good not tested yet
      fixed32_c_temp[21:0] = s_binary32_c_mantissa_extended[23:2]; // should be good not tested yet
      fixed32_d_temp[21:0] = s_binary32_d_mantissa_extended[23:2]; // should be good not tested yet

      case (s_current_sp)
        SINGLE_MODE: begin
          shift_amount_a = unbias_q128(s_binary128.exp);
        end
        TWO_SP_MODE: begin
          shift_amount_a = unbias_q64(s_binary64_a.exp);
          shift_amount_b = unbias_q64(s_binary64_b.exp);
        end
        FOUR_SP_MODE: begin
          shift_amount_a = unbias_q32(s_binary32_a.exp);
          shift_amount_b = unbias_q32(s_binary32_b.exp);
          shift_amount_c = unbias_q32(s_binary32_c.exp);
          shift_amount_d = unbias_q32(s_binary32_d.exp);
        end
        default: begin
          assert (0) else begin
            s_o_error[1] <= 1'b1;
            // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
          end
        end
      endcase

      // Register the packed output directly so downstream logic sees a FF output
      // instead of a mode-select mux hanging off of the output bus.
      case (s_current_sp)
        SINGLE_MODE: begin
          if (shift_amount_a >= 0 && shift_amount_a <= 9) begin
            // Case a:
            fixed128_shifted = fixed128_temp << shift_amount_a;
          end
          else if (shift_amount_a < 0) begin
            // Case b: (shift_amount_a >= -4 && shift_amount_a < 0)
            // Case d: (shift_amount_a < -4)
            // This else if statement combines both
            fixed128_shifted = fixed128_temp >> -shift_amount_a;
          end
          else if (shift_amount_a > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (the sign bit
            // is assigned in the final assignment section).
            fixed128_shifted = '1;
          end
          else begin
            // Should never be the case
            fixed128_shifted = '0;
            assert (0) else begin
              s_o_error[0] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
          end
          s_fixed_packed_q <= {s_binary128.sign, fixed128_shifted[126:117], fixed128_shifted[116:0]};
        end

        TWO_SP_MODE: begin
          if (shift_amount_a >= 0 && shift_amount_a <= 9) begin
            // Case a:
            fixed64_a_shifted = fixed64_a_temp << shift_amount_a;
          end
          else if (shift_amount_a < 0) begin
            // Case b: (shift_amount_a >= -4 && shift_amount_a < 0)
            // Case d: (shift_amount_a < -4)
            // This else if statement combines both
            fixed64_a_shifted = fixed64_a_temp >> -shift_amount_a;
          end
          else if (shift_amount_a > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (the sign bit
            // is assigned in the final assignment section).
            fixed64_a_shifted = '1;
          end
          else begin
            // Should never be the case
            fixed64_a_shifted = '0;
            assert (0) else begin
              s_o_error[0] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
          end
          if (shift_amount_b >= 0 && shift_amount_b <= 9) begin
            // Case a:
            fixed64_b_shifted = fixed64_b_temp << shift_amount_b;
          end
          else if (shift_amount_b < 0) begin
            // Case b: (shift_amount_b >= -4 && shift_amount_b < 0)
            // Case d: (shift_amount_b < -4)
            // This else if statement combines both
            fixed64_b_shifted = fixed64_b_temp >> -shift_amount_b;
          end
          else if (shift_amount_b > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (the sign bit
            // is assigned in the final assignment section).
            fixed64_b_shifted = '1;
          end
          else begin
            // Should never be the case
            fixed64_b_shifted = '0;
            assert (0) else begin
              s_o_error[0] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
          end
          s_fixed_packed_q <= {{s_binary64_a.sign, fixed64_a_shifted[62:52], fixed64_a_shifted[51:0]},
                               {s_binary64_b.sign, fixed64_b_shifted[62:52], fixed64_b_shifted[51:0]}};
        end

        FOUR_SP_MODE: begin
          if (shift_amount_a >= 0 && shift_amount_a <= 9) begin
            // Case a:
            fixed32_a_shifted = fixed32_a_temp << shift_amount_a;
          end
          else if (shift_amount_a < 0) begin
            // Case b: (shift_amount_a >= -4 && shift_amount_a < 0)
            // Case d: (shift_amount_a < -4)
            // This else if statement combines both
            fixed32_a_shifted = fixed32_a_temp >> -shift_amount_a;
          end
          else if (shift_amount_a > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (the sign bit
            // is assigned in the final assignment section).
            fixed32_a_shifted = '1;
          end
          else begin
            // Should never be the case
            fixed32_a_shifted = '0;
            assert (0) else begin
              s_o_error[0] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
          end

          if (shift_amount_b >= 0 && shift_amount_b <= 9) begin
            // Case a:
            fixed32_b_shifted = fixed32_b_temp << shift_amount_b;
          end
          else if (shift_amount_b < 0) begin
            // Case b: (shift_amount_b >= -4 && shift_amount_b < 0)
            // Case d: (shift_amount_b < -4)
            // This else if statement combines both
            fixed32_b_shifted = fixed32_b_temp >> -shift_amount_b;
          end
          else if (shift_amount_b > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (the sign bit
            // is assigned in the final assignment section).
            fixed32_b_shifted = '1;
          end
          else begin
            // Should never be the case
            fixed32_b_shifted = '0;
            assert (0) else begin
              s_o_error[0] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
          end

          if (shift_amount_c >= 0 && shift_amount_c <= 9) begin
            // Case a:
            fixed32_c_shifted = fixed32_c_temp << shift_amount_c;
          end
          else if (shift_amount_c < 0) begin
            // Case b: (shift_amount_c >= -4 && shift_amount_c < 0)
            // Case d: (shift_amount_c < -4)
            // This else if statement combines both
            fixed32_c_shifted = fixed32_c_temp >> -shift_amount_c;
          end
          else if (shift_amount_c > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (the sign bit
            // is assigned in the final assignment section).
            fixed32_c_shifted = '1;
          end
          else begin
            // Should never be the case
            fixed32_c_shifted = '0;
            assert (0) else begin
              s_o_error[0] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
          end

          if (shift_amount_d >= 0 && shift_amount_d <= 9) begin
            // Case a:
            fixed32_d_shifted = fixed32_d_temp << shift_amount_d;
          end
          else if (shift_amount_d < 0) begin
            // Case b: (shift_amount_d >= -4 && shift_amount_d < 0)
            // Case d: (shift_amount_d < -4)
            // This else if statement combines both
            fixed32_d_shifted = fixed32_d_temp >> -shift_amount_d;
          end
          else if (shift_amount_d > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (the sign bit
            // is assigned in the final assignment section).
            fixed32_d_shifted = '1;
          end
          else begin
            // Should never be the case
            fixed32_d_shifted = '0;
            assert (0) else begin
              s_o_error[0] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
          end
          s_fixed_packed_q <= {{s_binary32_a.sign, fixed32_a_shifted[30:21], fixed32_a_shifted[20:0]},
                               {s_binary32_b.sign, fixed32_b_shifted[30:21], fixed32_b_shifted[20:0]},
                               {s_binary32_c.sign, fixed32_c_shifted[30:21], fixed32_c_shifted[20:0]},
                               {s_binary32_d.sign, fixed32_d_shifted[30:21], fixed32_d_shifted[20:0]}};
        end
        default: begin
          s_fixed_packed_q <= '0;
        end
      endcase // case (s_current_sp)
    end // if (s_S1_en) begin
  end // else begin
end // always_ff

//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata = s_metadata_decoded;

assign o_fixed = s_fixed_packed_q;

// This is the identifier (ie version number) of this block
assign o_sanity_identifier      = MODULE_IDENTIFIER;

assign o_error = s_o_error;
assign o_debug = s_o_debug;

assign o_valid = s_pipe_valid[PIPE_DEPTH-1];

endmodule // module float_to_fixed #()
