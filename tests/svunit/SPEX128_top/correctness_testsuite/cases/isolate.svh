`SVTEST(handwritten_sanity_correctness_test_1)
  logic [127:0] expected = 128'h3fffe34955e21816b5358efea7d97501; // 1.8878377606380024213041543089000788719
                        //    0x3fffe34955e21816b5358efea7d97458

  s_i_x     = 128'h3ffe45575c44f4e77ad333b441e67d10; // 0.63543213216548984651621321000000003673
  s_i_ctrl  = 4'b0000; // single mode

  s_i_valid = '1;

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  `PRINT_INTERMEDIATE_RESULTS
  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

  `FAIL_UNLESS(lsb_error(expected, s_o_exp_x, `LSB_WINDOW) <= `ERR_TOL_LSB_128)
  // `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END