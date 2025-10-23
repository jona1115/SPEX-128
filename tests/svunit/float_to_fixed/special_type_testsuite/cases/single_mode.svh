// This is to make sure single mode special type detection works

// ZERO
`SVTEST(single_mode_0)
    s_i_float[127] = '0;
    s_i_float[126:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, ZERO)
`SVTEST_END
`SVTEST(single_mode_1)
    s_i_float[127] = '1;
    s_i_float[126:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, ZERO)
`SVTEST_END

// +/- INF
`SVTEST(single_mode_2)
    s_i_float[127] = '0;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = '0;
    $display("s_i_float=%x", s_i_float);
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, POS_INF)
`SVTEST_END
`SVTEST(single_mode_3)
    s_i_float[127] = '1;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = '0;
    $display("s_i_float=%x", s_i_float);
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, NEG_INF)
`SVTEST_END

// +/- NAN
`SVTEST(single_mode_4)
    s_i_float[127] = '0;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = 'd5; // non 0
    $display("s_i_float=%x", s_i_float);
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, NAN)
`SVTEST_END
`SVTEST(single_mode_5)
    s_i_float[127] = '1;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = 'd5; // non 0
    $display("s_i_float=%x", s_i_float);
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, NAN)
`SVTEST_END
