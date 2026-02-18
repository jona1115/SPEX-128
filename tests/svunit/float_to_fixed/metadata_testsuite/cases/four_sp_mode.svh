// // This is to make sure four subword mode special type detection works
// `SVTEST(four_sp_mode_special_type_test_0)
//     s_i_float[126:0] = '0;
//     wait_n_ticks(`LATENCY);

//     `FAIL_UNLESS_EQUAL(s_o_float_type_a, ZERO)
// `SVTEST_END

// =======================================================
// Four SP mode (4 × binary32 packed)
// Lane mapping (low->high):
// A=[31:0]  -> float_type_a
// B=[63:32] -> float_type_b
// C=[95:64] -> float_type_c
// D=[127:96]-> float_type_d
// =======================================================

// Below is ChatGPT generated based off single_mode.svh

//============================================================
// FOUR-SP MODE (binary32 x4) special-type detection tests
// Mode select: s_i_ctrl[1:0] = 2'b10
// Lane mapping (MSB -> LSB):
//   Lane A (float_type_a): s_i_float[127]      sign
//                          s_i_float[126:119]  exp[7:0]
//                          s_i_float[118:96]   frac[22:0]
//
//   Lane B (float_type_b): s_i_float[95]       sign
//                          s_i_float[94:87]    exp[7:0]
//                          s_i_float[86:64]    frac[22:0]
//
//   Lane C (float_type_c): s_i_float[63]       sign
//                          s_i_float[62:55]    exp[7:0]
//                          s_i_float[54:32]    frac[22:0]
//
//   Lane D (float_type_d): s_i_float[31]       sign
//                          s_i_float[30:23]    exp[7:0]
//                          s_i_float[22:0]     frac[22:0]
//============================================================

// Zeros with mixed signs (still ZERO)
`SVTEST(four_sp_mode_0)
    s_i_ctrl[1:0] = 2'b10;

    // Lane A: +0
    s_i_float[127]      = '0;  s_i_float[126:119] = 8'd0;  s_i_float[118:96] = '0;
    // Lane B: -0
    s_i_float[95]       = '1;  s_i_float[94:87]   = 8'd0;  s_i_float[86:64]  = '0;
    // Lane C: +0
    s_i_float[63]       = '0;  s_i_float[62:55]   = 8'd0;  s_i_float[54:32]  = '0;
    // Lane D: -0
    s_i_float[31]       = '1;  s_i_float[30:23]   = 8'd0;  s_i_float[22:0]   = '0;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, ZERO)
`SVTEST_END

// +INF / -INF / +INF / -INF
`SVTEST(four_sp_mode_1)
    s_i_ctrl[1:0] = 2'b10;

    // Lane A: +INF
    s_i_float[127]      = '0;  s_i_float[126:119] = 8'hFF; s_i_float[118:96] = '0;
    // Lane B: -INF
    s_i_float[95]       = '1;  s_i_float[94:87]   = 8'hFF; s_i_float[86:64]  = '0;
    // Lane C: +INF
    s_i_float[63]       = '0;  s_i_float[62:55]   = 8'hFF; s_i_float[54:32]  = '0;
    // Lane D: -INF
    s_i_float[31]       = '1;  s_i_float[30:23]   = 8'hFF; s_i_float[22:0]   = '0;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, POS_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NEG_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, POS_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NEG_INF)
`SVTEST_END

// NaN / NaN / NaN / NaN
`SVTEST(four_sp_mode_2)
    s_i_ctrl[1:0] = 2'b10;

    // Lane A: NaN
    s_i_float[127]      = '0;  s_i_float[126:119] = 8'hFF; s_i_float[118:96] = 'd5;
    // Lane B: NaN
    s_i_float[95]       = '1;  s_i_float[94:87]   = 8'hFF; s_i_float[86:64]  = 'd7;
    // Lane C: NaN
    s_i_float[63]       = '0;  s_i_float[62:55]   = 8'hFF; s_i_float[54:32]  = 'd9;
    // Lane D: NaN
    s_i_float[31]       = '1;  s_i_float[30:23]   = 8'hFF; s_i_float[22:0]   = 'd11;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NAN)
`SVTEST_END

// +Den / -Den / +Den / -Den  (denormals: exp=0, frac!=0)
`SVTEST(four_sp_mode_3)
    s_i_ctrl[1:0] = 2'b10;

    // Lane A: +denormal
    s_i_float[127]      = '0;  s_i_float[126:119] = 8'd0;  s_i_float[118:96] = 'd3;
    // Lane B: -denormal
    s_i_float[95]       = '1;  s_i_float[94:87]   = 8'd0;  s_i_float[86:64]  = 'd5;
    // Lane C: +denormal
    s_i_float[63]       = '0;  s_i_float[62:55]   = 8'd0;  s_i_float[54:32]  = 'd7;
    // Lane D: -denormal
    s_i_float[31]       = '1;  s_i_float[30:23]   = 8'd0;  s_i_float[22:0]   = 'd9;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, POS_DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NEG_DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, POS_DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NEG_DENORMAL)
`SVTEST_END

// Normal(+)/Normal(+)/Normal(-)/Normal(-)
`SVTEST(four_sp_mode_4)
    s_i_ctrl[1:0] = 2'b10;

    // Lane A: normal (+)
    s_i_float[127]      = '0;  s_i_float[126:119] = 8'd10;  s_i_float[118:96] = 'd21;
    // Lane B: normal (+)
    s_i_float[95]       = '0;  s_i_float[94:87]   = 8'd127; s_i_float[86:64]  = 'd37;
    // Lane C: normal (-)
    s_i_float[63]       = '1;  s_i_float[62:55]   = 8'd1;   s_i_float[54:32]  = 'd55;
    // Lane D: normal (-)
    s_i_float[31]       = '1;  s_i_float[30:23]   = 8'd200; s_i_float[22:0]   = 'd89;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NORMAL)
`SVTEST_END

// Mixed:  NaN / -INF / +Den / Normal(-)
`SVTEST(four_sp_mode_5)
    s_i_ctrl[1:0] = 2'b10;

    // Lane A: NaN
    s_i_float[127]      = '1;  s_i_float[126:119] = 8'hFF; s_i_float[118:96] = 'd13;

    // Lane B: -INF
    s_i_float[95]       = '1;  s_i_float[94:87]   = 8'hFF; s_i_float[86:64]  = '0;

    // Lane C: +denormal
    s_i_float[63]       = '0;  s_i_float[62:55]   = 8'd0;  s_i_float[54:32]  = 'd1;

    // Lane D: normal (-)
    s_i_float[31]       = '1;  s_i_float[30:23]   = 8'd80; s_i_float[22:0]   = 'd777;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NEG_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, POS_DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NORMAL)
`SVTEST_END

// Edge: Normal near max exp / zeros elsewhere
`SVTEST(four_sp_mode_6)
    s_i_ctrl[1:0] = 2'b10;

    // Lane A: normal near max exponent (0xFE)
    s_i_float[127]      = '1;
    s_i_float[126:119]  = 8'hFE;
    s_i_float[118:96]   = 'd1234;

    // Lane B: +0
    s_i_float[95]       = '0;  s_i_float[94:87]   = 8'd0;  s_i_float[86:64]  = '0;
    // Lane C: +0
    s_i_float[63]       = '0;  s_i_float[62:55]   = 8'd0;  s_i_float[54:32]  = '0;
    // Lane D: +0
    s_i_float[31]       = '0;  s_i_float[30:23]   = 8'd0;  s_i_float[22:0]   = '0;

    wait_n_ticks(`LATENCY);
    
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, ZERO)
`SVTEST_END
