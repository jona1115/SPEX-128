/********************************************************************
 * 
 * Originator   : Jonathan Tan feat. ChatGPT 5.2 Codex
 * Date         : 01/11/2026
 * 
 ********************************************************************
 * 
 * Description:
 * Helpers to convert IEEE-754 binary128 to binary64/binary32 with
 * round-to-nearest, ties-to-even (G/R/S bits).
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  01/11/2026  |  Birth of this file
 * 
 *******************************************************************/

package binary128_convert_pkg;

  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;

  localparam int BIAS_128 = 16383;
  localparam int BIAS_64  = 1023;
  localparam int BIAS_32  = 127;

  function automatic int unsigned lzc_113(input logic [112:0] in);
    int unsigned count;
    bit found;
    count = 0;
    found = 1'b0;
    for (int i = 112; i >= 0; i--) begin
      if (!found) begin
        if (in[i]) begin
          found = 1'b1;
        end
        else begin
          count++;
        end
      end
    end
    return count;
  endfunction

  function automatic binary64_t binary128_to_binary64_rne(input logic [127:0] in_bits);
    localparam int E_MAX_64 = 1023;
    localparam int E_MIN_64 = -1022;
    binary64_t out;
    binary128_t in;
    logic [112:0] full_sig;
    logic [112:0] sig_norm;
    logic [112:0] sig_shifted;
    logic [52:0] keep;
    logic G;
    logic R;
    logic S;
    logic round_inc;
    logic [53:0] rounded;
    int unsigned lz;
    int signed exp_unbiased;
    int signed exp_norm;
    int signed exp_out;
    int unsigned shift_sub;

    out = '0;
    in = binary128_t'(in_bits);

    if (in.exp == 15'h7fff) begin
      out.sign = in.sign;
      out.exp = 11'h7ff;
      if (in.mantissa == '0) begin
        out.mantissa = '0;
      end
      else begin
        out.mantissa = {1'b1, in.mantissa[111 -: 51]};
      end
      return out;
    end

    if (in.exp == 15'd0 && in.mantissa == '0) begin
      out.sign = in.sign;
      out.exp = '0;
      out.mantissa = '0;
      return out;
    end

    exp_unbiased = (in.exp == 15'd0) ? (1 - BIAS_128) : ($signed({1'b0, in.exp}) - BIAS_128);
    full_sig = {(in.exp == 15'd0) ? 1'b0 : 1'b1, in.mantissa};
    lz = lzc_113(full_sig);
    sig_norm = full_sig << lz;
    exp_norm = exp_unbiased - $signed(lz);

    if (exp_norm > E_MAX_64) begin
      out.sign = in.sign;
      out.exp = 11'h7ff;
      out.mantissa = '0;
      return out;
    end

    shift_sub = (exp_norm < E_MIN_64) ? (E_MIN_64 - exp_norm) : 0;
    sig_shifted = sig_norm >> shift_sub;

    keep = sig_shifted[112 -: 53];
    G = sig_shifted[112-53];
    R = sig_shifted[112-54];
    S = |sig_shifted[112-55:0];
    round_inc = G && (R || S || keep[0]);
    rounded = {1'b0, keep} + round_inc;

    out.sign = in.sign;
    if (shift_sub == 0) begin
      exp_out = exp_norm + (rounded[53] ? 1 : 0);
      if (exp_out > E_MAX_64) begin
        out.exp = 11'h7ff;
        out.mantissa = '0;
      end
      else begin
        out.exp = exp_out + BIAS_64;
        if (rounded[53]) begin
          out.mantissa = rounded[52:1];
        end
        else begin
          out.mantissa = rounded[51:0];
        end
      end
    end
    else begin
      if (rounded[53] || rounded[52]) begin
        out.exp = 11'd1;
        out.mantissa = '0;
      end
      else begin
        out.exp = '0;
        out.mantissa = rounded[51:0];
      end
    end

    return out;
  endfunction

  function automatic binary32_t binary128_to_binary32_rne(input logic [127:0] in_bits);
    localparam int E_MAX_32 = 127;
    localparam int E_MIN_32 = -126;
    binary32_t out;
    binary128_t in;
    logic [112:0] full_sig;
    logic [112:0] sig_norm;
    logic [112:0] sig_shifted;
    logic [23:0] keep;
    logic G;
    logic R;
    logic S;
    logic round_inc;
    logic [24:0] rounded;
    int unsigned lz;
    int signed exp_unbiased;
    int signed exp_norm;
    int signed exp_out;
    int unsigned shift_sub;

    out = '0;
    in = binary128_t'(in_bits);

    if (in.exp == 15'h7fff) begin
      out.sign = in.sign;
      out.exp = 8'hff;
      if (in.mantissa == '0) begin
        out.mantissa = '0;
      end
      else begin
        out.mantissa = {1'b1, in.mantissa[111 -: 22]};
      end
      return out;
    end

    if (in.exp == 15'd0 && in.mantissa == '0) begin
      out.sign = in.sign;
      out.exp = '0;
      out.mantissa = '0;
      return out;
    end

    exp_unbiased = (in.exp == 15'd0) ? (1 - BIAS_128) : ($signed({1'b0, in.exp}) - BIAS_128);
    full_sig = {(in.exp == 15'd0) ? 1'b0 : 1'b1, in.mantissa};
    lz = lzc_113(full_sig);
    sig_norm = full_sig << lz;
    exp_norm = exp_unbiased - $signed(lz);

    if (exp_norm > E_MAX_32) begin
      out.sign = in.sign;
      out.exp = 8'hff;
      out.mantissa = '0;
      return out;
    end

    shift_sub = (exp_norm < E_MIN_32) ? (E_MIN_32 - exp_norm) : 0;
    sig_shifted = sig_norm >> shift_sub;

    keep = sig_shifted[112 -: 24];
    G = sig_shifted[112-24];
    R = sig_shifted[112-25];
    S = |sig_shifted[112-26:0];
    round_inc = G && (R || S || keep[0]);
    rounded = {1'b0, keep} + round_inc;

    out.sign = in.sign;
    if (shift_sub == 0) begin
      exp_out = exp_norm + (rounded[24] ? 1 : 0);
      if (exp_out > E_MAX_32) begin
        out.exp = 8'hff;
        out.mantissa = '0;
      end
      else begin
        out.exp = exp_out + BIAS_32;
        if (rounded[24]) begin
          out.mantissa = rounded[23:1];
        end
        else begin
          out.mantissa = rounded[22:0];
        end
      end
    end
    else begin
      if (rounded[24] || rounded[23]) begin
        out.exp = 8'd1;
        out.mantissa = '0;
      end
      else begin
        out.exp = '0;
        out.mantissa = rounded[22:0];
      end
    end

    return out;
  endfunction

endpackage : binary128_convert_pkg
