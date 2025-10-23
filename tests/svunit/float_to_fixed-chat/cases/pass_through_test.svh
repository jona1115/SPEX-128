`SVTEST(passthrough_test0)
    s_i_float = 128'hDEADBEEF;
    // $display("s_i_float:%x", s_i_float);
    #1;
    `FAIL_UNLESS_EQUAL(s_o_fixed, s_i_float)
`SVTEST_END