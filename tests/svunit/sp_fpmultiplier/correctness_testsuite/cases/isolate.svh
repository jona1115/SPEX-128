`SVTEST(handwritten_sanity_correctness_test_SINGLEMODE_0)
  logic [127:0] expected = 128'h4000c000000000000000000000000000; // 3.5

  s_i_in_anikin = 128'h3ffe0000000000000000000000000000; // 0.5
  s_i_in_force  = 128'h4001c000000000000000000000000000; // 7.0

  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);

  s_i_valid128_anikin = '1;
  s_i_valid128_force  = '1;
  wait_n_ticks(1);
  s_i_valid128_anikin = '0;
  s_i_valid128_force  = '0;
  wait_n_ticks(`LATENCY - 1);

  $display(">>>>> s_o_out_jedi=0x%x", s_o_out_jedi);
  $display(">>>>> expected=0x%x", expected);

  `FAIL_UNLESS(s_o_out_jedi === expected)
`SVTEST_END