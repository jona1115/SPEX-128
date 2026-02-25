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

  // Part-1 payload for binary128 -> binary64 conversion.
  // This stage classifies and normalizes, but does not shift/round yet.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [50:0]        nan_payload;
    logic signed [15:0] exp_norm;
    logic [112:0]       sig_norm;
    logic [6:0]         shift_sub;
  } binary128_to_binary64_rne_p1_t;

  // Part-2 payload for binary128 -> binary64 conversion.
  // This stage does shift + GRS extraction + rounding add.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [50:0]        nan_payload;
    logic signed [15:0] exp_norm;
    logic [53:0]        rounded;
  } binary128_to_binary64_rne_p2_t;

  // Part-1 payload for binary128 -> binary32 conversion.
  // This stage classifies and normalizes, but does not shift/round yet.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [21:0]        nan_payload;
    logic signed [15:0] exp_norm;
    logic [112:0]       sig_norm;
    logic [6:0]         shift_sub;
  } binary128_to_binary32_rne_p1_t;

  // Part-2 payload for binary128 -> binary32 conversion.
  // This stage does shift + GRS extraction + rounding add.
  typedef struct packed {
    logic               sign;
    logic               is_nan;
    logic               is_inf;
    logic               is_zero;
    logic               is_overflow;
    logic               is_subnormal;
    logic [21:0]        nan_payload;
    logic signed [15:0] exp_norm;
    logic [24:0]        rounded;
  } binary128_to_binary32_rne_p2_t;

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

  function automatic binary128_to_binary64_rne_p1_t binary128_to_binary64_rne_part1(
    input logic [127:0] in_bits
  );
    localparam int E_MAX_64 = 1023;
    localparam int E_MIN_64 = -1022;
    binary128_to_binary64_rne_p1_t out;
    binary128_t in;
    logic [112:0] full_sig;
    logic [112:0] sig_norm;
    int unsigned lz;
    int signed exp_unbiased;
    int signed exp_norm;
    int signed shift_sub_signed;
    int unsigned shift_sub;

    // Step 0: Initialize and unpack.
    out = '0;
    in = binary128_t'(in_bits);
    out.sign = in.sign;

    // Step 1: Classify specials (NaN/Inf) and preserve NaN payload style.
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

    // Step 2: Classify signed zero.
    if (in.exp == 15'd0 && in.mantissa == '0) begin
      out.is_zero = 1'b1;
      return out;
    end

    // Step 3: Build unbiased exponent and 113-bit significand.
    // For subnormal binary128, hidden bit is 0; otherwise hidden bit is 1.
    exp_unbiased = (in.exp == 15'd0) ? (1 - BIAS_128) : ($signed({1'b0, in.exp}) - BIAS_128);
    full_sig = {(in.exp == 15'd0) ? 1'b0 : 1'b1, in.mantissa};

    // Step 4: Normalize significand and apply normalization shift to exponent.
    lz = lzc_113(full_sig);
    sig_norm = full_sig << lz;
    out.sig_norm = sig_norm;
    exp_norm = exp_unbiased - $signed(lz);
    out.exp_norm = exp_norm[15:0];

    // Step 5: Early overflow check against binary64 max normal exponent.
    if (exp_norm > E_MAX_64) begin
      out.is_overflow = 1'b1;
      return out;
    end

    // Step 6: Determine if final result is subnormal in binary64.
    // If subnormal, pre-shift right so part2 can directly round/pack.
    out.is_subnormal = (exp_norm < E_MIN_64);
    if (out.is_subnormal) begin
      shift_sub_signed = E_MIN_64 - exp_norm;
      shift_sub = (shift_sub_signed > 113) ? 113 : shift_sub_signed;
    end
    else begin
      shift_sub = 0;
    end
    out.shift_sub = shift_sub[6:0];

    return out;
  endfunction

  function automatic binary128_to_binary64_rne_p2_t binary128_to_binary64_rne_part2(
    input binary128_to_binary64_rne_p1_t in
  );
    binary128_to_binary64_rne_p2_t out;
    logic [112:0] sig_shifted;
    logic [52:0] keep;
    logic guard;
    logic round;
    logic sticky;
    logic round_inc;

    // Step 0: Initialize output with passthrough payload.
    out = '0;
    out.sign = in.sign;
    out.is_nan = in.is_nan;
    out.is_inf = in.is_inf;
    out.is_zero = in.is_zero;
    out.is_overflow = in.is_overflow;
    out.is_subnormal = in.is_subnormal;
    out.nan_payload = in.nan_payload;
    out.exp_norm = in.exp_norm;

    // Step 1: Specials/zero/overflow do not need shift+round.
    if (in.is_nan || in.is_inf || in.is_overflow || in.is_zero) begin
      return out;
    end

    // Step 2: Shift to subnormal boundary if needed and extract G/R/S bits.
    sig_shifted = in.sig_norm >> in.shift_sub;
    keep = sig_shifted[112 -: 53];
    guard = sig_shifted[112-53];
    round = sig_shifted[112-54];
    sticky = |sig_shifted[112-55:0];

    // Step 3: RNE increment and adder.
    round_inc = guard && (round || sticky || keep[0]);
    out.rounded = {1'b0, keep} + round_inc;

    return out;
  endfunction

  function automatic binary64_t binary128_to_binary64_rne_part3(
    input binary128_to_binary64_rne_p2_t in
  );
    localparam int E_MAX_64 = 1023;
    binary64_t out;
    int signed exp_out;

    // Step 0: Initialize output with sign propagated from part2.
    out = '0;
    out.sign = in.sign;

    // Step 1: Handle specials first (NaN, Inf, overflow-to-Inf, zero).
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

    // Step 2: Normal path pack (with post-round carry into exponent).
    if (!in.is_subnormal) begin
      exp_out = in.exp_norm + (in.rounded[53] ? 1 : 0);
      if (exp_out > E_MAX_64) begin
        out.exp = 11'h7ff;
        out.mantissa = '0;
      end
      else begin
        out.exp = exp_out + BIAS_64;
        if (in.rounded[53]) begin
          out.mantissa = in.rounded[52:1];
        end
        else begin
          out.mantissa = in.rounded[51:0];
        end
      end
    end

    // Step 3: Subnormal path pack (including subnormal-to-normal bump).
    else begin
      if (in.rounded[53] || in.rounded[52]) begin
        out.exp = 11'd1;
        out.mantissa = '0;
      end
      else begin
        out.exp = '0;
        out.mantissa = in.rounded[51:0];
      end
    end

    return out;
  endfunction

  function automatic binary128_to_binary32_rne_p1_t binary128_to_binary32_rne_part1(
    input logic [127:0] in_bits
  );
    localparam int E_MAX_32 = 127;
    localparam int E_MIN_32 = -126;
    binary128_to_binary32_rne_p1_t out;
    binary128_t in;
    logic [112:0] full_sig;
    logic [112:0] sig_norm;
    int unsigned lz;
    int signed exp_unbiased;
    int signed exp_norm;
    int signed shift_sub_signed;
    int unsigned shift_sub;

    // Step 0: Initialize and unpack.
    out = '0;
    in = binary128_t'(in_bits);
    out.sign = in.sign;

    // Step 1: Classify specials (NaN/Inf) and preserve NaN payload style.
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

    // Step 2: Classify signed zero.
    if (in.exp == 15'd0 && in.mantissa == '0) begin
      out.is_zero = 1'b1;
      return out;
    end

    // Step 3: Build unbiased exponent and 113-bit significand.
    exp_unbiased = (in.exp == 15'd0) ? (1 - BIAS_128) : ($signed({1'b0, in.exp}) - BIAS_128);
    full_sig = {(in.exp == 15'd0) ? 1'b0 : 1'b1, in.mantissa};

    // Step 4: Normalize significand and apply normalization shift to exponent.
    lz = lzc_113(full_sig);
    sig_norm = full_sig << lz;
    out.sig_norm = sig_norm;
    exp_norm = exp_unbiased - $signed(lz);
    out.exp_norm = exp_norm[15:0];

    // Step 5: Early overflow check against binary32 max normal exponent.
    if (exp_norm > E_MAX_32) begin
      out.is_overflow = 1'b1;
      return out;
    end

    // Step 6: Determine if final result is subnormal in binary32.
    // If subnormal, pre-shift right so part2 can directly round/pack.
    out.is_subnormal = (exp_norm < E_MIN_32);
    if (out.is_subnormal) begin
      shift_sub_signed = E_MIN_32 - exp_norm;
      shift_sub = (shift_sub_signed > 113) ? 113 : shift_sub_signed;
    end
    else begin
      shift_sub = 0;
    end
    out.shift_sub = shift_sub[6:0];

    return out;
  endfunction

  function automatic binary128_to_binary32_rne_p2_t binary128_to_binary32_rne_part2(
    input binary128_to_binary32_rne_p1_t in
  );
    binary128_to_binary32_rne_p2_t out;
    logic [112:0] sig_shifted;
    logic [23:0] keep;
    logic guard;
    logic round;
    logic sticky;
    logic round_inc;

    // Step 0: Initialize output with passthrough payload.
    out = '0;
    out.sign = in.sign;
    out.is_nan = in.is_nan;
    out.is_inf = in.is_inf;
    out.is_zero = in.is_zero;
    out.is_overflow = in.is_overflow;
    out.is_subnormal = in.is_subnormal;
    out.nan_payload = in.nan_payload;
    out.exp_norm = in.exp_norm;

    // Step 1: Specials/zero/overflow do not need shift+round.
    if (in.is_nan || in.is_inf || in.is_overflow || in.is_zero) begin
      return out;
    end

    // Step 2: Shift to subnormal boundary if needed and extract G/R/S bits.
    sig_shifted = in.sig_norm >> in.shift_sub;
    keep = sig_shifted[112 -: 24];
    guard = sig_shifted[112-24];
    round = sig_shifted[112-25];
    sticky = |sig_shifted[112-26:0];

    // Step 3: RNE increment and adder.
    round_inc = guard && (round || sticky || keep[0]);
    out.rounded = {1'b0, keep} + round_inc;

    return out;
  endfunction

  function automatic binary32_t binary128_to_binary32_rne_part3(
    input binary128_to_binary32_rne_p2_t in
  );
    localparam int E_MAX_32 = 127;
    binary32_t out;
    int signed exp_out;

    // Step 0: Initialize output with sign propagated from part2.
    out = '0;
    out.sign = in.sign;

    // Step 1: Handle specials first (NaN, Inf, overflow-to-Inf, zero).
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

    // Step 2: Normal path pack (with post-round carry into exponent).
    if (!in.is_subnormal) begin
      exp_out = in.exp_norm + (in.rounded[24] ? 1 : 0);
      if (exp_out > E_MAX_32) begin
        out.exp = 8'hff;
        out.mantissa = '0;
      end
      else begin
        out.exp = exp_out + BIAS_32;
        if (in.rounded[24]) begin
          out.mantissa = in.rounded[23:1];
        end
        else begin
          out.mantissa = in.rounded[22:0];
        end
      end
    end
    
    // Step 3: Subnormal path pack (including subnormal-to-normal bump).
    else begin
      if (in.rounded[24] || in.rounded[23]) begin
        out.exp = 8'd1;
        out.mantissa = '0;
      end
      else begin
        out.exp = '0;
        out.mantissa = in.rounded[22:0];
      end
    end

    return out;
  endfunction

  function automatic binary64_t binary128_to_binary64_rne(input logic [127:0] in_bits);
    // Backward-compatible 1-call wrapper: part1 then part2 then part3.
    return binary128_to_binary64_rne_part3(
      binary128_to_binary64_rne_part2(
        binary128_to_binary64_rne_part1(in_bits)
      )
    );
  endfunction

  function automatic binary32_t binary128_to_binary32_rne(input logic [127:0] in_bits);
    // Backward-compatible 1-call wrapper: part1 then part2 then part3.
    return binary128_to_binary32_rne_part3(
      binary128_to_binary32_rne_part2(
        binary128_to_binary32_rne_part1(in_bits)
      )
    );
  endfunction

endpackage : binary128_convert_pkg
