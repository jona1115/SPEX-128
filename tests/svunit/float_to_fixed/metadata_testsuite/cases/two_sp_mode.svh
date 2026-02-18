// // This is to make sure two subword mode special type detection works
// `SVTEST(two_sp_mode_special_type_test_0)
//     s_i_float[126:0] = '0;
    // wait_n_ticks(`LATENCY);
//     
//     `FAIL_UNLESS_EQUAL(s_o_float_type_a, ZERO)
// `SVTEST_END
// `SVTEST(two_sp_mode_special_type_test_1)
//     s_i_float[126:0] = '0;
    // wait_n_ticks(`LATENCY);
//     
//     `FAIL_UNLESS_EQUAL(s_o_float_type_b, ZERO)
// `SVTEST_END

// `SVTEST(two_sp_mode_special_type_test_2)
//     s_i_float[126:116] = 'h5; // Not 0
//     // $display("s_i_float=%x", s_i_float);
    // wait_n_ticks(`LATENCY);
//     
//     `FAIL_IF(s_o_float_type_a > NORMAL) // assert a is NORMAL
// `SVTEST_END
// `SVTEST(two_sp_mode_special_type_test_3)
//     s_i_float[62:52] = 'h5; // Not 0
//     // $display("s_i_float=%x", s_i_float);
    // wait_n_ticks(`LATENCY);
//     
//     `FAIL_UNLESS_EQUAL(s_o_float_type_b, NORMAL) // assert b is NORMAL
// `SVTEST_END

// ================================================
// Two SP mode (2 × binary64 packed)
// Lane mapping: A=[63:0] -> float_type_a, B=[127:64] -> float_type_b
// ================================================

// Below is ChatGPT generated based off single_mode.svh

//============================================================
// TWO-SP MODE (binary64 x2) special-type detection tests
// Mode select: s_i_ctrl[1:0] = 2'b01
// Lane mapping (MSB -> LSB):
//   Lane A (float_type_a): s_i_float[127]      sign
//                          s_i_float[126:116]  exp[10:0]
//                          s_i_float[115:64]   frac[51:0]
//
//   Lane B (float_type_b): s_i_float[63]       sign
//                          s_i_float[62:52]    exp[10:0]
//                          s_i_float[51:0]     frac[51:0]
// Lanes C/D are inactive in two-SP mode and must be NA.
//============================================================

// +0 / +0
`SVTEST(two_sp_mode_0)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: +0
    s_i_float[127]      = '0;
    s_i_float[126:116]  = 11'd0;
    s_i_float[115:64]   = '0;

    // Lane B: +0
    s_i_float[63]       = '0;
    s_i_float[62:52]    = 11'd0;
    s_i_float[51:0]     = '0;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// -0 / +0  (zeros are signless => ZERO for both)
`SVTEST(two_sp_mode_1)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: -0
    s_i_float[127]      = '1;
    s_i_float[126:116]  = 11'd0;
    s_i_float[115:64]   = '0;

    // Lane B: +0
    s_i_float[63]       = '0;
    s_i_float[62:52]    = 11'd0;
    s_i_float[51:0]     = '0;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +INF / -INF
`SVTEST(two_sp_mode_2)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: +INF
    s_i_float[127]      = '0;
    s_i_float[126:116]  = 11'h7FF;
    s_i_float[115:64]   = '0;

    // Lane B: -INF
    s_i_float[63]       = '1;
    s_i_float[62:52]    = 11'h7FF;
    s_i_float[51:0]     = '0;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, POS_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NEG_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// NaN / NaN  (sign ignored for NaN)
`SVTEST(two_sp_mode_3)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: NaN
    s_i_float[127]      = '0;
    s_i_float[126:116]  = 11'h7FF;
    s_i_float[115:64]   = 'd5; // non-zero frac

    // Lane B: NaN
    s_i_float[63]       = '1;
    s_i_float[62:52]    = 11'h7FF;
    s_i_float[51:0]     = 'd9; // non-zero frac

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// +Denormal / -Denormal
`SVTEST(two_sp_mode_4)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: +denormal
    s_i_float[127]      = '0;
    s_i_float[126:116]  = 11'd0;
    s_i_float[115:64]   = 'd7; // non-zero frac

    // Lane B: -denormal
    s_i_float[63]       = '1;
    s_i_float[62:52]    = 11'd0;
    s_i_float[51:0]     = 'd11; // non-zero frac

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, POS_DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NEG_DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// Normal(+)/Normal(-)
`SVTEST(two_sp_mode_5)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: normal (+)
    s_i_float[127]      = '0;
    s_i_float[126:116]  = 11'd10;
    s_i_float[115:64]   = 'd1234;

    // Lane B: normal (-)
    s_i_float[63]       = '1;
    s_i_float[62:52]    = 11'd100;
    s_i_float[51:0]     = 'd999;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// Normal near max exp / +0
`SVTEST(two_sp_mode_6)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: normal near max exponent (0x7FE)
    s_i_float[127]      = '1;       // sign doesn't change NORMAL
    s_i_float[126:116]  = 11'h7FE;
    s_i_float[115:64]   = 'd123;

    // Lane B: +0
    s_i_float[63]       = '0;
    s_i_float[62:52]    = 11'd0;
    s_i_float[51:0]     = '0;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END

// NaN / Normal(+)
`SVTEST(two_sp_mode_7)
    s_i_ctrl[1:0] = 2'b01;

    // Lane A: NaN
    s_i_float[127]      = '1;
    s_i_float[126:116]  = 11'h7FF;
    s_i_float[115:64]   = 'd42; // non-zero

    // Lane B: normal (+)
    s_i_float[63]       = '0;
    s_i_float[62:52]    = 11'd30;
    s_i_float[51:0]     = 'd55;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NA)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NA)
`SVTEST_END
