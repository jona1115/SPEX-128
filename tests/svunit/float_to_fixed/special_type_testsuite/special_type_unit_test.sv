`include "svunit_defines.svh"

module special_type_unit_test;
    import svunit_pkg::svunit_testcase;
    import float_flag_pkg::*;

    string name = "float_to_fixed_ut";
    svunit_testcase svunit_ut;

    // DUT IO
    logic           s_i_clk;
    logic [127:0]   s_i_float;
    logic [3:0]     s_i_ctrl;
    logic [127:0]   s_o_fixed;
    logic [2:0]     s_o_float_type_a,
                    s_o_float_type_b,
                    s_o_float_type_c,
                    s_o_float_type_d;

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    float_to_fixed my_float_to_fixed(
        .i_clk(s_i_clk),
        .i_float(s_i_float),
        .i_ctrl(s_i_ctrl),
        .o_fixed(s_o_fixed),
        .o_float_type_a(s_o_float_type_a),
        .o_float_type_b(s_o_float_type_b),
        .o_float_type_c(s_o_float_type_c),
        .o_float_type_d(s_o_float_type_d)
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
        s_i_clk = '0;
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

        `include "cases/single_mode.svh"
        // `include "cases/two_sp_mode.svh"
        // `include "cases/four_sp_mode.svh"

    `SVUNIT_TESTS_END

endmodule
