// Handwritten tests:
`SVTEST(handwritten_sanity_correctness_test_0)
  // logic [127:0] expected = 128'h4000c000000000000000000000000000; // 3.5

  // s_i_in_anikin = 128'h3ffe0000000000000000000000000000; // 0.5
  // s_i_in_force  = 128'h4001c000000000000000000000000000; // 7.0

  // wait_n_ticks(5);

  // `FAIL_UNLESS(s_o_out_jedi === expected)
`SVTEST_END

`SVTEST(handwritten_sanity_correctness_test_1)
  // logic [127:0] expected = 128'hc0076ee894ea7ad6392654fa263a57be; // -366.90852227686830087000000000000000737

  // s_i_in_anikin = 128'hbff7316088898481372ac2290d730dc7; // -0.0046596844999999999999999999999999997928
  // s_i_in_force  = 128'h400f339510c28a7e9e96838f970c4b93; // 78741.065468460000000000000000000002343

  // wait_n_ticks(5);

  // `FAIL_UNLESS(s_o_out_jedi === expected)
`SVTEST_END



/* This is the specification of DUT I gave ChatGPT:
 * 1. When i_metadata.sp_mode is SINGLE_MODE: o_out_jedi = (in_128_anikin * in_128_force) 
 *    in 5 clock cycles (ticks) if i_valid128_anikin and i_valid128_force are 1'b1. If any of the 
 *    valid bit is cleared, in 5 ticks, no new output will be generated for that lane.
 * 2. When i_metadata.sp_mode is TWO_SP_MODE mode: o_out_jedi = {(in_64a_anikin * in_64a_force), 
 *    (in_64b_anikin * in_64b_force)} in 5 clock cycles (ticks) if i_valid64a_anikin, i_valid64a_force, 
 *    i_valid64b_anikin, and i_valid64b_force are 1'b1. If any of the valid bit is cleared, in 5 ticks,
 *    no new output will be generated for that lane.
 * 3. When i_metadata.sp_mode is FOUR_SP_MODE mode: o_out_jedi = {(in_32a_anikin * in_32a_force), 
 *    (in_32b_anikin * in_32b_force), (in_32c_anikin * in_32c_force), (in_32d_anikin * in_32d_force)} 
 *    in 5 clock cycles (ticks) if , i_valid32a_anikin, i_valid32a_force, i_valid32b_anikin, 
 *    i_valid32b_force, i_valid32c_anikin, i_valid32c_force, i_valid32d_anikin, and i_valid32d_force are 
 *    1'b1. If any of the valid bit is cleared, in 5 ticks, no new output will be generated for that lane.
 * 4. Dealing with special types: As per IEEE-754, there are subnormal types in floats. In either 
 *    of the three modes, if any of the lanes is a 0, the output is a zero too after 5 ticks; if any 
 *    of the lanes is a POS_INF, output of that lane is POS_INF too after 5 ticks; if any of the lanes is 
 *    a NEG_INF, output of that lane is NEG_INF too after 5 ticks; if any of the lanes is a NaN, output of 
 *    that lane is NaN too after 5 ticks; however, if any of the lanes is POS or NEG denormal, the DUT 
 *    treats it as zero.
 * 5. o_valid128_jedi will be set after 5 ticks iff i_valid128_anikin and i_valid128_force are set.
 * 6. o_valid64a_jedi will be set after 5 ticks iff i_valid64a_anikin and i_valid64a_force are set; 
 *    o_valid64b_jedi will be set after 5 ticks iff i_valid64b_anikin and i_valid64b_force are set, 
 * 7. o_valid32a_jedi will be set after 5 ticks iff i_valid32a_anikin and i_valid32a_force are set; 
 *    o_valid32b_jedi will be set after 5 ticks iff i_valid32b_anikin and i_valid32b_force are set; 
 *    o_valid32c_jedi will be set after 5 ticks iff i_valid32c_anikin and i_valid32c_force are set; 
 *    o_valid32d_jedi will be set after 5 ticks iff i_valid32d_anikin and i_valid32d_force are set.
 * 8. o_metadata.sp_mode should be the same as i_metadata.sp_mode after 5 ticks.
 * 9. Any bits of o_error should never be set, having any bits set means an assertion error has 
 *    happened.
 * 10. o_debug should not be tested.
*/

// This is what ChatGPT gave me:
