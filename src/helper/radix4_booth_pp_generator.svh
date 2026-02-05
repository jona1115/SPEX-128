logic [EX_MAN_BITS_128+1 : 0] i_force_padded;
assign i_force_padded = {1'b0, i_force, 1'b0};  // Because for SINGLE_MODE i_force is 113 bit, per radix 4 rule, we
                                                // pad the LSB with one 0, and the MSB with one 0.

genvar i;
generate : dfasda
  for (i = 0; i < RADIX_4_ROWS - 2; i=i+1) begin : generate_PP_rows
    radix4_encoder #() my_i_radix4_encoder (
      .i_multiplicand(i_force),
      .i_a(i_force_padded[i+2 : i]),
      .o_encoded_multiplicand(s_pp[i])
    );
  end // generate_PP_rows
endgenerate // dfasda

// todo black out unused sections