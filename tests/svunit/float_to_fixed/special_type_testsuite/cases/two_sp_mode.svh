// This is to make sure two subword mode special type detection works
`SVTEST(two_sp_mode_special_type_test_0)
    s_i_float[126:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, ZERO)
`SVTEST_END
`SVTEST(two_sp_mode_special_type_test_1)
    s_i_float[126:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_b, ZERO)
`SVTEST_END

`SVTEST(two_sp_mode_special_type_test_2)
    s_i_float[126:116] = 'h5; // Not 0
    // $display("s_i_float=%x", s_i_float);
    #1;
    `FAIL_IF(s_o_float_type_a > NORMAL) // assert a is NORMAL
`SVTEST_END
`SVTEST(two_sp_mode_special_type_test_3)
    s_i_float[62:52] = 'h5; // Not 0
    // $display("s_i_float=%x", s_i_float);
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_b, NORMAL) // assert b is NORMAL
`SVTEST_END