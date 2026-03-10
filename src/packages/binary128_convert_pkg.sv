/********************************************************************
 * 
 * Originator   : Jonathan Tan with some help from Codex 5.2/5.3
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
 *       1.01  |  Jonathan  |  03/07/2026  |  Made it 4 stage pipeline (was 3)
 *       1.02  |  Jonathan  |  03/09/2026  |  Made it 6 stage pipeline (split s0/s1)
 * 
 *******************************************************************/

package binary128_convert_pkg;

  import binary128_pkg::*;
  import binary64_pkg::*;
  import binary32_pkg::*;

  const int CONVERSION_LATENCY = 6; // Must be the same as fixed_partition_sp.CONVERSION_LATENCY

  localparam logic signed [17:0] BIAS_128 = 18'sd16383;
  localparam logic signed [17:0] BIAS_64  = 18'sd1023;
  localparam logic signed [17:0] BIAS_32  = 18'sd127;

  // Stage-0a payload for binary128 -> binary64 conversion.
  // This stage unpacks and classifies.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic [51:0]        nan_payload;
    logic [14:0]        exp;
    logic [111:0]       mantissa;
  } binary128_to_binary64_rne_s0a_t;

  // Stage-0 payload for binary128 -> binary64 conversion.
  // This stage computes exp_unbiased/full_sig from stage-0a payload.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic [51:0]        nan_payload;
    logic [112:0]       full_sig;
    logic signed [17:0] exp_unbiased;
  } binary128_to_binary64_rne_s0_t;

  // Stage-1a payload for binary128 -> binary64 conversion.
  // This stage does LZC + exponent normalization + overflow classification.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic [51:0]        nan_payload;

    logic [112:0]       full_sig;
    logic signed [17:0] exp_unbiased;
    logic [6:0]         lz;
    logic signed [17:0] exp_norm;
  } binary128_to_binary64_rne_s1a_t;

  // Stage-1 payload for binary128 -> binary64 conversion.
  // This stage does subnormal bookkeeping.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [51:0]        nan_payload;

    logic [112:0]       full_sig;
    logic [6:0]         lz;
    logic signed [17:0] exp_norm;
    logic [6:0]         shift_sub;
    logic [6:0]         sub_rshift_amt;
  } binary128_to_binary64_rne_s1_t;

  // Stage-2 payload for binary128 -> binary64 conversion.
  // This stage performs one shift and computes round increment.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [51:0]        nan_payload;
    logic signed [17:0] exp_norm;

    logic [52:0]        keep;
    logic               round_inc;
  } binary128_to_binary64_rne_s2_t;

  // Stage-0a payload for binary128 -> binary32 conversion.
  // This stage unpacks and classifies.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic [22:0]        nan_payload;
    logic [14:0]        exp;
    logic [111:0]       mantissa;
  } binary128_to_binary32_rne_s0a_t;

  // Stage-0 payload for binary128 -> binary32 conversion.
  // This stage computes exp_unbiased/full_sig from stage-0a payload.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic [22:0]        nan_payload;
    logic [112:0]       full_sig;
    logic signed [17:0] exp_unbiased;
  } binary128_to_binary32_rne_s0_t;

  // Stage-1a payload for binary128 -> binary32 conversion.
  // This stage does LZC + exponent normalization + overflow classification.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic [22:0]        nan_payload;

    logic [112:0]       full_sig;
    logic signed [17:0] exp_unbiased;
    logic [6:0]         lz;
    logic signed [17:0] exp_norm;
  } binary128_to_binary32_rne_s1a_t;

  // Stage-1 payload for binary128 -> binary32 conversion.
  // This stage does subnormal bookkeeping.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [22:0]        nan_payload;

    logic [112:0]       full_sig;
    logic [6:0]         lz;
    logic signed [17:0] exp_norm;
    logic [6:0]         shift_sub;
    logic [6:0]         sub_rshift_amt;
  } binary128_to_binary32_rne_s1_t;

  // Stage-2 payload for binary128 -> binary32 conversion.
  // This stage performs one shift and computes round increment.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [22:0]        nan_payload;
    logic signed [17:0] exp_norm;

    logic [23:0]        keep;
    logic               round_inc;
  } binary128_to_binary32_rne_s2_t;

  // Leading-zero count in one byte (MSB-first).
  function automatic int unsigned lzc_8(input logic [7:0] in);
    casez (in)
      8'b1???????: return 0;
      8'b01??????: return 1;
      8'b001?????: return 2;
      8'b0001????: return 3;
      8'b00001???: return 4;
      8'b000001??: return 5;
      8'b0000001?: return 6;
      8'b00000001: return 7;
      default:     return 8;
    endcase
  endfunction

  // Leading-zero count for a 113-bit significand.
  // Implemented as a byte-group search to avoid a long linear priority chain.
  function automatic int unsigned lzc_113(input logic [112:0] in);
    logic [127:0] padded;
    logic [15:0] group_nonzero;
    logic [7:0] selected_byte;
    int unsigned byte_idx;
    int unsigned lz_total;

    // 1) Left-align into 128 bits so we can scan in 8-bit chunks.
    padded = {in, 15'b0};
    // 2) Mark which byte groups are non-zero.
    for (int i = 0; i < 16; i++) begin
      group_nonzero[15-i] = |padded[(127 - (i*8)) -: 8];
    end

    // 3) All-zero input maps to full-length LZC.
    if (group_nonzero == '0) begin
      return 113;
    end

    // 4) Find first non-zero byte from MSB side.
    casez (group_nonzero)
      16'b1???????????????: byte_idx = 0;
      16'b01??????????????: byte_idx = 1;
      16'b001?????????????: byte_idx = 2;
      16'b0001????????????: byte_idx = 3;
      16'b00001???????????: byte_idx = 4;
      16'b000001??????????: byte_idx = 5;
      16'b0000001?????????: byte_idx = 6;
      16'b00000001????????: byte_idx = 7;
      16'b000000001???????: byte_idx = 8;
      16'b0000000001??????: byte_idx = 9;
      16'b00000000001?????: byte_idx = 10;
      16'b000000000001????: byte_idx = 11;
      16'b0000000000001???: byte_idx = 12;
      16'b00000000000001??: byte_idx = 13;
      16'b000000000000001?: byte_idx = 14;
      default:             byte_idx = 15;
    endcase

    // 5) Select that byte and run the local 8-bit LZC.
    case (byte_idx)
      0: selected_byte = padded[127:120];
      1: selected_byte = padded[119:112];
      2: selected_byte = padded[111:104];
      3: selected_byte = padded[103:96];
      4: selected_byte = padded[95:88];
      5: selected_byte = padded[87:80];
      6: selected_byte = padded[79:72];
      7: selected_byte = padded[71:64];
      8: selected_byte = padded[63:56];
      9: selected_byte = padded[55:48];
      10: selected_byte = padded[47:40];
      11: selected_byte = padded[39:32];
      12: selected_byte = padded[31:24];
      13: selected_byte = padded[23:16];
      14: selected_byte = padded[15:8];
      default: selected_byte = padded[7:0];
    endcase

    // 6) Combine byte offset + intra-byte offset.
    lz_total = (byte_idx << 3) + lzc_8(selected_byte);
    // Clamp to 113 because padded lower bits are artificial.
    if (lz_total > 113) begin
      return 113;
    end
    return lz_total;
  endfunction

  function automatic binary128_to_binary64_rne_s0a_t binary128_to_binary64_rne_s0a(
    input logic [127:0] in_bits
  );
    binary128_to_binary64_rne_s0a_t out;
    binary128_t in;

    out = '0;
    in  = binary128_t'(in_bits);

    out.sign = in.sign;
    out.exp = in.exp;
    out.mantissa = in.mantissa;

    // NaN/Inf
    if (in.exp == 15'h7fff) begin
      if (in.mantissa == '0) begin
        out.is_inf = 1'b1;
      end
      else begin
        out.is_nan = 1'b1;
        out.nan_payload = {1'b1, in.mantissa[111 -: 51]};
      end
      return out;
    end

    // Signed zero
    if (in.exp == 15'd0 && in.mantissa == '0) begin
      out.is_zero = 1'b1;
      return out;
    end

    return out;
  endfunction

  function automatic binary128_to_binary64_rne_s0_t binary128_to_binary64_rne_s0b(
    input binary128_to_binary64_rne_s0a_t in
  );
    binary128_to_binary64_rne_s0_t out;

    out = '0;

    out.sign = in.sign;
    out.is_nan = in.is_nan;
    out.is_inf = in.is_inf;
    out.is_zero = in.is_zero;
    out.nan_payload = in.nan_payload;

    if (in.is_nan || in.is_inf || in.is_zero) begin
      return out;
    end

    out.exp_unbiased = (in.exp == 15'd0) ? (18'sd1 - BIAS_128)
                                          : ($signed({3'b0, in.exp}) - BIAS_128);
    out.full_sig = {(in.exp == 15'd0) ? 1'b0 : 1'b1, in.mantissa};

    return out;
  endfunction

  // Compatibility wrapper for legacy 4-stage call sites.
  function automatic binary128_to_binary64_rne_s0_t binary128_to_binary64_rne_s0(
    input logic [127:0] in_bits
  );
    return binary128_to_binary64_rne_s0b(binary128_to_binary64_rne_s0a(in_bits));
  endfunction

  function automatic binary128_to_binary64_rne_s1a_t binary128_to_binary64_rne_s1a(
    input binary128_to_binary64_rne_s0_t in
  );
    localparam logic signed [17:0] E_MAX_64_S = 18'sd1023;

    binary128_to_binary64_rne_s1a_t out;
    int unsigned lz_u;
    logic signed [17:0] exp_norm_s;

    out = '0;

    // passthrough flags
    out.sign         = in.sign;
    out.is_nan       = in.is_nan;
    out.is_inf       = in.is_inf;
    out.is_zero      = in.is_zero;
    out.nan_payload  = in.nan_payload;
    out.full_sig     = in.full_sig;
    out.exp_unbiased = in.exp_unbiased;

    // Specials/zero: bypass heavy math
    if (in.is_nan || in.is_inf || in.is_zero) begin
      return out;
    end

    // LZC on 113-bit significand
    lz_u = lzc_113(in.full_sig);
    if (lz_u > 113) begin
      out.lz = 7'd113;
    end
    else begin
      out.lz = lz_u[6:0];
    end

    exp_norm_s = in.exp_unbiased - $signed({11'b0, out.lz});
    out.exp_norm = exp_norm_s;

    // Early overflow
    if (exp_norm_s > E_MAX_64_S) begin
      out.is_overflow = 1'b1;
      return out;
    end

    return out;
  endfunction

  function automatic binary128_to_binary64_rne_s1_t binary128_to_binary64_rne_s1b(
    input binary128_to_binary64_rne_s1a_t in
  );
    localparam int signed E_MIN_64 = -1022;
    localparam logic signed [17:0] E_MIN_64_S = -18'sd1022;

    binary128_to_binary64_rne_s1_t out;
    int signed shift_sub_signed;
    int signed sub_rshift_signed;

    out = '0;

    out.sign         = in.sign;
    out.is_nan       = in.is_nan;
    out.is_inf       = in.is_inf;
    out.is_zero      = in.is_zero;
    out.is_overflow  = in.is_overflow;
    out.nan_payload  = in.nan_payload;
    out.full_sig     = in.full_sig;
    out.lz           = in.lz;
    out.exp_norm     = in.exp_norm;

    if (in.is_nan || in.is_inf || in.is_zero || in.is_overflow) begin
      return out;
    end

    // Subnormal classification (binary64)
    out.is_subnormal = (in.exp_norm < E_MIN_64_S);

    // shift_sub (kept for parity with old flow)
    if (out.is_subnormal) begin
      shift_sub_signed = E_MIN_64 - int'(in.exp_norm);
      if (shift_sub_signed > 113) begin
        out.shift_sub = 7'd113;
      end
      else begin
        out.shift_sub = shift_sub_signed[6:0];
      end
    end
    else begin
      out.shift_sub = 7'd0;
    end

    // For subnormals, avoid double-barrel shift:
    // sig_shifted = full_sig >> (E_MIN - exp_unbiased)
    if (out.is_subnormal) begin
      sub_rshift_signed = E_MIN_64 - int'(in.exp_unbiased);
      if (sub_rshift_signed < 0) begin
        out.sub_rshift_amt = 7'd0;
      end
      else if (sub_rshift_signed > 113) begin
        out.sub_rshift_amt = 7'd113;
      end
      else begin
        out.sub_rshift_amt = sub_rshift_signed[6:0];
      end
    end
    else begin
      out.sub_rshift_amt = 7'd0;
    end

    return out;
  endfunction

  // Compatibility wrapper for legacy 4-stage call sites.
  function automatic binary128_to_binary64_rne_s1_t binary128_to_binary64_rne_s1(
    input binary128_to_binary64_rne_s0_t in
  );
    return binary128_to_binary64_rne_s1b(binary128_to_binary64_rne_s1a(in));
  endfunction

  function automatic binary128_to_binary64_rne_s2_t binary128_to_binary64_rne_s2(
    input binary128_to_binary64_rne_s1_t in
  );
    binary128_to_binary64_rne_s2_t out;
    logic [112:0] sig_shifted;
    logic guard;
    logic round;
    logic sticky;

    out = '0;

    out.sign         = in.sign;
    out.is_nan       = in.is_nan;
    out.is_inf       = in.is_inf;
    out.is_zero      = in.is_zero;
    out.is_overflow  = in.is_overflow;
    out.is_subnormal = in.is_subnormal;
    out.nan_payload  = in.nan_payload;
    out.exp_norm     = in.exp_norm;

    if (in.is_nan || in.is_inf || in.is_zero || in.is_overflow) begin
      return out;
    end

    if (in.is_subnormal) begin
      sig_shifted = in.full_sig >> in.sub_rshift_amt;
    end
    else begin
      sig_shifted = in.full_sig << in.lz;
    end

    out.keep = sig_shifted[112 -: 53];
    guard = sig_shifted[112-53];
    round = sig_shifted[112-54];
    sticky = |sig_shifted[112-55:0];

    out.round_inc = guard && (round || sticky || out.keep[0]);

    return out;
  endfunction

  function automatic binary64_t binary128_to_binary64_rne_s3(
    input binary128_to_binary64_rne_s2_t in
  );
    localparam logic signed [17:0] E_MAX_64_S = 18'sd1023;

    binary64_t out;
    logic [53:0] rounded;
    logic carry;
    logic signed [17:0] exp_out_s;
    logic signed [17:0] exp_biased_s;

    out = '0;
    out.sign = in.sign;

    // specials first
    if (in.is_nan) begin
      out.exp = 11'h7ff;
      out.mantissa = in.nan_payload;
      return out;
    end
    if (in.is_inf || in.is_overflow) begin
      out.exp = 11'h7ff;
      out.mantissa = '0;
      return out;
    end
    if (in.is_zero) begin
      out.exp = '0;
      out.mantissa = '0;
      return out;
    end

    // rounding add
    rounded = {1'b0, in.keep} + {{53{1'b0}}, in.round_inc};
    carry = rounded[53];

    // pack
    if (!in.is_subnormal) begin
      exp_out_s = in.exp_norm + $signed({17'b0, carry});

      if (exp_out_s > E_MAX_64_S) begin
        out.exp = 11'h7ff;
        out.mantissa = '0;
      end
      else begin
        exp_biased_s = exp_out_s + BIAS_64;
        out.exp = exp_biased_s[10:0];
        out.mantissa = carry ? rounded[52:1] : rounded[51:0];
      end
    end
    else begin
      // subnormal pack + bump
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

  function automatic binary128_to_binary32_rne_s0a_t binary128_to_binary32_rne_s0a(
    input logic [127:0] in_bits
  );
    binary128_to_binary32_rne_s0a_t out;
    binary128_t in;

    out = '0;
    in  = binary128_t'(in_bits);

    out.sign = in.sign;
    out.exp = in.exp;
    out.mantissa = in.mantissa;

    // NaN/Inf
    if (in.exp == 15'h7fff) begin
      if (in.mantissa == '0) begin
        out.is_inf = 1'b1;
      end
      else begin
        out.is_nan = 1'b1;
        out.nan_payload = {1'b1, in.mantissa[111 -: 22]};
      end
      return out;
    end

    // Signed zero
    if (in.exp == 15'd0 && in.mantissa == '0) begin
      out.is_zero = 1'b1;
      return out;
    end

    return out;
  endfunction

  function automatic binary128_to_binary32_rne_s0_t binary128_to_binary32_rne_s0b(
    input binary128_to_binary32_rne_s0a_t in
  );
    binary128_to_binary32_rne_s0_t out;

    out = '0;

    out.sign = in.sign;
    out.is_nan = in.is_nan;
    out.is_inf = in.is_inf;
    out.is_zero = in.is_zero;
    out.nan_payload = in.nan_payload;

    if (in.is_nan || in.is_inf || in.is_zero) begin
      return out;
    end

    out.exp_unbiased = (in.exp == 15'd0) ? (18'sd1 - BIAS_128)
                                          : ($signed({3'b0, in.exp}) - BIAS_128);
    out.full_sig = {(in.exp == 15'd0) ? 1'b0 : 1'b1, in.mantissa};

    return out;
  endfunction

  // Compatibility wrapper for legacy 4-stage call sites.
  function automatic binary128_to_binary32_rne_s0_t binary128_to_binary32_rne_s0(
    input logic [127:0] in_bits
  );
    return binary128_to_binary32_rne_s0b(binary128_to_binary32_rne_s0a(in_bits));
  endfunction

  function automatic binary128_to_binary32_rne_s1a_t binary128_to_binary32_rne_s1a(
    input binary128_to_binary32_rne_s0_t in
  );
    localparam logic signed [17:0] E_MAX_32_S = 18'sd127;

    binary128_to_binary32_rne_s1a_t out;
    int unsigned lz_u;
    logic signed [17:0] exp_norm_s;

    out = '0;

    // passthrough flags
    out.sign         = in.sign;
    out.is_nan       = in.is_nan;
    out.is_inf       = in.is_inf;
    out.is_zero      = in.is_zero;
    out.nan_payload  = in.nan_payload;
    out.full_sig     = in.full_sig;
    out.exp_unbiased = in.exp_unbiased;

    // Specials/zero: bypass heavy math
    if (in.is_nan || in.is_inf || in.is_zero) begin
      return out;
    end

    // LZC on 113-bit significand
    lz_u = lzc_113(in.full_sig);
    if (lz_u > 113) begin
      out.lz = 7'd113;
    end
    else begin
      out.lz = lz_u[6:0];
    end

    exp_norm_s = in.exp_unbiased - $signed({11'b0, out.lz});
    out.exp_norm = exp_norm_s;

    // Early overflow
    if (exp_norm_s > E_MAX_32_S) begin
      out.is_overflow = 1'b1;
      return out;
    end

    return out;
  endfunction

  function automatic binary128_to_binary32_rne_s1_t binary128_to_binary32_rne_s1b(
    input binary128_to_binary32_rne_s1a_t in
  );
    localparam int signed E_MIN_32 = -126;
    localparam logic signed [17:0] E_MIN_32_S = -18'sd126;

    binary128_to_binary32_rne_s1_t out;
    int signed shift_sub_signed;
    int signed sub_rshift_signed;

    out = '0;

    out.sign         = in.sign;
    out.is_nan       = in.is_nan;
    out.is_inf       = in.is_inf;
    out.is_zero      = in.is_zero;
    out.is_overflow  = in.is_overflow;
    out.nan_payload  = in.nan_payload;
    out.full_sig     = in.full_sig;
    out.lz           = in.lz;
    out.exp_norm     = in.exp_norm;

    if (in.is_nan || in.is_inf || in.is_zero || in.is_overflow) begin
      return out;
    end

    // Subnormal classification (binary32)
    out.is_subnormal = (in.exp_norm < E_MIN_32_S);

    // shift_sub (kept for parity with old flow)
    if (out.is_subnormal) begin
      shift_sub_signed = E_MIN_32 - int'(in.exp_norm);
      if (shift_sub_signed > 113) begin
        out.shift_sub = 7'd113;
      end
      else begin
        out.shift_sub = shift_sub_signed[6:0];
      end
    end
    else begin
      out.shift_sub = 7'd0;
    end

    // For subnormals, avoid double-barrel shift:
    // sig_shifted = full_sig >> (E_MIN - exp_unbiased)
    if (out.is_subnormal) begin
      sub_rshift_signed = E_MIN_32 - int'(in.exp_unbiased);
      if (sub_rshift_signed < 0) begin
        out.sub_rshift_amt = 7'd0;
      end
      else if (sub_rshift_signed > 113) begin
        out.sub_rshift_amt = 7'd113;
      end
      else begin
        out.sub_rshift_amt = sub_rshift_signed[6:0];
      end
    end
    else begin
      out.sub_rshift_amt = 7'd0;
    end

    return out;
  endfunction

  // Compatibility wrapper for legacy 4-stage call sites.
  function automatic binary128_to_binary32_rne_s1_t binary128_to_binary32_rne_s1(
    input binary128_to_binary32_rne_s0_t in
  );
    return binary128_to_binary32_rne_s1b(binary128_to_binary32_rne_s1a(in));
  endfunction

  function automatic binary128_to_binary32_rne_s2_t binary128_to_binary32_rne_s2(
    input binary128_to_binary32_rne_s1_t in
  );
    binary128_to_binary32_rne_s2_t out;
    logic [112:0] sig_shifted;
    logic guard;
    logic round;
    logic sticky;

    out = '0;

    out.sign         = in.sign;
    out.is_nan       = in.is_nan;
    out.is_inf       = in.is_inf;
    out.is_zero      = in.is_zero;
    out.is_overflow  = in.is_overflow;
    out.is_subnormal = in.is_subnormal;
    out.nan_payload  = in.nan_payload;
    out.exp_norm     = in.exp_norm;

    if (in.is_nan || in.is_inf || in.is_zero || in.is_overflow) begin
      return out;
    end

    if (in.is_subnormal) begin
      sig_shifted = in.full_sig >> in.sub_rshift_amt;
    end
    else begin
      sig_shifted = in.full_sig << in.lz;
    end

    out.keep = sig_shifted[112 -: 24];
    guard = sig_shifted[88];
    round = sig_shifted[87];
    sticky = |sig_shifted[86:0];

    out.round_inc = guard && (round || sticky || out.keep[0]);

    return out;
  endfunction

  function automatic binary32_t binary128_to_binary32_rne_s3(
    input binary128_to_binary32_rne_s2_t in
  );
    localparam logic signed [17:0] E_MAX_32_S = 18'sd127;

    binary32_t out;
    logic [24:0] rounded;
    logic carry;
    logic signed [17:0] exp_out_s;
    logic signed [17:0] exp_biased_s;

    out = '0;
    out.sign = in.sign;

    // specials first
    if (in.is_nan) begin
      out.exp = 8'hff;
      out.mantissa = in.nan_payload;
      return out;
    end
    if (in.is_inf || in.is_overflow) begin
      out.exp = 8'hff;
      out.mantissa = '0;
      return out;
    end
    if (in.is_zero) begin
      out.exp = '0;
      out.mantissa = '0;
      return out;
    end

    // rounding add
    rounded = {1'b0, in.keep} + {{24{1'b0}}, in.round_inc};
    carry = rounded[24];

    // pack
    if (!in.is_subnormal) begin
      exp_out_s = in.exp_norm + $signed({17'b0, carry});

      if (exp_out_s > E_MAX_32_S) begin
        out.exp = 8'hff;
        out.mantissa = '0;
      end
      else begin
        exp_biased_s = exp_out_s + BIAS_32;
        out.exp = exp_biased_s[7:0];
        out.mantissa = carry ? rounded[23:1] : rounded[22:0];
      end
    end
    else begin
      // subnormal pack + bump
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

  function automatic binary64_t binary128_to_binary64_rne(input logic [127:0] in_bits);
    return binary128_to_binary64_rne_s3(
             binary128_to_binary64_rne_s2(
               binary128_to_binary64_rne_s1b(
                 binary128_to_binary64_rne_s1a(
                   binary128_to_binary64_rne_s0b(
                     binary128_to_binary64_rne_s0a(in_bits)
                   )
                 )
               )
             )
           );
  endfunction

  // Backward-compatible alias used in some call sites.
  function automatic binary64_t binary128_to_binary64_rne0(input logic [127:0] in_bits);
    return binary128_to_binary64_rne(in_bits);
  endfunction

  function automatic binary32_t binary128_to_binary32_rne(input logic [127:0] in_bits);
    return binary128_to_binary32_rne_s3(
             binary128_to_binary32_rne_s2(
               binary128_to_binary32_rne_s1b(
                 binary128_to_binary32_rne_s1a(
                   binary128_to_binary32_rne_s0b(
                     binary128_to_binary32_rne_s0a(in_bits)
                   )
                 )
               )
             )
           );
  endfunction

endpackage : binary128_convert_pkg
