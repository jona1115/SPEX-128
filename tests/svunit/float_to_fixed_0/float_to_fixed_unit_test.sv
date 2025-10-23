`include "svunit_defines.svh"

module float_to_fixed_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "float_to_fixed_ut";
    svunit_testcase svunit_ut;

    // DUT IO
    logic [127:0]     s_i_float;
    logic [3:0]       s_i_ctrl;
    logic [127:0]     s_o_fixed;

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    float_to_fixed my_float_to_fixed(
        .i_float(s_i_float),
        .i_ctrl(s_i_ctrl),
        .o_fixed(s_o_fixed)
    );


    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();
        /* Place Setup Code Here */
        s_i_float = '0;
        s_i_ctrl = '0;
        s_o_fixed = '0;
    endtask


    //===================================
    // Here we deconstruct anything we 
    // need after running the Unit Tests
    //===================================
    task teardown();
        svunit_ut.teardown();
        /* Place Teardown Code Here */

    endtask


    //===================================
    // All tests are defined between the
    // SVUNIT_TESTS_BEGIN/END macros
    //
    // Each individual test must be
    // defined between `SVTEST(_NAME_)
    // `SVTEST_END
    //
    // i.e.
    //     `SVTEST(mytest)
    //         <test code>
    //     `SVTEST_END
    //===================================
    `SVUNIT_TESTS_BEGIN

        `SVTEST(passthrough_test0)
            s_i_float = 128'hDEADBEEF;
            // $display("s_i_float:%x", s_i_float);
            #1;
            `FAIL_UNLESS_EQUAL(s_o_fixed, s_i_float)
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
