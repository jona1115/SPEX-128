// // This is to make sure four subword mode special type detection works
// `SVTEST(four_sp_mode_special_type_test_0)
//     s_i_float[126:0] = '0;
//     #1;
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

// All +0
`SVTEST(four_mode_0)
    s_i_ctrl[1:0] = 2'b10;

    // D
    s_i_float[127]     = '0;
    s_i_float[126:119] = 8'd0;
    s_i_float[118:96]  = '0;

    // C
    s_i_float[95]      = '0;
    s_i_float[94:87]   = 8'd0;
    s_i_float[86:64]   = '0;

    // B
    s_i_float[63]      = '0;
    s_i_float[62:55]   = 8'd0;
    s_i_float[54:32]   = '0;

    // A
    s_i_float[31]      = '0;
    s_i_float[30:23]   = 8'd0;
    s_i_float[22:0]    = '0;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, ZERO)
`SVTEST_END

// ±0 pattern
`SVTEST(four_mode_1)
    s_i_ctrl[1:0] = 2'b10;

    // D -0
    s_i_float[127]     = '1;
    s_i_float[126:119] = 8'd0;
    s_i_float[118:96]  = '0;

    // C +0
    s_i_float[95]      = '0;
    s_i_float[94:87]   = 8'd0;
    s_i_float[86:64]   = '0;

    // B -0
    s_i_float[63]      = '1;
    s_i_float[62:55]   = 8'd0;
    s_i_float[54:32]   = '0;

    // A +0
    s_i_float[31]      = '0;
    s_i_float[30:23]   = 8'd0;
    s_i_float[22:0]    = '0;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, ZERO)
`SVTEST_END

// INF mix
`SVTEST(four_mode_2)
    s_i_ctrl[1:0] = 2'b10;

    // D -inf
    s_i_float[127]     = '1;
    s_i_float[126:119] = 8'hFF;
    s_i_float[118:96]  = '0;

    // C +inf
    s_i_float[95]      = '0;
    s_i_float[94:87]   = 8'hFF;
    s_i_float[86:64]   = '0;

    // B -inf
    s_i_float[63]      = '1;
    s_i_float[62:55]   = 8'hFF;
    s_i_float[54:32]   = '0;

    // A +inf
    s_i_float[31]      = '0;
    s_i_float[30:23]   = 8'hFF;
    s_i_float[22:0]    = '0;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, POS_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NEG_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, POS_INF)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NEG_INF)
`SVTEST_END

// NaNs
`SVTEST(four_mode_3)
    s_i_ctrl[1:0] = 2'b10;

    // D NaN
    s_i_float[127]     = '0;
    s_i_float[126:119] = 8'hFF;
    s_i_float[118:96]  = 23'd1;

    // C NaN
    s_i_float[95]      = '1;
    s_i_float[94:87]   = 8'hFF;
    s_i_float[86:64]   = 23'd7;

    // B NaN
    s_i_float[63]      = '0;
    s_i_float[62:55]   = 8'hFF;
    s_i_float[54:32]   = 23'd9;

    // A NaN
    s_i_float[31]      = '1;
    s_i_float[30:23]   = 8'hFF;
    s_i_float[22:0]    = 23'd5;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NAN)
`SVTEST_END

// Denormals
`SVTEST(four_mode_4)
    s_i_ctrl[1:0] = 2'b10;

    // D denorm
    s_i_float[127]     = '1;
    s_i_float[126:119] = 8'd0;
    s_i_float[118:96]  = 23'd3;

    // C denorm
    s_i_float[95]      = '0;
    s_i_float[94:87]   = 8'd0;
    s_i_float[86:64]   = 23'd11;

    // B denorm
    s_i_float[63]      = '1;
    s_i_float[62:55]   = 8'd0;
    s_i_float[54:32]   = 23'd21;

    // A denorm
    s_i_float[31]      = '0;
    s_i_float[30:23]   = 8'd0;
    s_i_float[22:0]    = 23'd1;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, DENORMAL)
`SVTEST_END

// NORMALs (moderate)
`SVTEST(four_mode_5)
    s_i_ctrl[1:0] = 2'b10;

    // D normal
    s_i_float[127]     = '1;
    s_i_float[126:119] = 8'd10;
    s_i_float[118:96]  = 23'd5;

    // C normal
    s_i_float[95]      = '0;
    s_i_float[94:87]   = 8'd12;
    s_i_float[86:64]   = 23'd7;

    // B normal
    s_i_float[63]      = '1;
    s_i_float[62:55]   = 8'd40;
    s_i_float[54:32]   = 23'd12345;

    // A normal
    s_i_float[31]      = '0;
    s_i_float[30:23]   = 8'd8;
    s_i_float[22:0]    = 23'd99;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NORMAL)
`SVTEST_END

// NORMAL near max exponent (FE != FF)
`SVTEST(four_mode_6)
    s_i_ctrl[1:0] = 2'b10;

    // D max-normal
    s_i_float[127]     = '1;
    s_i_float[126:119] = 8'hFE;
    s_i_float[118:96]  = 23'd1;

    // C max-normal
    s_i_float[95]      = '0;
    s_i_float[94:87]   = 8'hFE;
    s_i_float[86:64]   = 23'd7777;

    // B max-normal
    s_i_float[63]      = '1;
    s_i_float[62:55]   = 8'hFE;
    s_i_float[54:32]   = 23'd8324;

    // A max-normal
    s_i_float[31]      = '0;
    s_i_float[30:23]   = 8'hFE;
    s_i_float[22:0]    = 23'd42;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, NORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, NORMAL)
`SVTEST_END

// Mixed: A=NaN, B=-0, C=denorm, D=+inf
`SVTEST(four_mode_7)
    s_i_ctrl[1:0] = 2'b10;

    // D +inf
    s_i_float[127]     = '0;
    s_i_float[126:119] = 8'hFF;
    s_i_float[118:96]  = '0;

    // C denorm
    s_i_float[95]      = '0;
    s_i_float[94:87]   = 8'd0;
    s_i_float[86:64]   = 23'd3;

    // B -0
    s_i_float[63]      = '1;
    s_i_float[62:55]   = 8'd0;
    s_i_float[54:32]   = '0;

    // A NaN
    s_i_float[31]      = '1;
    s_i_float[30:23]   = 8'hFF;
    s_i_float[22:0]    = 23'd9;

    #1;
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_a, NAN)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_b, ZERO)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_c, DENORMAL)
    `FAIL_UNLESS_EQUAL(s_o_metadata.float_type_d, POS_INF)
`SVTEST_END
