/********************************************************************
 *
 * Originator   : Jonathan Tan feat. ChatGPT 5.2 Codex
 * Date         : 01/11/2026
 *
 ********************************************************************
 *
 * Description:
 * Helpers to convert IEEE-754 binary128 to binary64/binary32 with
 * round-to-nearest, ties-to-even (RNE).
 *
 *******************************************************************/

package binary128_convert_pkg;

  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;

  // Tree-style leading-zero count for a 113-bit vector.
  // Returns 0..112 for non-zero inputs, and 113 when input is zero.
  function automatic logic [6:0] lzc_113(input logic [112:0] in);
    logic [127:0] in_ext;
    logic [6:0] lz;
    logic [63:0] lvl64;
    logic [31:0] lvl32;
    logic [15:0] lvl16;
    logic [7:0]  lvl8;
    logic [3:0]  lvl4;
    logic [1:0]  lvl2;
    begin
      if (~|in) begin
        lzc_113 = 7'd113;
      end
      else begin
        in_ext = {in, 15'b0};

        if (|in_ext[127:64]) begin
          lz[6] = 1'b0;
          lvl64 = in_ext[127:64];
        end
        else begin
          lz[6] = 1'b1;
          lvl64 = in_ext[63:0];
        end

        if (|lvl64[63:32]) begin
          lz[5] = 1'b0;
          lvl32 = lvl64[63:32];
        end
        else begin
          lz[5] = 1'b1;
          lvl32 = lvl64[31:0];
        end

        if (|lvl32[31:16]) begin
          lz[4] = 1'b0;
          lvl16 = lvl32[31:16];
        end
        else begin
          lz[4] = 1'b1;
          lvl16 = lvl32[15:0];
        end

        if (|lvl16[15:8]) begin
          lz[3] = 1'b0;
          lvl8  = lvl16[15:8];
        end
        else begin
          lz[3] = 1'b1;
          lvl8  = lvl16[7:0];
        end

        if (|lvl8[7:4]) begin
          lz[2] = 1'b0;
          lvl4  = lvl8[7:4];
        end
        else begin
          lz[2] = 1'b1;
          lvl4  = lvl8[3:0];
        end

        if (|lvl4[3:2]) begin
          lz[1] = 1'b0;
          lvl2  = lvl4[3:2];
        end
        else begin
          lz[1] = 1'b1;
          lvl2  = lvl4[1:0];
        end

        lz[0] = (~lvl2[1]) & (lvl2[1] | lvl2[0]);
        lzc_113 = lz;
      end
    end
  endfunction

  function automatic binary64_t binary128_to_binary64_rne(input logic [127:0] in_bits);
    localparam logic signed [17:0] C_BIAS128     = 18'sd16383;
    localparam logic signed [17:0] C_SUB_EXP128  = -18'sd16382;
    localparam logic signed [17:0] C_BIAS64      = 18'sd1023;
    localparam logic signed [17:0] C_EXP_MAX64   = 18'sd1023;
    localparam logic signed [17:0] C_EXP_MIN64   = -18'sd1022;
    localparam logic signed [17:0] C_SHIFT_ALL64 = 18'sd55; // M_BITS + 3
    typedef logic [10:0] exp64_bits_t;

    binary128_t in;
    binary64_t out;
    binary64_t cand_nan;
    binary64_t cand_inf;
    binary64_t cand_zero;
    binary64_t cand_finite;

    logic is_exp_all_ones;
    logic is_exp_zero;
    logic is_frac_zero;
    logic is_nan;
    logic is_inf;
    logic is_zero;
    logic is_sub;

    logic [112:0] sig_full;
    logic [6:0]   lz;
    logic [112:0] sig_norm;
    logic [112:0] sig_aligned;

    logic signed [17:0] exp_unbiased;
    logic signed [17:0] exp_norm;
    logic signed [17:0] shift_sub_s;
    logic signed [17:0] exp_rounded;

    logic finite_overflow;
    logic finite_subnormal;
    logic [6:0] shift_sub_amt;
    logic shift_sub_large;
    logic normal_overflow;

    logic [52:0] keep;
    logic G;
    logic R;
    logic S;
    logic round_inc;
    logic [53:0] rounded;
    logic round_carry;
    begin
      in = binary128_t'(in_bits);

      is_exp_all_ones = &in.exp;
      is_exp_zero     = ~|in.exp;
      is_frac_zero    = ~|in.mantissa;

      is_nan  = is_exp_all_ones & ~is_frac_zero;
      is_inf  = is_exp_all_ones &  is_frac_zero;
      is_zero = is_exp_zero     &  is_frac_zero;
      is_sub  = is_exp_zero     & ~is_frac_zero;

      sig_full = {~is_exp_zero, in.mantissa};
      lz       = lzc_113(sig_full);
      sig_norm = sig_full << lz;

      exp_unbiased = is_sub ? C_SUB_EXP128 : ($signed({3'b000, in.exp}) - C_BIAS128);
      exp_norm     = exp_unbiased - $signed({11'd0, lz});

      finite_overflow  = (exp_norm > C_EXP_MAX64);
      finite_subnormal = (exp_norm < C_EXP_MIN64);
      shift_sub_s      = C_EXP_MIN64 - exp_norm;
      shift_sub_amt    = shift_sub_s[6:0];
      shift_sub_large  = finite_subnormal && (shift_sub_s >= C_SHIFT_ALL64);

      sig_aligned = sig_norm;
      if (finite_subnormal) begin
        if (shift_sub_large) begin
          sig_aligned = '0;
        end
        else begin
          sig_aligned = sig_norm >> shift_sub_amt;
        end
      end

      keep = '0;
      G    = 1'b0;
      R    = 1'b0;
      S    = 1'b0;
      if (finite_subnormal && shift_sub_large) begin
        S = |sig_norm;
      end
      else begin
        keep = sig_aligned[112 -: 53];
        G    = sig_aligned[59];
        R    = sig_aligned[58];
        S    = |sig_aligned[57:0];
      end

      round_inc   = G && (R || S || keep[0]);
      rounded     = {1'b0, keep} + {{53{1'b0}}, round_inc};
      round_carry = rounded[53];

      exp_rounded   = exp_norm + (round_carry ? 18'sd1 : 18'sd0);
      normal_overflow = (exp_rounded > C_EXP_MAX64);

      cand_nan.sign     = in.sign;
      cand_nan.exp      = 11'h7ff;
      cand_nan.mantissa = {1'b1, in.mantissa[111 -: 51]};

      cand_inf.sign     = in.sign;
      cand_inf.exp      = 11'h7ff;
      cand_inf.mantissa = '0;

      cand_zero.sign     = in.sign;
      cand_zero.exp      = '0;
      cand_zero.mantissa = '0;

      cand_finite.sign     = in.sign;
      cand_finite.exp      = '0;
      cand_finite.mantissa = '0;

      if (finite_overflow) begin
        cand_finite.exp      = 11'h7ff;
        cand_finite.mantissa = '0;
      end
      else if (finite_subnormal) begin
        if (rounded[53] || rounded[52]) begin
          cand_finite.exp      = 11'd1;
          cand_finite.mantissa = '0;
        end
        else begin
          cand_finite.exp      = '0;
          cand_finite.mantissa = rounded[51:0];
        end
      end
      else begin
        if (normal_overflow) begin
          cand_finite.exp      = 11'h7ff;
          cand_finite.mantissa = '0;
        end
        else begin
          cand_finite.exp = exp64_bits_t'(exp_rounded + C_BIAS64);
          if (round_carry) begin
            cand_finite.mantissa = rounded[52:1];
          end
          else begin
            cand_finite.mantissa = rounded[51:0];
          end
        end
      end

      unique case (1'b1)
        is_nan:  out = cand_nan;
        is_inf:  out = cand_inf;
        is_zero: out = cand_zero;
        default: out = cand_finite;
      endcase

      binary128_to_binary64_rne = out;
    end
  endfunction

  function automatic binary32_t binary128_to_binary32_rne(input logic [127:0] in_bits);
    localparam logic signed [17:0] C_BIAS128     = 18'sd16383;
    localparam logic signed [17:0] C_SUB_EXP128  = -18'sd16382;
    localparam logic signed [17:0] C_BIAS32      = 18'sd127;
    localparam logic signed [17:0] C_EXP_MAX32   = 18'sd127;
    localparam logic signed [17:0] C_EXP_MIN32   = -18'sd126;
    localparam logic signed [17:0] C_SHIFT_ALL32 = 18'sd26; // M_BITS + 3
    typedef logic [7:0] exp32_bits_t;

    binary128_t in;
    binary32_t out;
    binary32_t cand_nan;
    binary32_t cand_inf;
    binary32_t cand_zero;
    binary32_t cand_finite;

    logic is_exp_all_ones;
    logic is_exp_zero;
    logic is_frac_zero;
    logic is_nan;
    logic is_inf;
    logic is_zero;
    logic is_sub;

    logic [112:0] sig_full;
    logic [6:0]   lz;
    logic [112:0] sig_norm;
    logic [112:0] sig_aligned;

    logic signed [17:0] exp_unbiased;
    logic signed [17:0] exp_norm;
    logic signed [17:0] shift_sub_s;
    logic signed [17:0] exp_rounded;

    logic finite_overflow;
    logic finite_subnormal;
    logic [6:0] shift_sub_amt;
    logic shift_sub_large;
    logic normal_overflow;

    logic [23:0] keep;
    logic G;
    logic R;
    logic S;
    logic round_inc;
    logic [24:0] rounded;
    logic round_carry;
    begin
      in = binary128_t'(in_bits);

      is_exp_all_ones = &in.exp;
      is_exp_zero     = ~|in.exp;
      is_frac_zero    = ~|in.mantissa;

      is_nan  = is_exp_all_ones & ~is_frac_zero;
      is_inf  = is_exp_all_ones &  is_frac_zero;
      is_zero = is_exp_zero     &  is_frac_zero;
      is_sub  = is_exp_zero     & ~is_frac_zero;

      sig_full = {~is_exp_zero, in.mantissa};
      lz       = lzc_113(sig_full);
      sig_norm = sig_full << lz;

      exp_unbiased = is_sub ? C_SUB_EXP128 : ($signed({3'b000, in.exp}) - C_BIAS128);
      exp_norm     = exp_unbiased - $signed({11'd0, lz});

      finite_overflow  = (exp_norm > C_EXP_MAX32);
      finite_subnormal = (exp_norm < C_EXP_MIN32);
      shift_sub_s      = C_EXP_MIN32 - exp_norm;
      shift_sub_amt    = shift_sub_s[6:0];
      shift_sub_large  = finite_subnormal && (shift_sub_s >= C_SHIFT_ALL32);

      sig_aligned = sig_norm;
      if (finite_subnormal) begin
        if (shift_sub_large) begin
          sig_aligned = '0;
        end
        else begin
          sig_aligned = sig_norm >> shift_sub_amt;
        end
      end

      keep = '0;
      G    = 1'b0;
      R    = 1'b0;
      S    = 1'b0;
      if (finite_subnormal && shift_sub_large) begin
        S = |sig_norm;
      end
      else begin
        keep = sig_aligned[112 -: 24];
        G    = sig_aligned[88];
        R    = sig_aligned[87];
        S    = |sig_aligned[86:0];
      end

      round_inc   = G && (R || S || keep[0]);
      rounded     = {1'b0, keep} + {{24{1'b0}}, round_inc};
      round_carry = rounded[24];

      exp_rounded   = exp_norm + (round_carry ? 18'sd1 : 18'sd0);
      normal_overflow = (exp_rounded > C_EXP_MAX32);

      cand_nan.sign     = in.sign;
      cand_nan.exp      = 8'hff;
      cand_nan.mantissa = {1'b1, in.mantissa[111 -: 22]};

      cand_inf.sign     = in.sign;
      cand_inf.exp      = 8'hff;
      cand_inf.mantissa = '0;

      cand_zero.sign     = in.sign;
      cand_zero.exp      = '0;
      cand_zero.mantissa = '0;

      cand_finite.sign     = in.sign;
      cand_finite.exp      = '0;
      cand_finite.mantissa = '0;

      if (finite_overflow) begin
        cand_finite.exp      = 8'hff;
        cand_finite.mantissa = '0;
      end
      else if (finite_subnormal) begin
        if (rounded[24] || rounded[23]) begin
          cand_finite.exp      = 8'd1;
          cand_finite.mantissa = '0;
        end
        else begin
          cand_finite.exp      = '0;
          cand_finite.mantissa = rounded[22:0];
        end
      end
      else begin
        if (normal_overflow) begin
          cand_finite.exp      = 8'hff;
          cand_finite.mantissa = '0;
        end
        else begin
          cand_finite.exp = exp32_bits_t'(exp_rounded + C_BIAS32);
          if (round_carry) begin
            cand_finite.mantissa = rounded[23:1];
          end
          else begin
            cand_finite.mantissa = rounded[22:0];
          end
        end
      end

      unique case (1'b1)
        is_nan:  out = cand_nan;
        is_inf:  out = cand_inf;
        is_zero: out = cand_zero;
        default: out = cand_finite;
      endcase

      binary128_to_binary32_rne = out;
    end
  endfunction

endpackage : binary128_convert_pkg
