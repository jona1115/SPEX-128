// This is to make sure single mode special type detection works

// +/- ZERO
`SVTEST(single_mode_0)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '0;
    s_i_float[126:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
`SVTEST(single_mode_1)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '1;
    s_i_float[126:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +/- INF
`SVTEST(single_mode_2)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '0;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, POS_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
`SVTEST(single_mode_3)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '1;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NEG_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +/- NAN
`SVTEST(single_mode_4)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '0;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = 'd5; // non 0
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
`SVTEST(single_mode_5)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '1;
    s_i_float[126:112] = 15'h7FFF;
    s_i_float[111:0] = 'd5; // non 0
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +/- Denormal
`SVTEST(single_mode_6)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '0;
    s_i_float[126:112] = 15'd0;
    s_i_float[111:0] = 'd5; // non 0
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
`SVTEST(single_mode_7)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '1;
    s_i_float[126:112] = 15'd0;
    s_i_float[111:0] = 'd5; // non 0
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// NORMAL
`SVTEST(single_mode_8)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '0;
    s_i_float[126:112] = 15'd10;
    s_i_float[111:0] = 'd5; // non 0
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
`SVTEST(single_mode_9)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '1;
    s_i_float[126:112] = 15'd10;
    s_i_float[111:0] = 'd5; // non 0
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
`SVTEST(single_mode_10)
    s_i_ctrl[1:0] = 2'b00;
    s_i_float[127] = '1;
    s_i_float[126:112] = 15'h7FFE;
    s_i_float[111:0] = 'd8324; // non 0
    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END