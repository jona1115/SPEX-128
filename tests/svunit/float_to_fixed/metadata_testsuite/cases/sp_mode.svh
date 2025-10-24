`SVTEST(sp_mode_test_0)
    s_i_ctrl[1:0] = 2'b00;
    $display(">>> s_o_metadata.sp_mode=0x%x", s_o_metadata.sp_mode);
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, SINGLE_MODE)
`SVTEST_END

`SVTEST(sp_mode_test_1)
    s_i_ctrl[1:0] = 2'b01;
    $display(">>> s_o_metadata.sp_mode=0x%x", s_o_metadata.sp_mode);
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, TWO_SP_MODE)
`SVTEST_END

`SVTEST(sp_mode_test_2)
    s_i_ctrl[1:0] = 2'b10;
    $display(">>> s_o_metadata.sp_mode=0x%x", s_o_metadata.sp_mode);
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, FOUR_SP_MODE)
`SVTEST_END

`SVTEST(sp_mode_test_3)
    s_i_ctrl[3:0] = 4'b1111;
    s_i_float = 'd1115;
    $display(">>> s_o_fixed=%d", s_o_fixed);
    $display(">>> s_o_metadata=0x%x", s_o_metadata);
    $display(">>> s_o_metadata.sp_mode=0x%x", s_o_metadata.sp_mode);
    #5;
    `FAIL_UNLESS_EQUAL(s_o_metadata.sp_mode, INVALID_SP_MODE)
`SVTEST_END