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
 *    shift_amount_a = i_float[126:112] - 16383
 *  elif two_sp_mode:
 *    shift_amount_a = i_float[126:116] - 1023
 *    shift_amount_b = i_float[62:52] - 1023
 *  elif four_sp_mode:
 *    shift_amount_a = i_float[126:119] - 127
 *    shift_amount_b = i_float[94:87] - 127
 *    shift_amount_c = i_float[62:55] - 127
 *    shift_amount_d = i_float[30:23] - 127
 * 
 */

// `include "float_metadata_pkg.svh"

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;

module float_to_fixed #() (
  input   logic             i_clk,
  input   logic [127:0]     i_float,
  input   logic [3:0]       i_ctrl,
  output  logic [127:0]     o_fixed,
  output  float_metadata_t  o_metadata
);

// Signal definitions
sp_mode_t s_current_sp;
binary128_t s_binary128;
binary64_t s_binary64_a;
binary64_t s_binary64_b;
binary32_t s_binary32_a;
binary32_t s_binary32_b;
binary32_t s_binary32_c;
binary32_t s_binary32_d;

float_flag_t s_float_type_a;
float_flag_t s_float_type_b;
float_flag_t s_float_type_c;
float_flag_t s_float_type_d;

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


// Final assignment
assign o_metadata.sp_mode       = s_current_sp;
assign o_metadata.float_type_a  = s_float_type_a;
assign o_metadata.float_type_b  = s_float_type_b;
assign o_metadata.float_type_c  = s_float_type_c;
assign o_metadata.float_type_d  = s_float_type_d;

// Passthrough (temp)
assign o_fixed = i_float;

endmodule