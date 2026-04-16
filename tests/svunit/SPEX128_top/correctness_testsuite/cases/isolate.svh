// `SVTEST(SINGLE_handwritten_sanity_correctness_test_1)
//   logic [127:0] expected = 128'h3fffe34955e21816b5358efea7d97501; // 1.8878377606380024213041543089000788719
//                         //    0x3fffe34955e21816b5358efea7d97458

//   s_i_x     = 128'h3ffe45575c44f4e77ad333b441e67d10; // 0.63543213216548984651621321000000003673
//   s_i_ctrl  = 4'b0000; // single mode

//   s_i_valid = '1;

//   wait_n_ticks(LATENCY_128);

//   `PRINT_INTERMEDIATE_RESULTS

//   $display(">>>>> s_i_x = 0x%X", s_i_x);
//   $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
//   $display(">>>>> expected  = 0x%x", expected);
//   $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);

//   `FAIL_UNLESS(lsb_error(expected, s_o_exp_x, `LSB_WINDOW) <= `ERR_TOL_LSB_128)
//   // `FAIL_UNLESS(s_o_exp_x === expected)
// `SVTEST_END

/*

  ------------------------------------------------------------------------------------------------------------
                          C                                       SV
  ------------------------------------------------------------------------------------------------------------
  Input                   0x3ffe45575c44f4e77ad333b441e67d10      0x3ffe45575c44f4e77ad333b441e67d10
  ------------------------------------------------------------------------------------------------------------
  Level 1                 0x00145575c44f4e77ad333b441e67d100      0x00145575c44f4e77ad333b441e67d100
  ------------------------------------------------------------------------------------------------------------
  Level 2 partition a     0x3fff0000000000000000000000000000      0x3fff0000000000000000000000000000
          partition b     0x3fffe3426355efe760144105192248a9      0x3fffe3426355efe760144105192248a9
          partition c     0x3fff0003ae06c52a4dd3579683461415      0x3fff0003ae06c52a4dd3579683461415
          partition d     0x3fff000000227a00025251121aadffae      0x3fff000000227a00025251121aadffae
          partition e     0x3fff000000000073b00000001a23cc80      0x3fff000000000073b00000001a23cc80
          partition f     0x3fff0000000000000d6999da20f33e88      0x3fff0000000000000d6999da20f33e88 (0x3fff0000000000000d6999da20f33ee2)
  ------------------------------------------------------------------------------------------------------------
  Level 3 mul0            0x3fffe3426355efe760144105192248a9      0x3fffe3426355efe760144105192248a9
          mul1            0x3fff0003ae293fa92dfb1ac81324acb0      0x3fff0003ae293fa92dfb1ac81324acb0
          mul2            0x3fff000000000073bd6999da3b1d1ab1      0x3fff000000000073bd6999da3b1d1ab1
          mul3            0x3fffe34955e2173c35af7a7f428a4047      0x3fffe34955e2173c35af7a7f428a4047
          mul4            0x3fffe34955e21816b5358efea7d97458      0x3fffe34955e21816b5358efea7d97458
  ------------------------------------------------------------------------------------------------------------

 */
