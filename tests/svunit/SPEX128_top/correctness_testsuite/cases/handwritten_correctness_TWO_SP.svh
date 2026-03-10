`SVTEST(TWO_SP_handwritten_sanity_correctness_test_0_exact)
  logic [127:0] expected = {64'h3ffa61298e1e069c, 64'h3ff6371a3bf42c66};

  s_i_x     = {64'h3fe0000000000000, 64'h3fd50110a137f38c}; // 0.5, 0.32819
  s_i_ctrl  = 4'b0001; // TWO SP mode

  s_i_valid = '1;

  wait_n_ticks(LATENCY_3264);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

`SVTEST(TWO_SP_handwritten_sanity_correctness_test_0)
  logic [127:0] expected = {64'h3ffa61298e1e069c, 64'h3ff6371a3bf42c66};

  s_i_x     = {64'h3fe0000000000000, 64'h3fd50110a137f38c}; // 0.5, 0.32819
  s_i_ctrl  = 4'b0001; // TWO SP mode

  s_i_valid = '1;

  wait_n_ticks(LATENCY_3264);

  `PRINT_INTERMEDIATE_RESULTS
  `PRINT_INTERMEDIATE_VALID_BITS

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `FAIL_UNLESS(lsb_error(expected, s_o_exp_x, `LSB_WINDOW) <= `ERR_TOL_LSB_64)
`SVTEST_END
