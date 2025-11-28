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

module float_classifier #() (
  input  sp_mode_t        i_current_sp,
  input  logic [127:0]    i_float,

  output float_metadata_t o_metadata
);


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

//=====================================================================================
// Module body
//=====================================================================================
// For the type of float
float_flag_t s_float_type_a;
float_flag_t s_float_type_b;
float_flag_t s_float_type_c;
float_flag_t s_float_type_d;
always_comb begin : float_type_determiner
  case (i_current_sp)
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


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata.sp_mode = i_current_sp; // Pass through
assign o_metadata.float_type_a = s_float_type_a;
assign o_metadata.float_type_b = s_float_type_b;
assign o_metadata.float_type_c = s_float_type_c;
assign o_metadata.float_type_d = s_float_type_d;


endmodule
