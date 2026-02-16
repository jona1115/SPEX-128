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

  // 16-bit leading-zero count, assumes input is non-zero.
  function automatic logic [3:0] lzc_16_nz(input logic [15:0] in);
    logic [7:0] lvl8;
    logic [3:0] lvl4;
    logic [1:0] lvl2;
    logic [3:0] lz;
    begin
      if (|in[15:8]) begin
        lz[3] = 1'b0;
        lvl8  = in[15:8];
      end
      else begin
        lz[3] = 1'b1;
        lvl8  = in[7:0];
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

      lz[0]    = (~lvl2[1]) & (lvl2[1] | lvl2[0]);
      lzc_16_nz = lz;
    end
  endfunction

  // 113-bit leading-zero count, assumes input is non-zero.
  // Returns 0..112 only.
  function automatic logic [6:0] lzc_113_nz(input logic [112:0] in);
    logic [127:0] in_ext;
    logic [7:0]   blk_has1;
    logic [2:0]   blk_sel;
    logic [15:0]  blk_data;
    logic [6:0]   blk_base_lz;
    logic [3:0]   in_blk_lz;
    begin
      in_ext = {in, 15'b0};

      blk_has1[7] = |in_ext[127:112];
      blk_has1[6] = |in_ext[111:96];
      blk_has1[5] = |in_ext[95:80];
      blk_has1[4] = |in_ext[79:64];
      blk_has1[3] = |in_ext[63:48];
      blk_has1[2] = |in_ext[47:32];
      blk_has1[1] = |in_ext[31:16];
      blk_has1[0] = |in_ext[15:0];

      if (|blk_has1[7:4]) begin
        if (|blk_has1[7:6]) begin
          blk_sel = blk_has1[7] ? 3'd7 : 3'd6;
        end
        else begin
          blk_sel = blk_has1[5] ? 3'd5 : 3'd4;
        end
      end
      else begin
        if (|blk_has1[3:2]) begin
          blk_sel = blk_has1[3] ? 3'd3 : 3'd2;
        end
        else begin
          if (blk_has1[1]) begin
            blk_sel = 3'd1;
          end
          else if (blk_has1[0]) begin
            blk_sel = 3'd0;
          end
          else begin
            blk_sel = 3'd0;
          end
        end
      end

      unique case (blk_sel)
        3'd7: begin blk_data = in_ext[127:112]; blk_base_lz = 7'd0;   end
        3'd6: begin blk_data = in_ext[111:96];  blk_base_lz = 7'd16;  end
        3'd5: begin blk_data = in_ext[95:80];   blk_base_lz = 7'd32;  end
        3'd4: begin blk_data = in_ext[79:64];   blk_base_lz = 7'd48;  end
        3'd3: begin blk_data = in_ext[63:48];   blk_base_lz = 7'd64;  end
        3'd2: begin blk_data = in_ext[47:32];   blk_base_lz = 7'd80;  end
        3'd1: begin blk_data = in_ext[31:16];   blk_base_lz = 7'd96;  end
        default: begin blk_data = in_ext[15:0]; blk_base_lz = 7'd112; end
      endcase

      in_blk_lz  = lzc_16_nz(blk_data);
      lzc_113_nz = blk_base_lz + {3'b000, in_blk_lz};
    end
  endfunction

  // Timing-friendly indexed bit getter:
  // 1) pick 16-bit chunk
  // 2) pick bit within chunk
  // Out-of-range index -> 0.
  function automatic logic get_bit_113(
    input logic [112:0] sig,
    input logic signed [9:0] idx
  );
    logic [127:0] sig_ext;
    logic [2:0]   blk_sel;
    logic [3:0]   bit_sel;
    logic [15:0]  chunk;
    begin
      sig_ext = {15'b0, sig};
      if (idx[9] || (idx > 10'sd112)) begin
        get_bit_113 = 1'b0;
      end
      else begin
        blk_sel = idx[6:4];
        bit_sel = idx[3:0];

        unique case (blk_sel)
          3'd0: chunk = sig_ext[15:0];
          3'd1: chunk = sig_ext[31:16];
          3'd2: chunk = sig_ext[47:32];
          3'd3: chunk = sig_ext[63:48];
          3'd4: chunk = sig_ext[79:64];
          3'd5: chunk = sig_ext[95:80];
          3'd6: chunk = sig_ext[111:96];
          default: chunk = sig_ext[127:112];
        endcase

        get_bit_113 = chunk[bit_sel];
      end
    end
  endfunction

  // suffix_or[i] = OR(sig[i:0]), built with a fixed-depth tree.
  function automatic logic [112:0] suffix_or_113(input logic [112:0] sig);
    logic [112:0] st1;
    logic [112:0] st2;
    logic [112:0] st3;
    logic [112:0] st4;
    logic [112:0] st5;
    logic [112:0] st6;
    logic [112:0] st7;
    begin
      st1 = sig | (sig << 1);
      st2 = st1 | (st1 << 2);
      st3 = st2 | (st2 << 4);
      st4 = st3 | (st3 << 8);
      st5 = st4 | (st4 << 16);
      st6 = st5 | (st5 << 32);
      st7 = st6 | (st6 << 64);
      suffix_or_113 = st7;
    end
  endfunction

  function automatic binary64_t binary128_to_binary64_rne(input logic [127:0] in_bits);
    localparam logic signed [17:0] C_BIAS128   = 18'sd16383;
    localparam logic signed [17:0] C_SUB_EXP128 = -18'sd16382;
    localparam logic signed [17:0] C_BIAS64    = 18'sd1023;
    localparam logic signed [17:0] C_EXP_MAX64 = 18'sd1023;
    localparam logic signed [17:0] C_EXP_MIN64 = -18'sd1022;
    typedef logic [10:0] exp64_bits_t;

    binary128_t in;
    binary64_t  out;
    binary64_t  cand_nan;
    binary64_t  cand_inf;
    binary64_t  cand_zero;
    binary64_t  cand_finite;

    logic is_exp_all_ones;
    logic is_exp_zero;
    logic is_frac_zero;
    logic is_nan;
    logic is_inf;
    logic is_zero;
    logic is_sub;
    logic [2:0] class_sel;

    logic [112:0] sig_full;
    logic [112:0] sig_suffix_or;
    logic is_sig_zero;

    logic [6:0] lz;
    logic [6:0] p;

    logic signed [17:0] exp_unbiased;
    logic signed [17:0] exp_norm;
    logic signed [17:0] shift_sub_s;
    logic signed [17:0] exp_rounded;

    logic finite_overflow;
    logic finite_subnormal;
    logic normal_overflow;

    logic signed [9:0] shift_sub_idx;
    logic signed [9:0] idx_keep_msb;
    logic signed [9:0] k_keep_lsb;
    logic signed [9:0] kG;
    logic signed [9:0] kR;
    logic signed [9:0] kS_max;

    logic [52:0] keep;
    logic        G;
    logic        R;
    logic        S;
    logic        round_inc;
    logic [53:0] rounded;
    logic        round_carry;
    begin
      in = binary128_t'(in_bits);

      is_exp_all_ones = &in.exp;
      is_exp_zero     = ~|in.exp;
      is_frac_zero    = ~|in.mantissa;

      is_nan  = is_exp_all_ones & ~is_frac_zero;
      is_inf  = is_exp_all_ones &  is_frac_zero;
      is_zero = is_exp_zero     &  is_frac_zero;
      is_sub  = is_exp_zero     & ~is_frac_zero;
      class_sel = {is_nan, is_inf, is_zero};

      sig_full      = {~is_exp_zero, in.mantissa};
      is_sig_zero   = ~|sig_full;
      sig_suffix_or = suffix_or_113(sig_full);

      if (is_sig_zero) begin
        lz = 7'd0;
      end
      else begin
        lz = lzc_113_nz(sig_full);
      end
      p = 7'd112 - lz;

      exp_unbiased = is_sub ? C_SUB_EXP128 : ($signed({3'b000, in.exp}) - C_BIAS128);
      exp_norm     = exp_unbiased - $signed({11'd0, lz});

      finite_overflow  = (exp_norm > C_EXP_MAX64);
      finite_subnormal = (exp_norm < C_EXP_MIN64);
      shift_sub_s      = C_EXP_MIN64 - exp_norm;

      if (finite_subnormal) begin
        if (shift_sub_s[17]) begin
          shift_sub_idx = 10'sd0;
        end
        else if (shift_sub_s > 18'sd255) begin
          shift_sub_idx = 10'sd255;
        end
        else begin
          shift_sub_idx = $signed({2'b00, shift_sub_s[7:0]});
        end
      end
      else begin
        shift_sub_idx = 10'sd0;
      end

      // Window extraction indices (equivalent to normalized-shifted slicing).
      idx_keep_msb = $signed({3'b000, p}) + shift_sub_idx;
      k_keep_lsb   = idx_keep_msb - 10'sd52;
      kG           = idx_keep_msb - 10'sd53;
      kR           = idx_keep_msb - 10'sd54;
      kS_max       = idx_keep_msb - 10'sd55;

      keep = '0;
      for (logic [5:0] j = 6'd0; j < 6'd53; j = j + 6'd1) begin
        keep[j] = get_bit_113(sig_full, k_keep_lsb + $signed({4'b0000, j}));
      end
      G = get_bit_113(sig_full, kG);
      R = get_bit_113(sig_full, kR);
      if (kS_max[9]) begin
        S = 1'b0;
      end
      else if (kS_max > 10'sd112) begin
        S = sig_suffix_or[112];
      end
      else begin
        S = get_bit_113(sig_suffix_or, kS_max);
      end

      round_inc   = G && (R || S || keep[0]);
      rounded     = {1'b0, keep} + {{53{1'b0}}, round_inc};
      round_carry = rounded[53];

      exp_rounded    = exp_norm + (round_carry ? 18'sd1 : 18'sd0);
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

      unique case (class_sel)
        3'b100: out = cand_nan;
        3'b010: out = cand_inf;
        3'b001: out = cand_zero;
        default: out = cand_finite;
      endcase

      binary128_to_binary64_rne = out;
    end
  endfunction

  function automatic binary32_t binary128_to_binary32_rne(input logic [127:0] in_bits);
    localparam logic signed [17:0] C_BIAS128    = 18'sd16383;
    localparam logic signed [17:0] C_SUB_EXP128 = -18'sd16382;
    localparam logic signed [17:0] C_BIAS32     = 18'sd127;
    localparam logic signed [17:0] C_EXP_MAX32  = 18'sd127;
    localparam logic signed [17:0] C_EXP_MIN32  = -18'sd126;
    typedef logic [7:0] exp32_bits_t;

    binary128_t in;
    binary32_t  out;
    binary32_t  cand_nan;
    binary32_t  cand_inf;
    binary32_t  cand_zero;
    binary32_t  cand_finite;

    logic is_exp_all_ones;
    logic is_exp_zero;
    logic is_frac_zero;
    logic is_nan;
    logic is_inf;
    logic is_zero;
    logic is_sub;
    logic [2:0] class_sel;

    logic [112:0] sig_full;
    logic [112:0] sig_suffix_or;
    logic is_sig_zero;

    logic [6:0] lz;
    logic [6:0] p;

    logic signed [17:0] exp_unbiased;
    logic signed [17:0] exp_norm;
    logic signed [17:0] shift_sub_s;
    logic signed [17:0] exp_rounded;

    logic finite_overflow;
    logic finite_subnormal;
    logic normal_overflow;

    logic signed [9:0] shift_sub_idx;
    logic signed [9:0] idx_keep_msb;
    logic signed [9:0] k_keep_lsb;
    logic signed [9:0] kG;
    logic signed [9:0] kR;
    logic signed [9:0] kS_max;

    logic [23:0] keep;
    logic        G;
    logic        R;
    logic        S;
    logic        round_inc;
    logic [24:0] rounded;
    logic        round_carry;
    begin
      in = binary128_t'(in_bits);

      is_exp_all_ones = &in.exp;
      is_exp_zero     = ~|in.exp;
      is_frac_zero    = ~|in.mantissa;

      is_nan  = is_exp_all_ones & ~is_frac_zero;
      is_inf  = is_exp_all_ones &  is_frac_zero;
      is_zero = is_exp_zero     &  is_frac_zero;
      is_sub  = is_exp_zero     & ~is_frac_zero;
      class_sel = {is_nan, is_inf, is_zero};

      sig_full      = {~is_exp_zero, in.mantissa};
      is_sig_zero   = ~|sig_full;
      sig_suffix_or = suffix_or_113(sig_full);

      if (is_sig_zero) begin
        lz = 7'd0;
      end
      else begin
        lz = lzc_113_nz(sig_full);
      end
      p = 7'd112 - lz;

      exp_unbiased = is_sub ? C_SUB_EXP128 : ($signed({3'b000, in.exp}) - C_BIAS128);
      exp_norm     = exp_unbiased - $signed({11'd0, lz});

      finite_overflow  = (exp_norm > C_EXP_MAX32);
      finite_subnormal = (exp_norm < C_EXP_MIN32);
      shift_sub_s      = C_EXP_MIN32 - exp_norm;

      if (finite_subnormal) begin
        if (shift_sub_s[17]) begin
          shift_sub_idx = 10'sd0;
        end
        else if (shift_sub_s > 18'sd255) begin
          shift_sub_idx = 10'sd255;
        end
        else begin
          shift_sub_idx = $signed({2'b00, shift_sub_s[7:0]});
        end
      end
      else begin
        shift_sub_idx = 10'sd0;
      end

      // Window extraction indices (equivalent to normalized-shifted slicing).
      idx_keep_msb = $signed({3'b000, p}) + shift_sub_idx;
      k_keep_lsb   = idx_keep_msb - 10'sd23;
      kG           = idx_keep_msb - 10'sd24;
      kR           = idx_keep_msb - 10'sd25;
      kS_max       = idx_keep_msb - 10'sd26;

      keep = '0;
      for (logic [4:0] j = 5'd0; j < 5'd24; j = j + 5'd1) begin
        keep[j] = get_bit_113(sig_full, k_keep_lsb + $signed({5'b00000, j}));
      end
      G = get_bit_113(sig_full, kG);
      R = get_bit_113(sig_full, kR);
      if (kS_max[9]) begin
        S = 1'b0;
      end
      else if (kS_max > 10'sd112) begin
        S = sig_suffix_or[112];
      end
      else begin
        S = get_bit_113(sig_suffix_or, kS_max);
      end

      round_inc   = G && (R || S || keep[0]);
      rounded     = {1'b0, keep} + {{24{1'b0}}, round_inc};
      round_carry = rounded[24];

      exp_rounded    = exp_norm + (round_carry ? 18'sd1 : 18'sd0);
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

      unique case (class_sel)
        3'b100: out = cand_nan;
        3'b010: out = cand_inf;
        3'b001: out = cand_zero;
        default: out = cand_finite;
      endcase

      binary128_to_binary32_rne = out;
    end
  endfunction

endpackage : binary128_convert_pkg
