// This is to make sure four subword mode special type detection works
`SVTEST(four_sp_mode_special_type_test_0)
    s_i_float[126:0] = '0;
    #1;
    `FAIL_UNLESS_EQUAL(s_o_float_type_a, ZERO)
`SVTEST_END