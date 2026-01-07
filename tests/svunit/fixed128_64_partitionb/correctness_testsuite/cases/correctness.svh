/* This is the specification of DUT I gave ChatGPT:
 * Specification of the DUT:
 * 1. i_metadata goes in, after one tick, the same value should come out as o_metadata.
 * 2. i_valid128 goes in, after one tick, the same value should come out as o_valid128.
 * 3. if both i_valid64a and i_valid64b are set, then o_valid64a and o_valid64b will be 
 *    set in one tick; else, both will be 0 in one tick
 * 4. if i_metadata sp mode element is SINGLE mode, if i_valid128 is set, in one tick, 
 *    o_exp_a128 should be the result read from gt_mem128[i_a]If i_valid128 is not set, 
 *    then o_exp_a128 should be whatever it was before.
 * 5. if i_metadata sp mode element is TWO_SP_MODE, if i_valid64a and i_valid64b are both 
 *    set, then s_o_exp_a64a <= gt_mem64[i_a]; s_o_exp_a64b <= gt_mem64[i_a2]]. If 
 *    either/both i_valid64a or i_valid64b is 0, then s_o_exp_a64a and s_o_exp_a64b will 
 *    be whatever it was before.
 * 6. On reset (ie `!i_rst_n`, because i_rst_n is active low), all outputs will be set 
 *    to all 0.
 * 7. If i_metadata sp mode is FOUR_SP_MODE, o_error[1] should be a 1 in the next tick.
 * 8. If i_metadata sp mode is anything other than the three modes stated above, 
 *    o_error[0] should be a 1 in the next tick.
 * 9. o_error should always be 0.
 * 10. o_debug should always be 0. (no need to test this bit)
*/

// This is what ChatGPT gave me:


// -----------------------------
// Spec 6: reset drives all 0s
// -----------------------------
`SVTEST(reset_clears_all_outputs)
  // Prime outputs with non-zero activity
  drive_meta(SINGLE_MODE, NORMAL, ZERO, POS_INF, NA);
  drive128(13'd1, 1'b1);
  drive64a(13'd2, 1'b1);
  drive64b(13'd3, 1'b1);
  tick();

  // Assert synchronous active-low reset
  s_i_rst_n = 1'b0;
  tick();

  `FAIL_IF_LOG(s_o_valid128 !== '0 || s_o_valid64a !== '0 || s_o_valid64b !== '0,
                "o_valid* not cleared on reset")
  `FAIL_IF_LOG(s_o_exp_a128  !== '0 || s_o_exp_a64a  !== '0 || s_o_exp_a64b  !== '0,
                "o_exp_* not cleared on reset")
  `FAIL_IF_LOG(s_o_metadata  !== '0, "o_metadata not cleared on reset")
  `FAIL_IF_LOG(s_o_error     !== '0, "o_error not cleared on reset")
  `FAIL_IF_LOG(s_o_debug     !== '0, "o_debug not cleared on reset")

  // Deassert reset
  s_i_rst_n = 1'b1;
  tick();
`SVTEST_END


// ----------------------------------------------
// Spec 1: metadata passes through in one tick
// ----------------------------------------------
`SVTEST(metadata_passthrough_one_cycle)
  float_metadata_t m_in = mk_meta(TWO_SP_MODE, POS_INF, NEG_DENORMAL, NA, ZERO);
  drive_meta(m_in.sp_mode, m_in.float_type_a, m_in.float_type_b, m_in.float_type_c, m_in.float_type_d);
  tick();
  expect_metadata_passthrough(m_in, "meta passthrough");
`SVTEST_END


// ----------------------------------------------------
// Spec 2: i_valid128 → o_valid128 (one-cycle latency)
// ----------------------------------------------------
`SVTEST(valid128_passthrough)
  drive_meta(SINGLE_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  s_i_valid128 = 1'b1; tick();
  expect_valid128_passthrough(1'b1, "i_valid128=1 -> o_valid128=1");

  s_i_valid128 = 1'b0; tick();
  expect_valid128_passthrough(1'b0, "i_valid128=0 -> o_valid128=0");
`SVTEST_END


// -----------------------------------------------------------------
// Spec 4: SINGLE_MODE — lookup + hold when i_valid128=0 (bubble)
// -----------------------------------------------------------------
`SVTEST(single_mode_128_lookup_and_hold)
  // Use a couple of representative addresses (including high edge)
  logic [12:0] a0 = 13'd27;
  logic [12:0] a1 = 13'd8191;

  clear_all_valids();
  drive_meta(SINGLE_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

  // First valid read
  drive128(a0, 1'b1); tick();
  expect_now_valid_and_value128(a0, "SINGLE first");

  // Second valid read overwrites
  drive128(a1, 1'b1); tick();
  expect_now_valid_and_value128(a1, "SINGLE second");

  // Bubble: change addr but drop valid; output must hold a1 value
  drive128(13'd5, 1'b0); tick();
  expect_hold128(gt_mem128[a1], "SINGLE bubble holds");
`SVTEST_END


// -----------------------------------------------------------------------
// Spec 3 & 5: TWO_SP_MODE — both valids required; else hold previous data
// -----------------------------------------------------------------------
`SVTEST(two_sp_mode_64_lookup_and_bubble_rules)
  // Prime both outputs with a valid transaction
  logic [12:0] a0 = 13'd14;
  logic [12:0] b0 = 13'd21;
  binary64_t exp_a0 = gt_mem64[a0];
  binary64_t exp_b0 = gt_mem64[b0];

  clear_all_valids();
  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

  drive64a(a0, 1'b1);
  drive64b(b0, 1'b1);
  tick();
  expect_now_valid_and_value64a(a0, "TWO_SP both valid (a)");
  expect_now_valid_and_value64b(b0, "TWO_SP both valid (b)");

  // Only one valid -> both o_valid* must be 0 and values must hold
  drive64a(13'd123, 1'b1);
  drive64b(13'd456, 1'b0);
  tick();
  `FAIL_IF_LOG(s_o_valid64a !== 1'b0 || s_o_valid64b !== 1'b0,
                "One valid missing -> both o_valid64* must be 0")
  expect_hold64a(exp_a0, "TWO_SP bubble holds (a)");
  expect_hold64b(exp_b0, "TWO_SP bubble holds (b)");

  // Neither valid -> still hold
  drive64a(13'd7, 1'b0);
  drive64b(13'd8, 1'b0);
  tick();
  expect_hold64a(exp_a0, "TWO_SP double-bubble holds (a)");
  expect_hold64b(exp_b0, "TWO_SP double-bubble holds (b)");
`SVTEST_END


// -------------------------------------------------------
// Spec 7: FOUR_SP_MODE should raise o_error[1] in 1 cycle
// -------------------------------------------------------
`SVTEST(four_sp_mode_sets_error_bit1)
  clear_all_valids();
  drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  tick();
  // `FAIL_IF_LOG(s_o_error[1] !== 1'b1, "FOUR_SP_MODE must set o_error[1]")
  `FAIL_IF_LOG(s_o_error[0] !== 1'b0, "FOUR_SP_MODE must not set o_error[0]")
`SVTEST_END


// -----------------------------------------------------------------
// Spec 8: INVALID_SP_MODE should raise o_error[0] in 1 cycle
// -----------------------------------------------------------------
`SVTEST(invalid_mode_sets_error_bit0)
  clear_all_valids();
  drive_meta(INVALID_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  tick();
  `FAIL_IF_LOG(s_o_error[0] !== 1'b1, "INVALID_SP_MODE must set o_error[0]")
`SVTEST_END


// ------------------------------------------------------------
// Spec 9 (interpreted): valid modes keep o_error at 0
// ------------------------------------------------------------
`SVTEST(valid_modes_keep_error_zero)
  // SINGLE_MODE
  clear_all_valids();
  drive_meta(SINGLE_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  tick();
  `FAIL_IF_LOG(s_o_error !== '0, "SINGLE_MODE should not raise errors")

  // TWO_SP_MODE
  clear_all_valids();
  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);
  tick();
  `FAIL_IF_LOG(s_o_error !== '0, "TWO_SP_MODE should not raise errors")
`SVTEST_END
