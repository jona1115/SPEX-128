/**
 * 
 * Specification:
 * 0. If i_ctrl[1:0] is 00:   1 x binary128 aka single_mode
 *  elif i_ctrl[1:0] is 01:   2 x binary64  aka two_sp_mode (sp == subword parallel)
 *  elif i_ctrl[1:0] is 10:   4 x binary32  aka four_sp_mode
 * 1. Do special type check and output for o_float_type_n accordingly.
 *  single_mode will only use s_float_type_a, and set NA to the b, c, d o_metadata.float_type_n
 *  two_sp_mode will only use s_float_type_a, and b, and set NA to the c, d o_metadata.float_type_n
 *  four_sp_mode will use all s_float_type_a, b, c, d
 * 2. We first calculate the "offset" of the exponent component
 *  if single_mode:
 *    s_shift_amount_a = i_float[126:112] - 16383
 *  elif two_sp_mode:
 *    s_shift_amount_a = i_float[126:116] - 1023
 *    s_shift_amount_b = i_float[62:52] - 1023
 *  elif four_sp_mode:
 *    s_shift_amount_a = i_float[126:119] - 127
 *    s_shift_amount_b = i_float[94:87] - 127
 *    s_shift_amount_c = i_float[62:55] - 127
 *    s_shift_amount_d = i_float[30:23] - 127
 * 
 */

// `include "float_metadata_pkg.svh"

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;
import fixed128_pkg::*;

module float_to_fixed #() (
  input   logic             i_clk,
  input   logic             i_reset, // Synchronous

  input   logic [127:0]     i_float,
  input   logic [3:0]       i_ctrl,
  output  logic [127:0]     o_fixed,
  output  float_metadata_t  o_metadata,

  output  logic [3:0]       o_sanity_identifier
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
sp_mode_t s_current_sp;
binary128_t s_binary128;
binary64_t s_binary64_a;
binary64_t s_binary64_b;
binary32_t s_binary32_a;
binary32_t s_binary32_b;
binary32_t s_binary32_c;
binary32_t s_binary32_d;
// For the type of float
float_flag_t s_float_type_a;
float_flag_t s_float_type_b;
float_flag_t s_float_type_c;
float_flag_t s_float_type_d;
// For temporary output
fixed128_t s_fixed128;
fixed128_t s_fixed64_a;
fixed128_t s_fixed64_b;
fixed128_t s_fixed32_a;
fixed128_t s_fixed32_b;
fixed128_t s_fixed32_c;
fixed128_t s_fixed32_d;
// Mantissa extended
logic [112:0] s_binary128_mantissa_extended = {1'b1, s_binary128.mantissa};
logic [52:0] s_binary64_a_mantissa_extended = {1'b1, s_binary64_a.mantissa};
logic [52:0] s_binary64_b_mantissa_extended = {1'b1, s_binary64_b.mantissa};
logic [23:0] s_binary32_a_mantissa_extended = {1'b1, s_binary32_a.mantissa};
logic [23:0] s_binary32_b_mantissa_extended = {1'b1, s_binary32_b.mantissa};
logic [23:0] s_binary32_c_mantissa_extended = {1'b1, s_binary32_c.mantissa};
logic [23:0] s_binary32_d_mantissa_extended = {1'b1, s_binary32_d.mantissa};

// Determine what sp (subword parallel) mode we are in based on input control
// signals.
// Using assign will make it "continuous assignment", so it is eval-ed before 
// always_comb blocks, usually we use assign for decoders. - ChatGPT
assign s_current_sp =
  (i_ctrl[1:0] == 2'b00) ? SINGLE_MODE  :
  (i_ctrl[1:0] == 2'b01) ? TWO_SP_MODE  :
  (i_ctrl[1:0] == 2'b10) ? FOUR_SP_MODE : INVALID_SP_MODE;

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


// Determine what the output float types are based on s_current_sp
always_comb begin : float_type_determiner
  case (s_current_sp)
    SINGLE_MODE: begin
      s_float_type_a = 
                (s_binary128.exp == '0 && s_binary128.mantissa == '0)                               ? ZERO          :
                (s_binary128.sign == '0 && s_binary128.exp == '1 && s_binary128.mantissa == '0)     ? POS_INF       :
                (s_binary128.sign == '1 && s_binary128.exp == '1 && s_binary128.mantissa == '0)     ? NEG_INF       :
                (s_binary128.exp == '1 && s_binary128.mantissa != '0)                               ? NAN           :
                (s_binary128.sign == '0 && s_binary128.exp == '0 && s_binary128.mantissa != '0)     ? POS_DENORMAL  :
                (s_binary128.sign == '1 && s_binary128.exp == '0 && s_binary128.mantissa != '0)     ? NEG_DENORMAL  :
                NORMAL;
      s_float_type_b = NA;
      s_float_type_c = NA;
      s_float_type_d = NA;
    end

    TWO_SP_MODE: begin
      s_float_type_a = 
                (s_binary64_a.exp == '0 && s_binary64_a.mantissa == '0)                             ? ZERO          :
                (s_binary64_a.sign == '0 && s_binary64_a.exp == '1 && s_binary64_a.mantissa == '0)  ? POS_INF       :
                (s_binary64_a.sign == '1 && s_binary64_a.exp == '1 && s_binary64_a.mantissa == '0)  ? NEG_INF       :
                (s_binary64_a.exp == '1 && s_binary64_a.mantissa != '0)                             ? NAN           :
                (s_binary64_a.sign == '0 && s_binary64_a.exp == '0 && s_binary64_a.mantissa != '0)  ? POS_DENORMAL  :
                (s_binary64_a.sign == '1 && s_binary64_a.exp == '0 && s_binary64_a.mantissa != '0)  ? NEG_DENORMAL  :
                NORMAL;
      s_float_type_b = 
                (s_binary64_b.exp == '0 && s_binary64_b.mantissa == '0)                             ? ZERO          :
                (s_binary64_b.sign == '0 && s_binary64_b.exp == '1 && s_binary64_b.mantissa == '0)  ? POS_INF       :
                (s_binary64_b.sign == '1 && s_binary64_b.exp == '1 && s_binary64_b.mantissa == '0)  ? NEG_INF       :
                (s_binary64_b.exp == '1 && s_binary64_b.mantissa != '0)                             ? NAN           :
                (s_binary64_b.sign == '0 && s_binary64_b.exp == '0 && s_binary64_b.mantissa != '0)  ? POS_DENORMAL  :
                (s_binary64_b.sign == '1 && s_binary64_b.exp == '0 && s_binary64_b.mantissa != '0)  ? NEG_DENORMAL  :
                NORMAL;
      s_float_type_c = NA;
      s_float_type_d = NA;
    end

    FOUR_SP_MODE: begin
      s_float_type_a = 
                (s_binary32_a.exp == '0 && s_binary32_a.mantissa == '0)                             ? ZERO          :
                (s_binary32_a.sign == '0 && s_binary32_a.exp == '1 && s_binary32_a.mantissa == '0)  ? POS_INF       :
                (s_binary32_a.sign == '1 && s_binary32_a.exp == '1 && s_binary32_a.mantissa == '0)  ? NEG_INF       :
                (s_binary32_a.exp == '1 && s_binary32_a.mantissa != '0)                             ? NAN           :
                (s_binary32_a.sign == '0 && s_binary32_a.exp == '0 && s_binary32_a.mantissa != '0)  ? POS_DENORMAL  :
                (s_binary32_a.sign == '1 && s_binary32_a.exp == '0 && s_binary32_a.mantissa != '0)  ? NEG_DENORMAL  :
                NORMAL;
      s_float_type_b = 
                (s_binary32_b.exp == '0 && s_binary32_b.mantissa == '0)                             ? ZERO          :
                (s_binary32_b.sign == '0 && s_binary32_b.exp == '1 && s_binary32_b.mantissa == '0)  ? POS_INF       :
                (s_binary32_b.sign == '1 && s_binary32_b.exp == '1 && s_binary32_b.mantissa == '0)  ? NEG_INF       :
                (s_binary32_b.exp == '1 && s_binary32_b.mantissa != '0)                             ? NAN           :
                (s_binary32_b.sign == '0 && s_binary32_b.exp == '0 && s_binary32_b.mantissa != '0)  ? POS_DENORMAL  :
                (s_binary32_b.sign == '1 && s_binary32_b.exp == '0 && s_binary32_b.mantissa != '0)  ? NEG_DENORMAL  :
                NORMAL;
      s_float_type_c = 
                (s_binary32_c.exp == '0 && s_binary32_c.mantissa == '0)                             ? ZERO          :
                (s_binary32_c.sign == '0 && s_binary32_c.exp == '1 && s_binary32_c.mantissa == '0)  ? POS_INF       :
                (s_binary32_c.sign == '1 && s_binary32_c.exp == '1 && s_binary32_c.mantissa == '0)  ? NEG_INF       :
                (s_binary32_c.exp == '1 && s_binary32_c.mantissa != '0)                             ? NAN           :
                (s_binary32_c.sign == '0 && s_binary32_c.exp == '0 && s_binary32_c.mantissa != '0)  ? POS_DENORMAL  :
                (s_binary32_c.sign == '1 && s_binary32_c.exp == '0 && s_binary32_c.mantissa != '0)  ? NEG_DENORMAL  :
                NORMAL;
      s_float_type_d = 
                (s_binary32_d.exp == '0 && s_binary32_d.mantissa == '0)                             ? ZERO          :
                (s_binary32_d.sign == '0 && s_binary32_d.exp == '1 && s_binary32_d.mantissa == '0)  ? POS_INF       :
                (s_binary32_d.sign == '1 && s_binary32_d.exp == '1 && s_binary32_d.mantissa == '0)  ? NEG_INF       :
                (s_binary32_d.exp == '1 && s_binary32_d.mantissa != '0)                             ? NAN           :
                (s_binary32_d.sign == '0 && s_binary32_d.exp == '0 && s_binary32_d.mantissa != '0)  ? POS_DENORMAL  :
                (s_binary32_d.sign == '1 && s_binary32_d.exp == '0 && s_binary32_d.mantissa != '0)  ? NEG_DENORMAL  :
                NORMAL;
    end

    INVALID_SP_MODE: begin
      s_float_type_a = NA;
      s_float_type_b = NA;
      s_float_type_c = NA;
      s_float_type_d = NA;
    end

    default: begin
      s_float_type_a = NA;
      s_float_type_b = NA;
      s_float_type_c = NA;
      s_float_type_d = NA;
    end
  endcase
end

// FSM
state_t s_curr_state, s_next_state;
always_ff @( posedge i_clk ) begin : float_to_fixed_FSM
  if (!i_reset) begin
    s_curr_state <= S0_IDLE;
  end
  else begin
    s_curr_state <= s_next_state;
  end
end

// todo
logic s_stage1_en, s_stage2_en;
always_comb begin : stage_en_control
  // Defaults
  s_next_state = s_curr_state;
  s_stage1_en = 1'b0;
  s_stage1_en = 1'b0;

  unique case (s_curr_state)
    S0_IDLE: begin
      s_next_state = S1_GET_SHIFT_AMOUNT;
    end
    S1_GET_SHIFT_AMOUNT: begin
      s_stage1_en = 1'b1;
      s_next_state = S2_CONVERT;
    end
    S2_CONVERT: begin
      s_stage2_en = 1'b1;
      s_next_state = S0_IDLE;
    end 
    default: begin
      s_next_state = S0_IDLE;
    end
  endcase
end

// Stage 1 block:
typedef logic signed [15:0] sh_t; // we use 16 bits so we can properly represent -ve shift amount 
                                  // for single_mode
sh_t s_shift_amount_a, s_shift_amount_b, s_shift_amount_c, s_shift_amount_d; // Why 14:0? Because in the worse case, we want to accomodate shifting 16383 position for binary128 decoding. Do we ACTUALLY have to accomodate that number? No, but for now, this is easiest to implement.
always_ff @( posedge i_clk ) begin : stage1_get_shift_amount
  if (!i_reset) begin
    s_shift_amount_a <= '0;
    s_shift_amount_b <= '0;
    s_shift_amount_c <= '0;
    s_shift_amount_d <= '0;
  end
  else begin
    // Default case
    s_shift_amount_a <= '0;
    s_shift_amount_b <= '0;
    s_shift_amount_c <= '0;
    s_shift_amount_d <= '0;

    if (s_stage1_en) begin
      // Switch case
      case (s_current_sp)
        SINGLE_MODE: begin
          s_shift_amount_a = $signed({1'b0, s_binary128.exp}) - 16'sd16383;
        end
        TWO_SP_MODE: begin
          s_shift_amount_a <= $signed({1'b0, s_binary64_a.exp}) - 12'sd1023;
          s_shift_amount_b <= $signed({1'b0, s_binary64_b.exp}) - 12'sd1023;
        end
        FOUR_SP_MODE: begin
          s_shift_amount_a <= $signed({1'b0, s_binary32_a.exp}) - 9'sd127;
          s_shift_amount_b <= $signed({1'b0, s_binary32_b.exp}) - 9'sd127;
          s_shift_amount_c <= $signed({1'b0, s_binary32_c.exp}) - 9'sd127;
          s_shift_amount_d <= $signed({1'b0, s_binary32_d.exp}) - 9'sd127;
        end
        default: begin
          // Already have default assignment
        end
      endcase // case (s_current_sp)
    end // if (s_stage1_en) begin
  end // else begin
end // always_ff

// Stage 2 block:
always_ff @( posedge i_clk ) begin : stage2_convert
  if (!i_reset) begin
    s_fixed128 = '0;
    s_fixed64_a = '0;
    s_fixed64_b = '0;
    s_fixed32_a = '0;
    s_fixed32_b = '0;
    s_fixed32_c = '0;
    s_fixed32_d = '0;
  end
  else begin
    if (s_stage2_en) begin
      // Default case
      s_fixed128 = '0;
      s_fixed64_a = '0;
      s_fixed64_b = '0;
      s_fixed32_a = '0;
      s_fixed32_b = '0;
      s_fixed32_c = '0;
      s_fixed32_d = '0;

      // assign the integer and frac
      case (s_current_sp)
        SINGLE_MODE: begin
          // do the sign
          s_fixed128.sign_portion = s_binary128.sign;

          if (s_shift_amount_a >= 0) begin
            if (s_shift_amount_a >= 128) begin
              s_fixed128.int_portion = '1;
            end // if (s_shift_amount_a >= 128) begin
            else begin
              
            end
          end // if (s_shift_amount_a >= 0) begin
          else begin
            // s_shift_amount_a < 0
          end // else begin
        end
        TWO_SP_MODE: begin
          // do the sign
          s_fixed64_a.sign_portion = s_binary64_a.sign;
          s_fixed64_b.sign_portion = s_binary64_b.sign;
        end
        FOUR_SP_MODE: begin
          // do the sign
          s_fixed32_a.sign_portion = s_binary32_a.sign;
          s_fixed32_b.sign_portion = s_binary32_b.sign;
          s_fixed32_c.sign_portion = s_binary32_c.sign;
          s_fixed32_d.sign_portion = s_binary32_d.sign;
        end
        default: begin

        end
      endcase
    end // if (s_stage2_en) begin
  end // else begin
end // always_ff


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata.sp_mode       = s_current_sp;
assign o_metadata.float_type_a  = s_float_type_a;
assign o_metadata.float_type_b  = s_float_type_b;
assign o_metadata.float_type_c  = s_float_type_c;
assign o_metadata.float_type_d  = s_float_type_d;

// Passthrough (temp)
assign o_fixed = i_float;

// This is the identifier (ie version number) of this block
assign o_sanity_identifier      = 4'b0000;

endmodule