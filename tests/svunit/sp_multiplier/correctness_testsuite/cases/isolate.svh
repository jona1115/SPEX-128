`SVTEST(single_mode_overflow_to_posinf)
  // max finite * 2.0 -> +INF
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_MAX_FINITE_POS;
  s_i_in_force  = F128_TWO;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  $display(">>>>> s_o_out_jedi=0x%x", s_o_out_jedi);
  `FAIL_UNLESS(is_inf128(s_o_out_jedi) && (s_o_out_jedi[127] == 1'b0)) // +INF
  `FAIL_UNLESS(s_o_metadata.sp_mode == SINGLE_MODE)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END