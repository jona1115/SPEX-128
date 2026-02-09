localparam int RADIX4_PP_NBITS = EX_MAN_BITS_128;

logic [RADIX4_PP_NBITS+1 : 0] s_S1_pp_full;
logic [RADIX4_PP_NBITS+1 : 0] s_S1_pp_folded;
logic [RADIX4_PP_NBITS-1 : 0] s_S1_anikin_masked;
logic [RADIX4_PP_NBITS-1 : 0] s_S1_carry_add;
logic [1:0]                   s_S1_carry_out;

logic [RADIX4_PP_NBITS : 0]   s_S1_force_pad; // pad one MSB to make even number of bits (113 -> 114)
assign s_S1_force_pad = {1'b0, i_force};

int pp_row, mtpc_i; // mtpc == MulTiPliCant
always_comb begin : radix4_pp_generator
  // Defaults
  s_pp           = '{default:'0};
  s_pp_carry_out = '0;

  s_S1_carry_add = '0;
  s_S1_carry_out = '0;

  pp_row = 0;
  for (mtpc_i = 0; mtpc_i < RADIX4_PP_NBITS+1; mtpc_i += 2) begin
    // Mask multiplicand to enforce subword-parallel "no cross terms" behavior.
    // We key lane selection off the MSB index of this radix-4 digit (mtpc_i+1).
    s_S1_anikin_masked = i_anikin;
    unique case (i_metadata.sp_mode)
      SINGLE_MODE: begin
        // no masking
      end

      TWO_SP_MODE: begin
        if ((mtpc_i+1) <= 54) begin
          s_S1_anikin_masked[RADIX4_PP_NBITS-1:53] = '0;    // keep [52:0]
        end
        else begin
          s_S1_anikin_masked[54:0] = '0;                    // keep [RADIX4_PP_NBITS-1:55]
        end
      end

      FOUR_SP_MODE: begin
        if ((mtpc_i+1) <= 25) begin
          s_S1_anikin_masked[RADIX4_PP_NBITS-1:24] = '0;    // lane d: [23:0]
        end
        else if ((mtpc_i+1) <= 52) begin
          s_S1_anikin_masked[RADIX4_PP_NBITS-1:50] = '0;
          s_S1_anikin_masked[25:0] = '0;                    // lane c: [49:26]
        end
        else if ((mtpc_i+1) <= 78) begin
          s_S1_anikin_masked[RADIX4_PP_NBITS-1:77] = '0;
          s_S1_anikin_masked[52:0] = '0;                    // lane b: [76:53]
        end
        else begin
          s_S1_anikin_masked[RADIX4_PP_NBITS-1:103] = '0;
          s_S1_anikin_masked[78:0] = '0;                    // lane a: [102:79]
        end
      end

      default: begin
      end
    endcase

    // Compute digit * multiplicand as (N+2)-bit value.
    unique case (s_S1_force_pad[mtpc_i +: 2])
      2'b00: s_S1_pp_full = '0;
      2'b01: s_S1_pp_full = {2'b0, s_S1_anikin_masked};
      2'b10: s_S1_pp_full = {1'b0, s_S1_anikin_masked, 1'b0}; // 2X
      2'b11: s_S1_pp_full = {1'b0, s_S1_anikin_masked, 1'b0} + {2'b0, s_S1_anikin_masked}; // 3X
      default: s_S1_pp_full = '0;
    endcase

    // Fold any overflow above bit[EX_MAN_BITS_128-1] into subsequent radix-4 rows.
    s_S1_pp_folded = s_S1_pp_full + {2'b0, s_S1_carry_add};

    s_pp[pp_row]   = s_S1_pp_folded[RADIX4_PP_NBITS-1:0];
    s_S1_carry_out = s_S1_pp_folded[RADIX4_PP_NBITS+1 : RADIX4_PP_NBITS];
    s_S1_carry_add = {s_S1_carry_out, {(RADIX4_PP_NBITS-2){1'b0}}}; // shift down by 2 (row spacing is 2 bits)

    pp_row += 1;
  end

  // Carry bits beyond the last partial-product row.
  // For EX_MAN_BITS_128=113 and RADIX4_ROWS=57: s_pp_carry_out[0] maps to o_jedi[225], s_pp_carry_out[1] would
  //                                             map to bit 226 (should be 0).
  s_pp_carry_out = s_S1_carry_out;
end // radix4_pp_generator
