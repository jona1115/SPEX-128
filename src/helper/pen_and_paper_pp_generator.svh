always_comb begin : pp_matrix_generator // pp = partial products
  for (row = 0; row < EX_MAN_BITS_128; row = row + 1) begin : pp_row_generator
    for (col = 0; col < EX_MAN_BITS_128; col = col + 1) begin : pp_col_generator
      s_pp[row][col] = i_anikin[col] & i_force[row];

      unique case (i_metadata.sp_mode)
        SINGLE_MODE: begin
        end // SINGLE_MODE

        TWO_SP_MODE: begin
          // Zero out: top left, bottom right
          if ((/*TL*/row >= 0   && row <= 54  && col >= 53  && col <= 112) ||
              (/*BR*/row >= 55  && row <= 112 && col >= 0   && col <= 54)) begin
            s_pp[row][col] = 0;
          end
        end // TWO_SP_MODE

        FOUR_SP_MODE: begin
          // Zero out: TL, BR (slighly different from TWO_SP_MODE)
          if ((/*TL*/row >= 0   && row <= 52  && col >= 50  && col <= 112) ||
              (/*BR*/row >= 50  && row <= 112 && col >= 0   && col <= 52)) begin
            s_pp[row][col] = 0;
          end
          
          // Zero out: TR's TL/BR, BL's TL/BR
          if ((/*TRTL*/row >= 0 && row <= 23 && col >= 24 && col <= 52) ||
              (/*TRBR*/row >= 24 && row <= 52 && col >= 0 && col <= 23) ||
              (/*BLTL*/row >= 53 && row <= 78 && col >= 77 && col <= 112) ||
              (/*BLBR*/row >= 77 && row <= 112 && col >= 50 && col <= 78)) begin
            s_pp[row][col] = 0;
          end
        end // FOUR_SP_MODE

        default: begin
        end // default
      endcase
    end // pp_col_generator
  end // pp_row_generator
end // pp_matrix_generator