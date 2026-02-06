logic [EX_MAN_BITS_128+2-1  : 0]  s_S1_0X;
logic [EX_MAN_BITS_128+2-1  : 0]  s_S1_1X;
logic [EX_MAN_BITS_128+2-1  : 0]  s_S1_2X;
logic [EX_MAN_BITS_128+2-1  : 0]  s_S1_3X;

logic [EX_MAN_BITS_128+1    : 0]  s_S1_anikin_pad; // Because i_anikin is 113 bits, so we pad with one bit at MSB to make it 114

// Pre-generate the outputs
assign s_S1_0X = '0;
assign s_S1_1X = {2'b0, i_force};
assign s_S1_2X = {1'b0, i_force, 1'b0};
assign s_S1_3X = {1'b0, i_force} + i_force;

assign s_S1_anikin_pad = {1'b0, i_anikin};

int pp_row, mtpc_i; // mtpc == MulTiPliCant
always_comb begin : radix4_pp_generator
  pp_row = 0;
  for (mtpc_i = 0; mtpc_i < EX_MAN_BITS_128+1; mtpc_i += 2) begin // "+1" because we prepend one bit to i_anikin
    unique case (s_S1_anikin_pad[mtpc_i +: 2])
      2'b00: begin
        s_pp[pp_row] = s_S1_0X;
      end

      2'b01: begin
        s_pp[pp_row] = s_S1_1X;
      end

      2'b10: begin
        s_pp[pp_row] = s_S1_2X;
      end

      2'b11: begin
        s_pp[pp_row] = s_S1_3X;
      end

      default: begin
        s_pp[pp_row] = s_S1_0X;
      end
    endcase

    pp_row += 1;
  end
end // radix4_pp_generator
