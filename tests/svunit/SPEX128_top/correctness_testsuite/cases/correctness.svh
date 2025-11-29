// Handwritten tests:
// `SVTEST(handwritten_sanity_correctness_test_0)
//   logic [127:0] expected = 128'h3fffa61298e1e069bc972dfefab6df34; // 1.6487212707001281468486507878141635764

//   s_i_x     = 128'h3ffe0000000000000000000000000000; // 0.5
//   s_i_ctrl  = 4'b0000; // single mode

//   wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

//   $display(">>>>> s_o_exp_x=0x%X", s_o_exp_x);
//   `FAIL_UNLESS(s_o_exp_x === expected)
// `SVTEST_END

`SVTEST(handwritten_sanity_correctness_test_1)
  logic [127:0] expected = 128'h402899670853bf4bb876f5ead09f48e8; // 3516740446078.5915669155853082529447639
                           // 0x402899670853bf4bb876f5ead09f48a5
  s_i_x     = 128'h4003ce3786259f7d0292051588915546; // 28.888555666890000000000000000000000887
  s_i_ctrl  = 4'b0000; // single mode

  wait_n_ticks(2+1+5*3/*idk why the +3*/+3);

  $display(">>>>> s_o_exp_x=0x%X", s_o_exp_x);
  `FAIL_UNLESS(s_o_exp_x === expected)
`SVTEST_END



/* This is the specification of DUT I gave ChatGPT:
 * todo
*/

// This is what ChatGPT gave me:
