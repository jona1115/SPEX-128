// // This is to make sure two subword mode special type detection works
// `SVTEST(two_sp_mode_special_type_test_0)
//     s_i_float[126:0] = '0;
//     #1;
//     `FAIL_UNLESS_EQUAL(s_o_float_type_a, ZERO)
// `SVTEST_END
// `SVTEST(two_sp_mode_special_type_test_1)
//     s_i_float[126:0] = '0;
//     #1;
//     `FAIL_UNLESS_EQUAL(s_o_float_type_b, ZERO)
// `SVTEST_END

// `SVTEST(two_sp_mode_special_type_test_2)
//     s_i_float[126:116] = 'h5; // Not 0
//     // $display("s_i_float=%x", s_i_float);
//     #1;
//     `FAIL_IF(s_o_float_type_a > NORMAL) // assert a is NORMAL
// `SVTEST_END
// `SVTEST(two_sp_mode_special_type_test_3)
//     s_i_float[62:52] = 'h5; // Not 0
//     // $display("s_i_float=%x", s_i_float);
//     #1;
//     `FAIL_UNLESS_EQUAL(s_o_float_type_b, NORMAL) // assert b is NORMAL
// `SVTEST_END

// ================================================
// Two SP mode (2 × binary64 packed)
// Lane mapping: A=[63:0] -> float_type_a, B=[127:64] -> float_type_b
// ================================================

// Below is ChatGPT generated based off single_mode.svh

// ++/- ZERO
`SVTEST(two_mode_0)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (+0)
    s_i_float[127]     = '0;         // sign
    s_i_float[126:116] = 11'd0;      // exp
    s_i_float[115:64]  = '0;         // frac

    // lane A (+0)
    s_i_float[63]      = '0;
    s_i_float[62:52]   = 11'd0;
    s_i_float[51:0]    = '0;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

`SVTEST(two_mode_1)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (+0)
    s_i_float[127]     = '0;
    s_i_float[126:116] = 11'd0;
    s_i_float[115:64]  = '0;

    // lane A (-0)
    s_i_float[63]      = '1;
    s_i_float[62:52]   = 11'd0;
    s_i_float[51:0]    = '0;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +/- INF
`SVTEST(two_mode_2)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (-inf)
    s_i_float[127]     = '1;
    s_i_float[126:116] = 11'h7FF;
    s_i_float[115:64]  = '0;

    // lane A (+inf)
    s_i_float[63]      = '0;
    s_i_float[62:52]   = 11'h7FF;
    s_i_float[51:0]    = '0;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, POS_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NEG_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +/- NaN
`SVTEST(two_mode_3)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (+NaN)
    s_i_float[127]     = '0;
    s_i_float[126:116] = 11'h7FF;
    s_i_float[115:64]  = 52'd5; // nonzero payload

    // lane A (-NaN) (sign irrelevant)
    s_i_float[63]      = '1;
    s_i_float[62:52]   = 11'h7FF;
    s_i_float[51:0]    = 52'd9; // nonzero payload

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +/- Denormal
`SVTEST(two_mode_4)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (-denorm)
    s_i_float[127]     = '1;
    s_i_float[126:116] = 11'd0;
    s_i_float[115:64]  = 52'd7; // nonzero

    // lane A (+denorm)
    s_i_float[63]      = '0;
    s_i_float[62:52]   = 11'd0;
    s_i_float[51:0]    = 52'd3; // nonzero

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// NORMALs (moderate exponents)
`SVTEST(two_mode_5)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (+normal)
    s_i_float[127]     = '0;
    s_i_float[126:116] = 11'd10;
    s_i_float[115:64]  = 52'd5;

    // lane A (+normal)
    s_i_float[63]      = '0;
    s_i_float[62:52]   = 11'd12;
    s_i_float[51:0]    = 52'd11;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

`SVTEST(two_mode_6)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (+normal)
    s_i_float[127]     = '0;
    s_i_float[126:116] = 11'd100;
    s_i_float[115:64]  = 52'd12345;

    // lane A (-normal)
    s_i_float[63]      = '1;
    s_i_float[62:52]   = 11'd55;
    s_i_float[51:0]    = 52'd6789;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// NORMAL near max exponent (7FE != 7FF)
`SVTEST(two_mode_7)
    s_i_ctrl[1:0] = 2'b01;

    // lane B (max-normal)
    s_i_float[127]     = '1;          // sign doesn't change NORMAL
    s_i_float[126:116] = 11'h7FE;
    s_i_float[115:64]  = 52'd8324;

    // lane A (max-normal)
    s_i_float[63]      = '0;
    s_i_float[62:52]   = 11'h7FE;
    s_i_float[51:0]    = 52'd1;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// Mixed: A=NaN, B=normal
`SVTEST(two_mode_8)
    s_i_ctrl[1:0] = 2'b01;

    // lane B normal
    s_i_float[127]     = '0;
    s_i_float[126:116] = 11'd20;
    s_i_float[115:64]  = 52'd55;

    // lane A NaN
    s_i_float[63]      = '0;
    s_i_float[62:52]   = 11'h7FF;
    s_i_float[51:0]    = 52'd999;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// Mixed: A=denorm, B=-0
`SVTEST(two_mode_9)
    s_i_ctrl[1:0] = 2'b01;

    // lane B -0
    s_i_float[127]     = '1;
    s_i_float[126:116] = 11'd0;
    s_i_float[115:64]  = '0;

    // lane A denorm
    s_i_float[63]      = '0;
    s_i_float[62:52]   = 11'd0;
    s_i_float[51:0]    = 52'd7;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
