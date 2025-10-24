`SVTEST(sp_mode_test_0)
    s_i_ctrl[1:0] = 2'b00;
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, SINGLE_MODE)
`SVTEST_END

`SVTEST(sp_mode_test_1)
    s_i_ctrl[1:0] = 2'b01;
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, TWO_SP_MODE)
`SVTEST_END

`SVTEST(sp_mode_test_2)
    s_i_ctrl[1:0] = 2'b10;
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, FOUR_SP_MODE)
`SVTEST_END

`SVTEST(sp_mode_test_3)
    s_i_ctrl[3:0] = 4'b1111;
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, INVALID_SP_MODE)
`SVTEST_END