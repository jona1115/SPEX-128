`SVTEST(handwritten_sanity_correctness_test_0)
  logic [127:0] expected = 128'h3fffa61298e1e069bc972dfefab6df34; // 1.6487212707001281468486507878141635764

  s_i_x     = 128'h3ffe0000000000000000000000000000; // 0.5
  s_i_ctrl  = 4'b0000; // single mode

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);
  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

`SVTEST(handwritten_sanity_correctness_test_1)
  logic [127:0] expected = 128'h3fffe34955e21816b5358efea7d97501; // 1.8878377606380024213041543089000788719
                        //    0x3fffe34955e21816b5358efea7d97458

  s_i_x     = 128'h3ffe45575c44f4e77ad333b441e67d10; // 0.63543213216548984651621321000000003673
  s_i_ctrl  = 4'b0000; // single mode

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `PRINT_INTERMEDIATE_RESULTS
  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

`SVTEST(handwritten_sanity_correctness_test_2)
  logic [127:0] expected = 128'h3fffaa5086149bfdd9723b5d8fb5bdd3; // 1.6652911949458863084291607887622380928
                        //    0x3fffaa5086149bfdd9723b5d8fb5bd0e

  s_i_x     = 128'h3ffe051eb851eb851eb851eb851eb852; // 0.5100000000000000000000000000000000077
  s_i_ctrl  = 4'b0000; // single mode

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);
  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

`SVTEST(handwritten_sanity_correctness_test_3)
  logic [127:0] expected = 128'h402899670853bf4bb876f5ead09f48e8; // 3516740446078.5915669155853082529447639
                           // 0x402899670853bf4bb876f5ead09f48a5
  s_i_x     = 128'h4003ce3786259f7d0292051588915546; // 28.888555666890000000000000000000000887
  s_i_ctrl  = 4'b0000; // single mode

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);
  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

`SVTEST(handwritten_sanity_correctness_test_4)
  logic [127:0] expected = 128'h3fff0041919b7ee33ce8184f77d3f23c; // 1.0010005001667083416680557539930582506
                        //    0x3fff0041919b7ee33ce8184f77d3f21b

  s_i_x     = 128'h3ff50624dd2f1a9fbe76c8b439581062; // 0.00099999999999999999999999999999999994282
  s_i_ctrl  = 4'b0000; // single mode

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);
  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

`SVTEST(handwritten_sanity_correctness_test_5)
  logic [127:0] expected = 128'h3fff0000000000000000000000000000; // 1.0

  s_i_x     = '0; // 0.0
  s_i_ctrl  = 4'b0000; // single mode

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `PRINT_INTERMEDIATE_RESULTS
  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

