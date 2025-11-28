`SVTEST(single_mode_underflow_to_zero)
  // min normal * 2^-200 -> rounds to 0 (magnitude < min subnormal)
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_MIN_NORMAL;
  s_i_in_force  = F128_2_NEG_200;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  $display(">>>>> s_i_in_anikin=0x%x", s_i_in_anikin);
  $display(">>>>> s_i_in_force=0x%x", s_i_in_force);
  $display(">>>>> s_o_out_jedi=0x%x", s_o_out_jedi);
  `FAIL_UNLESS(s_o_out_jedi == 128'b0)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END