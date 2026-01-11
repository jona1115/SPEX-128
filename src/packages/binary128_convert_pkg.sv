/********************************************************************
 * 
 * Originator   : ChatGPT 5.2 Codex
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
 *       1.00  |  ChatGPT   |  01/11/2026  |  Birth of this file
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

// Another version:
// package binary128_convert_pkg;

//   import binary128_pkg::*;
//   import binary64_pkg::*;
//   import binary32_pkg::*;

//   // ----------------------------
//   // Constants (IEEE-754)
//   // ----------------------------
//   localparam int BIAS128 = 16383;
//   localparam int BIAS64  = 1023;
//   localparam int BIAS32  = 127;

//   localparam int EXP128_MAX = (1<<15) - 1; // 0x7fff
//   localparam int EXP64_MAX  = (1<<11) - 1; // 0x7ff
//   localparam int EXP32_MAX  = (1<<8)  - 1; // 0xff

//   localparam int PSRC = 112;  // binary128 fraction bits
//   localparam int SIGW = PSRC + 1; // 113-bit significand (hidden + frac)

//   // ----------------------------
//   // Bitwise pack/unpack helpers
//   // ----------------------------
//   function automatic binary128_t bits_to_binary128(input logic [127:0] bits);
//     bits_to_binary128 = binary128_t'(bits); // bitwise reinterpret
//   endfunction

//   function automatic logic [127:0] binary128_to_bits(input binary128_t x);
//     binary128_to_bits = logic [127:0]'(x);
//   endfunction

//   function automatic logic [63:0] binary64_to_bits(input binary64_t x);
//     binary64_to_bits = logic [63:0]'(x);
//   endfunction

//   function automatic logic [31:0] binary32_to_bits(input binary32_t x);
//     binary32_to_bits = logic [31:0]'(x);
//   endfunction

//   // ----------------------------
//   // Right-shift with RN-even rounding
//   // Returns OUTW bits, plus carry-out from "+1 ulp" increment.
//   // ----------------------------
//   function automatic logic [OUTW-1:0] rshift_round_rne #(
//     int OUTW = 53,     // bits to keep
//     int INW  = 113     // input significand width
//   ) (
//     input  logic [INW-1:0] sig,
//     input  int unsigned    sh,
//     output logic           carry_out
//   );
//     logic [INW-1:0] shifted;
//     logic [OUTW-1:0] keep;
//     logic guard, roundb, sticky, lsb, inc;
//     logic [OUTW:0] sum; // one extra for carry

//     begin
//       // Default
//       shifted = '0;
//       keep    = '0;
//       guard   = 1'b0;
//       roundb  = 1'b0;
//       sticky  = 1'b0;

//       // Shift and keep
//       if (sh == 0) begin
//         // keep the bottom OUTW bits (for completeness; not used in our conv flow)
//         keep = sig[OUTW-1:0];
//       end else begin
//         shifted = sig >> sh;
//         keep    = shifted[OUTW-1:0];

//         // Guard bit = first dropped bit
//         guard  = ((sh-1) < INW) ? sig[sh-1] : 1'b0;

//         // Round bit = second dropped bit
//         roundb = (sh >= 2 && (sh-2) < INW) ? sig[sh-2] : 1'b0;

//         // Sticky = OR of all remaining dropped bits
//         if (sh >= 3) begin
//           if ((sh-3) >= INW) sticky = |sig;
//           else               sticky = |sig[sh-3:0];
//         end
//       end

//       lsb = keep[0];
//       inc = guard & (roundb | sticky | lsb);

//       sum       = {1'b0, keep} + inc;
//       carry_out = sum[OUTW];
//       rshift_round_rne = sum[OUTW-1:0];
//     end
//   endfunction

//   // ----------------------------
//   // binary128 (struct) -> binary64 (struct)
//   // ----------------------------
//   function automatic binary64_t binary128_to_binary64(input binary128_t a);
//     binary64_t out;

//     bit is_zero, is_sub, is_inf, is_nan;
//     int E;          // unbiased exponent of source
//     int eT;         // biased exponent for target
//     int unsigned sh;

//     logic [SIGW-1:0] sig;      // 113-bit (hidden + frac)
//     logic carry;
//     logic [52:0] sig53;        // target normal significand (hidden+52)
//     logic [51:0] frac52;       // target fraction
//     logic [51:0] sub52;        // target subnormal fraction

//     begin
//       out = '0;
//       out.sign = a.sign;

//       is_zero = (a.exp == '0) && (a.mantissa == '0);
//       is_sub  = (a.exp == '0) && (a.mantissa != '0);
//       is_inf  = (a.exp == 15'h7fff) && (a.mantissa == '0);
//       is_nan  = (a.exp == 15'h7fff) && (a.mantissa != '0);

//       // NaN
//       if (is_nan) begin
//         out.exp = '1; // all ones
//         // quiet-NaN: set MSB of mantissa, copy payload from top of source
//         out.mantissa = {1'b1, a.mantissa[111 -: 51]};
//         if (out.mantissa == '0) out.mantissa[0] = 1'b1; // avoid Inf encoding
//         return out;
//       end

//       // Inf
//       if (is_inf) begin
//         out.exp = '1;
//         out.mantissa = '0;
//         return out;
//       end

//       // Zero
//       if (is_zero) begin
//         out.exp = '0;
//         out.mantissa = '0;
//         return out;
//       end

//       // Build source unbiased exponent + integer significand
//       if (is_sub) begin
//         E   = 1 - BIAS128;
//         sig = {1'b0, a.mantissa};
//       end else begin
//         E   = int'(a.exp) - BIAS128;
//         sig = {1'b1, a.mantissa};
//       end

//       // Target biased exponent
//       eT = E + BIAS64;

//       // Overflow -> Inf
//       if (eT >= EXP64_MAX) begin
//         out.exp = '1;
//         out.mantissa = '0;
//         return out;
//       end

//       // Subnormal/underflow path (eT <= 0 => exponent field 0)
//       if (eT <= 0) begin
//         // shift = (PSRC - 52) + (E_min - E), where E_min = 1 - BIAS64
//         sh = (PSRC - 52) + int'((1 - BIAS64) - E);

//         sub52 = rshift_round_rne #(.OUTW(52), .INW(SIGW))(sig, sh, carry);

//         // If rounding carried out, it becomes minimum normal
//         if (carry) begin
//           out.exp = 11'd1;
//           out.mantissa = '0;
//         end else begin
//           out.exp = '0;
//           out.mantissa = sub52;
//         end

//         return out;
//       end

//       // Normal path: keep 53 bits (hidden+52). shift = 113 - 53 = 60
//       sh = (SIGW - 53); // 60
//       sig53 = rshift_round_rne #(.OUTW(53), .INW(SIGW))(sig, sh, carry);

//       // If carry: significand overflowed (e.g., 1.111.. -> 10.000..), bump exponent
//       if (carry) begin
//         eT = eT + 1;
//         if (eT >= EXP64_MAX) begin
//           out.exp = '1;
//           out.mantissa = '0;
//           return out;
//         end
//         frac52 = '0;
//       end else begin
//         frac52 = sig53[51:0];
//       end

//       out.exp = $unsigned(eT[10:0]); // truncate is safe in-range
//       out.mantissa = frac52;
//       return out;
//     end
//   endfunction

//   // Convenience: bits[127:0] -> binary64_t
//   function automatic binary64_t binary128_bits_to_binary64(input logic [127:0] bits128);
//     return binary128_to_binary64(bits_to_binary128(bits128));
//   endfunction

//   // ----------------------------
//   // binary128 (struct) -> binary32 (struct)
//   // ----------------------------
//   function automatic binary32_t binary128_to_binary32(input binary128_t a);
//     binary32_t out;

//     bit is_zero, is_sub, is_inf, is_nan;
//     int E;
//     int eT;
//     int unsigned sh;

//     logic [SIGW-1:0] sig;
//     logic carry;
//     logic [23:0] sig24;   // hidden+23
//     logic [22:0] frac23;
//     logic [22:0] sub23;

//     begin
//       out = '0;
//       out.sign = a.sign;

//       is_zero = (a.exp == '0) && (a.mantissa == '0);
//       is_sub  = (a.exp == '0) && (a.mantissa != '0);
//       is_inf  = (a.exp == 15'h7fff) && (a.mantissa == '0);
//       is_nan  = (a.exp == 15'h7fff) && (a.mantissa != '0);

//       if (is_nan) begin
//         out.exp = '1;
//         out.mantissa = {1'b1, a.mantissa[111 -: 22]};
//         if (out.mantissa == '0) out.mantissa[0] = 1'b1;
//         return out;
//       end

//       if (is_inf) begin
//         out.exp = '1;
//         out.mantissa = '0;
//         return out;
//       end

//       if (is_zero) begin
//         out.exp = '0;
//         out.mantissa = '0;
//         return out;
//       end

//       if (is_sub) begin
//         E   = 1 - BIAS128;
//         sig = {1'b0, a.mantissa};
//       end else begin
//         E   = int'(a.exp) - BIAS128;
//         sig = {1'b1, a.mantissa};
//       end

//       eT = E + BIAS32;

//       if (eT >= EXP32_MAX) begin
//         out.exp = '1;
//         out.mantissa = '0;
//         return out;
//       end

//       if (eT <= 0) begin
//         // shift = (PSRC - 23) + (E_min - E), E_min = 1 - BIAS32
//         sh = (PSRC - 23) + int'((1 - BIAS32) - E);

//         sub23 = rshift_round_rne #(.OUTW(23), .INW(SIGW))(sig, sh, carry);

//         if (carry) begin
//           out.exp = 8'd1;
//           out.mantissa = '0;
//         end else begin
//           out.exp = '0;
//           out.mantissa = sub23;
//         end

//         return out;
//       end

//       // Normal: keep 24 bits (hidden+23). shift = 113 - 24 = 89
//       sh = (SIGW - 24); // 89
//       sig24 = rshift_round_rne #(.OUTW(24), .INW(SIGW))(sig, sh, carry);

//       if (carry) begin
//         eT = eT + 1;
//         if (eT >= EXP32_MAX) begin
//           out.exp = '1;
//           out.mantissa = '0;
//           return out;
//         end
//         frac23 = '0;
//       end else begin
//         frac23 = sig24[22:0];
//       end

//       out.exp = $unsigned(eT[7:0]);
//       out.mantissa = frac23;
//       return out;
//     end
//   endfunction

//   // Convenience: bits[127:0] -> binary32_t
//   function automatic binary32_t binary128_bits_to_binary32(input logic [127:0] bits128);
//     return binary128_to_binary32(bits_to_binary128(bits128));
//   endfunction

// endpackage : binary128_convert_pkg
