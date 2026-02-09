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
  parameter int NUM_BITS_128  = 128,
  parameter int NUM_BITS_64   = 64,
  parameter int NUM_BITS_32   = 32,
  
  parameter int FIXED128_SHIFT_AMOUNT_INT_PORTION_OVERFLOW  = 9,  // 9 because there is 10 int portion bits and with the implicit 1, we can only afford to shift right by 10-1
  parameter int FIXED64_SHIFT_AMOUNT_INT_PORTION_OVERFLOW   = 9,  // 9 because there is 10 int portion bits and with the implicit 1, we can only afford to shift right by 10-1
  parameter int FIXED32_SHIFT_AMOUNT_INT_PORTION_OVERFLOW   = 9,  // 9 because there is 10 int portion bits and with the implicit 1, we can only afford to shift right by 10-1

  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32
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
  S2_CONVERT            = 2'b10,
  S3_FINALIZE           = 2'b11
} state_t;

//=====================================================================================
// Signal definitions
//=====================================================================================
sp_mode_t s_current_sp;
binary128_t s_binary128;
binary64_t s_binary64_a;
binary64_t s_binary64_b;
binary32_t s_binary32_a;
binary32_t s_binary32_b;
binary32_t s_binary32_c;
binary32_t s_binary32_d;
// For internal output
fixed128_t s_fixed128;
fixed64_t s_fixed64_a;
fixed64_t s_fixed64_b;
fixed32_t s_fixed32_a;
fixed32_t s_fixed32_b;
fixed32_t s_fixed32_c;
fixed32_t s_fixed32_d;
// For temporary internal output
fixed128_t s_fixed128_temp;
fixed64_t s_fixed64_a_temp;
fixed64_t s_fixed64_b_temp;
fixed32_t s_fixed32_a_temp;
fixed32_t s_fixed32_b_temp;
fixed32_t s_fixed32_c_temp;
fixed32_t s_fixed32_d_temp;
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
// For status
logic s_S1_busy;
logic s_S2_busy;

// Determine what sp (subword parallel) mode we are in based on input control
// signals.
// Using assign will make it "continuous assignment", so it is eval-ed before 
// always_comb blocks, usually we use assign for decoders. - ChatGPT
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
float_metadata_t s_o_metadata;
float_classifier #() my_float_classifier_0 (
  .i_current_sp(s_current_sp),
  .i_float(i_float),
  .o_metadata(s_o_metadata)
);

/**
 * FSM
 */
state_t s_curr_state, s_next_state;
always_ff @( posedge i_clk ) begin : float_to_fixed_FSM
  if (!i_rst_n) begin
    s_curr_state <= S0_IDLE;
  end
  else begin
    s_curr_state <= s_next_state;
  end
end

/**
 * 
 * State transition control
 * 
 */
logic s_stage1_en, s_stage2_en, s_stage3_en;
always_comb begin : stage_en_control
  // Defaults
  s_next_state = s_curr_state;
  s_stage1_en = 1'b0;
  s_stage2_en = 1'b0;
  s_stage3_en = 1'b0;

  unique case (s_curr_state)
    S0_IDLE: begin
      if (i_valid) begin
        // Only proceed when input is valid
        s_next_state = S1_GET_SHIFT_AMOUNT;
      end
    end
    S1_GET_SHIFT_AMOUNT: begin
      s_stage1_en = 1'b1;
      s_next_state = S2_CONVERT;
    end
    S2_CONVERT: begin
      s_stage2_en = 1'b1;
      s_next_state = S3_FINALIZE;
    end
    S3_FINALIZE: begin
      s_stage3_en = 'b1;
      s_next_state = S0_IDLE;
    end
    default: begin
      s_next_state = S0_IDLE;
    end
  endcase
end

/**
 * Stage 1 block
 */
sh_t s_shift_amount_a, s_shift_amount_b, s_shift_amount_c, s_shift_amount_d; // Why 15:0? Because in the 
                                                                             // worse case, we want to 
                                                                             // accomodate shifting 16383 
                                                                             // position for binary128 
                                                                             // decoding. Do we ACTUALLY 
                                                                             // have to accomodate that 
                                                                             // number? No, but for now, 
                                                                             // this is easiest to implement.
always_ff @( posedge i_clk ) begin : stage1_get_shift_amount
  if (!i_rst_n) begin
    s_shift_amount_a <= '0;
    s_shift_amount_b <= '0;
    s_shift_amount_c <= '0;
    s_shift_amount_d <= '0;

    s_fixed128_temp  <= '0;
    s_fixed64_a_temp <= '0;
    s_fixed64_b_temp <= '0;
    s_fixed32_a_temp <= '0;
    s_fixed32_b_temp <= '0;
    s_fixed32_c_temp <= '0;
    s_fixed32_d_temp <= '0;
    s_o_error[1]     <= 1'b0;
    s_o_error[ERROR_SIGNAL_NUM_BITS-1:2] <= '0;
  end
  else begin
    if (s_stage1_en) begin
      // Switch case
      case (s_current_sp)
        SINGLE_MODE: begin
          s_shift_amount_a <= unbias_q128(s_binary128.exp);
        end
        TWO_SP_MODE: begin
          s_shift_amount_a <= unbias_q64(s_binary64_a.exp);
          s_shift_amount_b <= unbias_q64(s_binary64_b.exp);
        end
        FOUR_SP_MODE: begin
          s_shift_amount_a <= unbias_q32(s_binary32_a.exp);
          s_shift_amount_b <= unbias_q32(s_binary32_b.exp);
          s_shift_amount_c <= unbias_q32(s_binary32_c.exp);
          s_shift_amount_d <= unbias_q32(s_binary32_d.exp);
        end
        default: begin
          assert (0) else begin
              s_o_error[1] <= 1'b1;
              // $fatal(1, "Entered illegal branch"); // This is for simulator not synthesis
            end
        end
      endcase // case (s_current_sp)
    end // if (s_stage1_en) begin

    // Map extended mantissa(s) of input to fixed temporarily
    s_fixed128_temp[117:5] <= s_binary128_mantissa_extended;
    s_fixed64_a_temp[53:1] <= s_binary64_a_mantissa_extended;
    s_fixed64_b_temp[53:1] <= s_binary64_b_mantissa_extended;
    s_fixed32_a_temp[21:0] <= s_binary32_a_mantissa_extended[23:2]; // should be good not tested yet
    s_fixed32_b_temp[21:0] <= s_binary32_b_mantissa_extended[23:2]; // should be good not tested yet
    s_fixed32_c_temp[21:0] <= s_binary32_c_mantissa_extended[23:2]; // should be good not tested yet
    s_fixed32_d_temp[21:0] <= s_binary32_d_mantissa_extended[23:2]; // should be good not tested yet
  end // else begin
end // always_ff

/**
 * Stage 2
 */
logic s_S2_valid;
always_ff @( posedge i_clk ) begin : stage2_convert
  logic [NUM_BITS_128-1:0] fixed128_shifted;
  logic [NUM_BITS_64-1:0] fixed64_a_shifted;
  logic [NUM_BITS_64-1:0] fixed64_b_shifted;
  logic [NUM_BITS_32-1:0] fixed32_a_shifted;
  logic [NUM_BITS_32-1:0] fixed32_b_shifted;
  logic [NUM_BITS_32-1:0] fixed32_c_shifted;
  logic [NUM_BITS_32-1:0] fixed32_d_shifted;

  if (!i_rst_n) begin
    s_fixed128.int_portion  <= '0;
    s_fixed128.frac_portion <= '0;
    s_fixed64_a.int_portion  <= '0;
    s_fixed64_a.frac_portion <= '0;
    s_fixed64_b.int_portion  <= '0;
    s_fixed64_b.frac_portion <= '0;
    s_fixed32_a.int_portion  <= '0;
    s_fixed32_a.frac_portion <= '0;
    s_fixed32_b.int_portion  <= '0;
    s_fixed32_b.frac_portion <= '0;
    s_fixed32_c.int_portion  <= '0;
    s_fixed32_c.frac_portion <= '0;
    s_fixed32_d.int_portion  <= '0;
    s_fixed32_d.frac_portion <= '0;

    s_S2_valid  <= '0;
    s_o_error[0] <= 1'b0;
  end
  else begin
    if (s_stage2_en) begin
      s_S2_valid <= '1;
      
      // assign the integer and frac
      case (s_current_sp)
        SINGLE_MODE: begin
          if (s_shift_amount_a >= 0 && s_shift_amount_a <= 9) begin
            // Case a:
            fixed128_shifted = s_fixed128_temp << s_shift_amount_a;
          end
          else if (s_shift_amount_a < 0) begin
            // Case b: (s_shift_amount_a >= -4 && s_shift_amount_a < 0)
            // Case d: (s_shift_amount_a < -4)
            // This else if statement combines both
            fixed128_shifted = s_fixed128_temp >> -s_shift_amount_a;
          end
          else if (s_shift_amount_a > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (well, except
            // the sign bit but that will be dealt with in stage 3).
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
          s_fixed128.int_portion  <= fixed128_shifted[126:117];
          s_fixed128.frac_portion <= fixed128_shifted[116:0];
        end

        TWO_SP_MODE: begin
          if (s_shift_amount_a >= 0 && s_shift_amount_a <= 9) begin
            // Case a:
            fixed64_a_shifted = s_fixed64_a_temp << s_shift_amount_a;
          end
          else if (s_shift_amount_a < 0) begin
            // Case b: (s_shift_amount_a >= -4 && s_shift_amount_a < 0)
            // Case d: (s_shift_amount_a < -4)
            // This else if statement combines both
            fixed64_a_shifted = s_fixed64_a_temp >> -s_shift_amount_a;
          end
          else if (s_shift_amount_a > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (well, except
            // the sign bit but that will be dealt with in stage 3).
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
          s_fixed64_a.int_portion  <= fixed64_a_shifted[62:52];
          s_fixed64_a.frac_portion <= fixed64_a_shifted[51:0];

          if (s_shift_amount_b >= 0 && s_shift_amount_b <= 9) begin
            // Case a:
            fixed64_b_shifted = s_fixed64_b_temp << s_shift_amount_b;
          end
          else if (s_shift_amount_b < 0) begin
            // Case b: (s_shift_amount_b >= -4 && s_shift_amount_b < 0)
            // Case d: (s_shift_amount_b < -4)
            // This else if statement combines both
            fixed64_b_shifted = s_fixed64_b_temp >> -s_shift_amount_b;
          end
          else if (s_shift_amount_b > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (well, except
            // the sign bit but that will be dealt with in stage 3).
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
          s_fixed64_b.int_portion  <= fixed64_b_shifted[62:52];
          s_fixed64_b.frac_portion <= fixed64_b_shifted[51:0];
        end

        FOUR_SP_MODE: begin
          if (s_shift_amount_a >= 0 && s_shift_amount_a <= 9) begin
            // Case a:
            fixed32_a_shifted = s_fixed32_a_temp << s_shift_amount_a;
          end
          else if (s_shift_amount_a < 0) begin
            // Case b: (s_shift_amount_a >= -4 && s_shift_amount_a < 0)
            // Case d: (s_shift_amount_a < -4)
            // This else if statement combines both
            fixed32_a_shifted = s_fixed32_a_temp >> -s_shift_amount_a;
          end
          else if (s_shift_amount_a > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (well, except
            // the sign bit but that will be dealt with in stage 3).
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
          s_fixed32_a.int_portion  <= fixed32_a_shifted[30:21];
          s_fixed32_a.frac_portion <= fixed32_a_shifted[20:0];

          if (s_shift_amount_b >= 0 && s_shift_amount_b <= 9) begin
            // Case a:
            fixed32_b_shifted = s_fixed32_b_temp << s_shift_amount_b;
          end
          else if (s_shift_amount_b < 0) begin
            // Case b: (s_shift_amount_b >= -4 && s_shift_amount_b < 0)
            // Case d: (s_shift_amount_b < -4)
            // This else if statement combines both
            fixed32_b_shifted = s_fixed32_b_temp >> -s_shift_amount_b;
          end
          else if (s_shift_amount_b > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (well, except
            // the sign bit but that will be dealt with in stage 3).
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
          s_fixed32_b.int_portion  <= fixed32_b_shifted[30:21];
          s_fixed32_b.frac_portion <= fixed32_b_shifted[20:0];

          if (s_shift_amount_c >= 0 && s_shift_amount_c <= 9) begin
            // Case a:
            fixed32_c_shifted = s_fixed32_c_temp << s_shift_amount_c;
          end
          else if (s_shift_amount_c < 0) begin
            // Case b: (s_shift_amount_c >= -4 && s_shift_amount_c < 0)
            // Case d: (s_shift_amount_c < -4)
            // This else if statement combines both
            fixed32_c_shifted = s_fixed32_c_temp >> -s_shift_amount_c;
          end
          else if (s_shift_amount_c > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (well, except
            // the sign bit but that will be dealt with in stage 3).
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
          s_fixed32_c.int_portion  <= fixed32_c_shifted[30:21];
          s_fixed32_c.frac_portion <= fixed32_c_shifted[20:0];

          if (s_shift_amount_d >= 0 && s_shift_amount_d <= 9) begin
            // Case a:
            fixed32_d_shifted = s_fixed32_d_temp << s_shift_amount_d;
          end
          else if (s_shift_amount_d < 0) begin
            // Case b: (s_shift_amount_d >= -4 && s_shift_amount_d < 0)
            // Case d: (s_shift_amount_d < -4)
            // This else if statement combines both
            fixed32_d_shifted = s_fixed32_d_temp >> -s_shift_amount_d;
          end
          else if (s_shift_amount_d > 9) begin
            // Case c:
            // In this case, we have a overflow in the int part, an overflow in the int part
            // is an overflow in the overall value, so fill everything with 1s. (well, except
            // the sign bit but that will be dealt with in stage 3).
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
          s_fixed32_d.int_portion  <= fixed32_d_shifted[30:21];
          s_fixed32_d.frac_portion <= fixed32_d_shifted[20:0];
        end
        default: begin

        end
      endcase // case (s_current_sp)
    end // if (s_stage2_en) begin
  end // else begin
end // always_ff

/**
 * Stage 3
 * In this stage we will deal with assigning sign bit.
 */
always_ff @( posedge i_clk ) begin : stage3_finalize
  if (!i_rst_n) begin
    s_fixed128.sign_portion <= 1'b0;
    s_fixed64_a.sign_portion <= 1'b0;
    s_fixed64_b.sign_portion <= 1'b0;
    s_fixed32_a.sign_portion <= 1'b0;
    s_fixed32_b.sign_portion <= 1'b0;
    s_fixed32_c.sign_portion <= 1'b0;
    s_fixed32_d.sign_portion <= 1'b0;
  end
  else begin
    if (s_stage3_en) begin
      case (s_current_sp)
        SINGLE_MODE: begin
          // Assign sign bit
          s_fixed128.sign_portion <= s_binary128.sign;
        end
        TWO_SP_MODE: begin
          // Assign sign bit
          s_fixed64_a.sign_portion <= s_binary64_a.sign;
          s_fixed64_b.sign_portion <= s_binary64_b.sign;
        end
        FOUR_SP_MODE: begin
          // Assign sign bit
          s_fixed32_a.sign_portion <= s_binary32_a.sign;
          s_fixed32_b.sign_portion <= s_binary32_b.sign;
          s_fixed32_c.sign_portion <= s_binary32_c.sign;
          s_fixed32_d.sign_portion <= s_binary32_d.sign;
        end
        default: begin
        end
      endcase // case (s_current_sp)
    end // if (s_stage2_en) begin
  end // else begin
end // always_ff


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata = s_o_metadata;

// assign o_fixed = (s_current_sp == SINGLE_MODE)  ? {s_binary128.sign,
//                                                    s_fixed128.int_portion,
//                                                    s_fixed128.frac_portion}   :
//                  (s_current_sp == TWO_SP_MODE)  ? {s_binary64_a.sign,
//                                                    s_fixed64_a.int_portion,
//                                                    s_fixed64_a.frac_portion,
//                                                    s_binary64_b.sign,
//                                                    s_fixed64_b.int_portion,
//                                                    s_fixed64_b.frac_portion}  :
//                  (s_current_sp == FOUR_SP_MODE) ? {s_binary32_a.sign,
//                                                    s_fixed32_a.int_portion,
//                                                    s_fixed32_a.frac_portion,
//                                                    s_binary32_b.sign,
//                                                    s_fixed32_b.int_portion,
//                                                    s_fixed32_b.frac_portion,
//                                                    s_binary32_c.sign,
//                                                    s_fixed32_c.int_portion,
//                                                    s_fixed32_c.frac_portion,
//                                                    s_binary32_d.sign,
//                                                    s_fixed32_d.int_portion,
//                                                    s_fixed32_d.frac_portion}  :
assign o_fixed = (s_current_sp == SINGLE_MODE)  ? s_fixed128                                            :
                 (s_current_sp == TWO_SP_MODE)  ? {s_fixed64_a, s_fixed64_b}                            :
                 (s_current_sp == FOUR_SP_MODE) ? {s_fixed32_a, s_fixed32_b, s_fixed32_c, s_fixed32_d}  :
                 '0;

// This is the identifier (ie version number) of this block
assign o_sanity_identifier      = 4'b0000;

assign o_error = s_o_error;
assign o_debug = s_o_debug;

assign o_valid = s_S2_valid;

endmodule // module float_to_fixed #()
