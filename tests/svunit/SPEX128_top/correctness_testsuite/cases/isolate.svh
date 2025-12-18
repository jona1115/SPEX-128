`SVTEST(handwritten_sanity_correctness_test_1)
  logic [127:0] expected = 128'h3fffe34955e21816b5358efea7d97501; // 1.8878377606380024213041543089000788719
                        //    0x3fffe34955e21816b5358efea7d97458 << actual

  s_i_x     = 128'h3ffe45575c44f4e77ad333b441e67d10; // 0.63543213216548984651621321000000003673
  s_i_ctrl  = 4'b0000; // single mode

  s_i_valid = '1;

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x = 0x%X", s_o_exp_x);
  $display(">>>>> expected  = 0x%x", expected);
  $display(">>>>> error = %d\t(error=expected-actual)", expected[12:0]-s_o_exp_x[12:0]);
  `PRINT_INTERMEDIATE_RESULTS

  `FAIL_UNLESS(lsb_error(expected, s_o_exp_x, `LSB_WINDOW) <= `ERR_TOL_LSB_128)
  // `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END

/*

Level 1:
  Expected    : 0x00145575c44f4e77ad333b441e67d100
  Actual      : 0x00145575c44f4e77ad333b441e67d100

Level 2:
  partition a:
    Expected  : 0x3fff0000000000000000000000000000
    Actual    : 0x3fff0000000000000000000000000000
  partition b:
    Expected  : 0x3fffe3426355efe760144105192248a9
    Actual    : 0x3fffe3426355efe760144105192248a9
  partition c:
    Expected  : 0x3fff0003ae06c52a4dd3579683461415
    Actual    : 0x3fff0003ae06c52a4dd3579683461415
  partition d:
    Expected  : 0x3fff000000227a00025251121aadffae
    Actual    : 0x3fff000000227a00025251121aadffae
  partition e:
    Expected  : 0x3fff000000000073b00000001a23cc80
    Actual    : 0x3fff000000000073b00000001a23cc80
  partition f:
    Expected  : 0x3fff0000000000000d6999da20f33e88
    Actual    : 0x3fff0000000000000d6999da20f33e88

Level 3:
  mul 0: a*b=i
    Expected  : 0x3fffe3426355efe760144105192248a9
    Actual    : 0x3fffe3426355efe760144105192248a9
  mul 1: c*d=j
    Expected  : 0x3fff0003ae293fa92dfb1ac81324acb0
    Actual    : 0x3fff0003ae293fa92dfb1ac81324acb0
  mul 2: e*f=k
    Expected  : 0x3fff000000000073bd6999da3b1d1ab1
    Actual    : 0x3fff000000000073bd6999da3b1d1ab1
  mul 3: i*j=z
    Expected  : 0x3fffe34955e2173c35af7a7f428a4047
    Actual    : 0x3fffe34955e2173c35af7a7f428a4047
  mul 4: z*k=expx
    Expected  : 0x3fffe34955e21816b5358efea7d97458
    Actual    : 0x3fffe34955e21816b5358efea7d97458
*/
