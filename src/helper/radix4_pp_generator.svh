genvar pp_row_g;
logic [RADIX4_PP_NBITS : 0] s_S1_force_pad;
assign s_S1_force_pad = {{(RADIX4_PP_NBITS+1-EX_MAN_BITS_128){1'b0}}, i_force};

generate
  for (pp_row_g = 0; pp_row_g < RADIX4_ROWS; pp_row_g++) begin : radix4_pp_row_gen
    localparam int RADIX4_DIGIT_LSB = pp_row_g * 2;
    localparam int RADIX4_DIGIT_MSB = (pp_row_g * 2) + 1;

    logic [1:0]                   s_S1_force_digit_row;
    logic [RADIX4_PP_NBITS-1 : 0] s_S1_anikin_ext_row;
    logic [RADIX4_PP_NBITS-1 : 0] s_S1_anikin_masked_row;
    logic [RADIX4_PP_NBITS : 0]   s_S1_pp_full_row;

    always_comb begin : radix4_pp_row_comb
      // Defaults
      s_S1_force_digit_row   = '0;
      s_S1_anikin_ext_row    = {{(RADIX4_PP_NBITS-EX_MAN_BITS_128){1'b0}}, i_anikin};
      s_S1_anikin_masked_row = s_S1_anikin_ext_row;
      s_S1_pp_full_row       = '0;
      s_pp[pp_row_g]         = '0;

      // Force radix-4 digit from zero-extended multiplier bits.
      s_S1_force_digit_row = s_S1_force_pad[RADIX4_DIGIT_LSB +: 2];

      // Mask multiplicand to enforce subword-parallel "no cross terms" behavior.
      unique case (i_metadata.sp_mode)
        SINGLE_MODE: begin
          // no masking
        end

        TWO_SP_MODE: begin
          if (RADIX4_DIGIT_MSB <= 54) begin
            s_S1_anikin_masked_row[RADIX4_PP_NBITS-1:53] = '0;    // keep [52:0]
          end
          else begin
            s_S1_anikin_masked_row[54:0] = '0;                    // keep [RADIX4_PP_NBITS-1:55]
          end
        end

        FOUR_SP_MODE: begin
          if (RADIX4_DIGIT_MSB <= 25) begin
            s_S1_anikin_masked_row[RADIX4_PP_NBITS-1:24] = '0;    // lane d: [23:0]
          end
          else if (RADIX4_DIGIT_MSB <= 52) begin
            s_S1_anikin_masked_row[RADIX4_PP_NBITS-1:50] = '0;
            s_S1_anikin_masked_row[25:0] = '0;                    // lane c: [49:26]
          end
          else if (RADIX4_DIGIT_MSB <= 78) begin
            s_S1_anikin_masked_row[RADIX4_PP_NBITS-1:77] = '0;
            s_S1_anikin_masked_row[52:0] = '0;                    // lane b: [76:53]
          end
          else begin
            s_S1_anikin_masked_row[RADIX4_PP_NBITS-1:103] = '0;
            s_S1_anikin_masked_row[78:0] = '0;                    // lane a: [102:79]
          end
        end

        default: begin
        end
      endcase

      // Compute one radix-4 partial-product row.
      unique case (s_S1_force_digit_row)
        2'b00: s_S1_pp_full_row = '0;                                                               // 0
        2'b01: s_S1_pp_full_row = {1'b0, s_S1_anikin_masked_row};                                   // X
        2'b10: s_S1_pp_full_row = {s_S1_anikin_masked_row, 1'b0};                                   // 2X
        2'b11: s_S1_pp_full_row = {s_S1_anikin_masked_row, 1'b0} + {1'b0, s_S1_anikin_masked_row};  // 3X
        default: s_S1_pp_full_row = '0;
      endcase

      s_pp[pp_row_g] = s_S1_pp_full_row[RADIX4_PP_NBITS-1 : 0];
    end
  end
endgenerate
