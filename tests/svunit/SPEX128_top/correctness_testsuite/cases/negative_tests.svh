`SVTEST(SINGLE_negative_test_0)
  logic [127:0] expected = 128'h3ffe368b2fc6f9609fe7aceb46aa619c; // 1.6487212707001281468486507878141635764

  s_i_x     = 128'hbffe0000000000000000000000000000; // -0.5
  s_i_ctrl  = 4'b0000; // single mode

  s_i_valid = '1;

  wait_n_ticks(LATENCY_128);

  // $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  // $display(">>>>> expected  = 0x%x", expected);
  // $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `FAIL_UNLESS(s_o_exp_x === expected)
  // `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END


`SVTEST(SINGLE_negative_test_1)
  logic [127:0] expected = 128'h3ffe1be29d41127b21611917fe0142e9; // fp128_t expx = fp128_exp(x);

  s_i_x     = 128'hbffe2df4525b028488c14a7ce4f1eea8; // fp128_t x = -0.589754651651Q;
  s_i_ctrl  = 4'b0000; // single mode

  s_i_valid = '1;

  wait_n_ticks(LATENCY_128);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `FAIL_UNLESS(lsb_error(expected, s_o_exp_x, `LSB_WINDOW) <= `ERR_TOL_LSB_128)
  // `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

`SVTEST(TWO_SP_negative_test_0)
  logic [127:0] expected = {64'h3fe368b2fc6f960a, 64'h3fe368b2fc6f960a}; // 0.606531

  s_i_x     = {64'hbfe0000000000000, 64'hbfe0000000000000}; // -0.5, 
  s_i_ctrl  = 4'b0001; // TWO SP mode

  s_i_valid = '1;

  wait_n_ticks(LATENCY_64);

  // $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  // $display(">>>>> expected  = 0x%x", expected);
  // $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `FAIL_UNLESS(s_o_exp_x === expected)
  // `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END
