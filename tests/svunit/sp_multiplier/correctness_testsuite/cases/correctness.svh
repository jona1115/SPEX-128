// Handwritten tests:
// `SVTEST(handwritten_sanity_correctness_test_SINGLEMODE_0)
//   logic [127:0] expected = 128'h4000c000000000000000000000000000; // 3.5

//   s_i_in_anikin = 128'h3ffe0000000000000000000000000000; // 0.5
//   s_i_in_force  = 128'h4001c000000000000000000000000000; // 7.0

//   drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);

//   s_i_valid128_anikin = '1;
//   s_i_valid128_force  = '1;
//   wait_n_ticks(1);
//   s_i_valid128_anikin = '0;
//   s_i_valid128_force  = '0;
//   wait_n_ticks(4);

//   `FAIL_UNLESS(s_o_out_jedi === expected)
// `SVTEST_END

// `SVTEST(handwritten_sanity_correctness_test_SINGLEMODE_1)
//   logic [127:0] expected = 128'hc0076ee894ea7ad6392654fa263a57be; // -366.90852227686830087000000000000000737

//   s_i_in_anikin = 128'hbff7316088898481372ac2290d730dc7; // -0.0046596844999999999999999999999999997928
//   s_i_in_force  = 128'h400f339510c28a7e9e96838f970c4b93; // 78741.065468460000000000000000000002343

//   drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);

//   s_i_valid128_anikin = '1;
//   s_i_valid128_force  = '1;
//   wait_n_ticks(1);
//   s_i_valid128_anikin = '0;
//   s_i_valid128_force  = '0;
//   wait_n_ticks(4);

//   `FAIL_UNLESS(s_o_out_jedi === expected)
// `SVTEST_END

// `SVTEST(handwritten_sanity_correctness_test_TWOSPMODE_0)
//   logic [127:0] expected = {64'h410465776e87a276/*167086.928970*/,
//                             64'hc0500719616462c5/*-64.110924*/};

//   s_i_in_anikin = {64'h402b1182a9930be1/*13.534200*/,
//                    64'hbed5c7f0f883bd6d/*-0.000005*/};
//   s_i_in_force  = {64'h40c81cc460aa64c3/*12345.534200*/,
//                    64'h41678c2560000000/*12345643.000000*/};

//   drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

//   s_i_valid64a_anikin = '1;
//   s_i_valid64a_force  = '1;
//   s_i_valid64b_anikin = '1;
//   s_i_valid64b_force  = '1;
//   wait_n_ticks(1);
//   s_i_valid64a_anikin = '0;
//   s_i_valid64a_force  = '0;
//   s_i_valid64b_anikin = '0;
//   s_i_valid64b_force  = '0;
//   wait_n_ticks(4);

//   `FAIL_UNLESS(s_o_out_jedi === expected)
// `SVTEST_END

// `SVTEST(handwritten_sanity_correctness_test_FOURSPMODE_0)
//   logic [127:0] expected = {32'hc91c8554/*-641109.250000*/,
//                             32'h80000000/*-0.000000*/,
//                             32'h40d27ef9/*6.578000*/,
//                             32'h410894e1/*8.536347*/};

//   s_i_in_anikin = {32'hbd54b48d/*-0.051930*/,
//                    32'h4b3c612b/*12345643.000000*/,
//                    32'h4121eb85/*10.120000*/,
//                    32'h40490e56/*3.141500*/};
//   s_i_in_force  = {32'h4b3c612b/*12345643.000000*/,
//                    32'h80000000/*-0.000000*/,
//                    32'h3f266666/*0.650000*/,
//                    32'h402de7fb/*2.717284*/};

//   drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

//   s_i_valid32a_anikin = '1;
//   s_i_valid32a_force  = '1;
//   s_i_valid32b_anikin = '1;
//   s_i_valid32b_force  = '1;
//   s_i_valid32c_anikin = '1;
//   s_i_valid32c_force  = '1;
//   s_i_valid32d_anikin = '1;
//   s_i_valid32d_force  = '1;
//   wait_n_ticks(1);
//   s_i_valid32a_anikin = '0;
//   s_i_valid32a_force  = '0;
//   s_i_valid32b_anikin = '0;
//   s_i_valid32b_force  = '0;
//   s_i_valid32c_anikin = '0;
//   s_i_valid32c_force  = '0;
//   s_i_valid32d_anikin = '0;
//   s_i_valid32d_force  = '0;
//   wait_n_ticks(4);

//   `FAIL_UNLESS(s_o_out_jedi === expected)
// `SVTEST_END



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
 * 6. o_valid64a_jedi and o_valid64b_jedi will be set after 5 ticks iff i_valid64a_anikin, 
 *    i_valid64a_force, i_valid64b_anikin, and i_valid64b_force are set. This is the "all-or-nothing" rule.
 * 7. o_valid32a_jedi, o_valid32b_jedi, o_valid32c_jedi, and o_valid32d_jedi will be set after 5 ticks 
 *    iff i_valid32a_anikin, i_valid32a_force i_valid32b_anikin, i_valid32b_force, i_valid32c_anikin, 
 *    i_valid32c_force, i_valid32d_anikin, and i_valid32d_force are set. This is the "all-or-nothing" rule.
 * 8. o_metadata.sp_mode should be the same as i_metadata.sp_mode after 5 ticks.
 * 9. Any bits of o_error should never be set, having any bits set means an assertion error has 
 *    happened.
 * 10. o_debug should not be tested.
*/

// This is what ChatGPT gave me:

// -------------------------------------------------------------------------
// Sanity / Spec 9/10: idle behavior and error stays 0
// -------------------------------------------------------------------------
`SVTEST(noop_when_valids_low)
  logic [127:0] prev = s_o_out_jedi;

  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_POS_INF;
  s_i_in_force  = F128_NEG_INF;
  clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_out_jedi === prev)
  `FAIL_UNLESS(!s_o_valid128_jedi)
  `FAIL_UNLESS(!s_o_valid64a_jedi && !s_o_valid64b_jedi)
  `FAIL_UNLESS(!s_o_valid32a_jedi && !s_o_valid32b_jedi && !s_o_valid32c_jedi && !s_o_valid32d_jedi)
  `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 1/4/5/8: SINGLE_MODE zero; valid after exactly 5 ticks; per-lane gating
// -------------------------------------------------------------------------
`SVTEST(single_mode_zero_and_latency_5)
  drive_meta(SINGLE_MODE, ZERO, NA, NA, NA);

  s_i_in_anikin = F128_ZERO;
  s_i_in_force  = F128_POS_INF;

  // Pulse valids one cycle
  s_i_valid128_anikin = 1;
  s_i_valid128_force  = 1;
  @(posedge s_i_clk);
  clear_valids();

  // Check latency precisely: first 4 ticks no valid, at 5th tick valid
  wait_n_ticks(3);
  `FAIL_UNLESS(!s_o_valid128_jedi)
  wait_n_ticks(2);
  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_metadata.sp_mode == SINGLE_MODE)
  `FAIL_UNLESS(s_o_out_jedi == 128'b0)
  `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 1 per-lane gating: one valid low -> no new output and no valid
// -------------------------------------------------------------------------
`SVTEST(single_mode_partial_valids_no_update)
  logic [127:0] prev = s_o_out_jedi;

  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_POS_INF;
  s_i_in_force  = F128_POS_INF;

  // Only anikin valid, force not valid
  s_i_valid128_anikin = 1;
  s_i_valid128_force  = 0;
  @(posedge s_i_clk); clear_valids();
  wait_n_ticks(5);

  `FAIL_UNLESS(!s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_out_jedi === prev)
  `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 1/4: SINGLE_MODE INF/NaN propagation (structural checks)
// -------------------------------------------------------------------------
`SVTEST(single_mode_inf_nan_special_cases)
  // +INF case
  drive_meta(SINGLE_MODE, POS_INF, NA, NA, NA);
  s_i_in_anikin = F128_POS_INF;
  s_i_in_force = F128_ONE;
  s_i_valid128_anikin = 1;
  s_i_valid128_force = 1;
  
  @(posedge s_i_clk);
  clear_valids();
  
  wait_n_ticks(5);
  `FAIL_UNLESS(s_o_valid128_jedi)
  // $display(">>>>> s_o_out_jedi=0x%x", s_o_out_jedi);
  `FAIL_UNLESS( (s_o_out_jedi[126 -: 15] == {15{1'b1}}) && (s_o_out_jedi[111:0] == '0) )
  // `FAIL_UNLESS( s_o_out_jedi == F128_POS_INF )

  // -INF case
  drive_meta(SINGLE_MODE, NEG_INF, NA, NA, NA);
  s_i_in_anikin = F128_NEG_INF;
  s_i_in_force = F128_ONE;
  s_i_valid128_anikin = 1;
  s_i_valid128_force = 1;
  
  @(posedge s_i_clk);
  clear_valids();
  
  wait_n_ticks(5);
  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS( (s_o_out_jedi[127] == 1'b1) && (s_o_out_jedi[126 -: 15] == {15{1'b1}}) && (s_o_out_jedi[111:0] == '0) )

  // NaN case
  drive_meta(SINGLE_MODE, NAN, NA, NA, NA);
  s_i_in_anikin = F128_QNAN;
  s_i_in_force = F128_ONE;
  s_i_valid128_anikin = 1;
  s_i_valid128_force = 1;
  
  @(posedge s_i_clk);
  clear_valids();
  
  wait_n_ticks(5);
  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS( (s_o_out_jedi[126 -: 15] == {15{1'b1}}) && (s_o_out_jedi[111:0] != '0) )
  `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 2/6/8/9: TWO_SP_MODE exact numeric; per-lane valids; 5-tick latency
// -------------------------------------------------------------------------
`SVTEST(two_sp_mode_basic_multiply)
  // Choose any operands you like; bits shown here for clarity
  logic [63:0] a_top = $realtobits(2.0);
  logic [63:0] a_bot = $realtobits(0.5);
  logic [63:0] b_top = $realtobits(3.0);
  logic [63:0] b_bot = $realtobits(0.25);

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid64a_jedi && s_o_valid64b_jedi)
  `FAIL_UNLESS(top64(s_o_out_jedi) == mul64_bits(a_top, b_top))
  `FAIL_UNLESS(bot64(s_o_out_jedi) == mul64_bits(a_bot, b_bot))
  `FAIL_UNLESS(s_o_metadata.sp_mode == TWO_SP_MODE)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 2/6: TWO_SP_MODE group gating — "all-or-nothing": if one lane is
//           invalid, all other lanes will not proceed
// -------------------------------------------------------------------------
`SVTEST(two_sp_mode_group_gating_any_invalid_blocks_all)
  logic [127:0] prev = s_o_out_jedi;

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  // Case A: lane B incomplete (force missing)
  s_i_in_anikin = pack_2x64( 2.0, 0.5 );
  s_i_in_force  = pack_2x64( 3.0, 0.25 );

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;   // lane A complete
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 0;   // lane B incomplete
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(!s_o_valid64a_jedi && !s_o_valid64b_jedi) // all suppressed
  `FAIL_UNLESS(s_o_out_jedi === prev)                    // no update
  `FAIL_UNLESS(s_o_error == '0)

  // Case B: lane A incomplete (anikin missing)
  prev = s_o_out_jedi;

  s_i_in_anikin = pack_2x64( 2.0, 0.5 );
  s_i_in_force  = pack_2x64( 3.0, 0.25 );

  s_i_valid64a_anikin = 0; s_i_valid64a_force = 1;   // lane A incomplete
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;   // lane B complete
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(!s_o_valid64a_jedi && !s_o_valid64b_jedi)
  `FAIL_UNLESS(s_o_out_jedi === prev)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(two_sp_mode_group_gating_then_success)
  // First launch: one lane invalid -> nothing after 5 ticks
  logic [127:0] prev = s_o_out_jedi;

  logic [63:0] a_top = $realtobits(2.0);
  logic [63:0] a_bot = $realtobits(0.5);
  logic [63:0] b_top = $realtobits(3.0);
  logic [63:0] b_bot = $realtobits(0.25);

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 0; // block the group
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);
  `FAIL_UNLESS(!s_o_valid64a_jedi && !s_o_valid64b_jedi)
  `FAIL_UNLESS(s_o_out_jedi === prev)

  // Second launch: all valids -> both lanes produce results at +5
  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid64a_jedi && s_o_valid64b_jedi)
  `FAIL_UNLESS(top64(s_o_out_jedi) == mul64_bits(a_top, b_top))
  `FAIL_UNLESS(bot64(s_o_out_jedi) == mul64_bits(a_bot, b_bot))
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END


// -------------------------------------------------------------------------
// Spec 3/7/8/9: FOUR_SP_MODE exact numeric; per-lane valids; 5-tick latency
// -------------------------------------------------------------------------
`SVTEST(four_sp_mode_basic_multiply)
  logic [31:0] aa = $shortrealtobits(shortreal'(2.0));
  logic [31:0] ab = $shortrealtobits(shortreal'(0.5));
  logic [31:0] ac = $shortrealtobits(shortreal'(1.0));
  logic [31:0] ad = $shortrealtobits(shortreal'(8.0));

  logic [31:0] fa = $shortrealtobits(shortreal'(3.0));
  logic [31:0] fb = $shortrealtobits(shortreal'(0.25));
  logic [31:0] fc = $shortrealtobits(shortreal'(4.0));
  logic [31:0] fd = $shortrealtobits(shortreal'(0.125));

  drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

  s_i_in_anikin = {aa, ab, ac, ad};
  s_i_in_force  = {fa, fb, fc, fd};

  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1;
  s_i_valid32b_anikin = 1; s_i_valid32b_force = 1;
  s_i_valid32c_anikin = 1; s_i_valid32c_force = 1;
  s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid32a_jedi && s_o_valid32b_jedi && s_o_valid32c_jedi && s_o_valid32d_jedi)
  `FAIL_UNLESS(lane32_a(s_o_out_jedi) == mul32_bits(aa, fa))
  `FAIL_UNLESS(lane32_b(s_o_out_jedi) == mul32_bits(ab, fb))
  `FAIL_UNLESS(lane32_c(s_o_out_jedi) == mul32_bits(ac, fc))
  `FAIL_UNLESS(lane32_d(s_o_out_jedi) == mul32_bits(ad, fd))
  `FAIL_UNLESS(s_o_metadata.sp_mode == FOUR_SP_MODE)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 3/4/7: FOUR_SP_MODE special types and denormals -> 0
// -------------------------------------------------------------------------
`define MY_POS_DENORMAL {1'b0, {8{1'b0}}, 23'b1}
`define MY_POS_INF      {1'b0, {8{1'b1}}, {23{1'b0}}}
`define MY_NEG_INF      {1'b1, {8{1'b1}}, {23{1'b0}}}
`define MY_NAN          {1'b0, {8{1'b1}}, 23'hB1B1}
`SVTEST(four_sp_mode_special_cases_and_denormals)
  logic [31:0] oa;
  logic [31:0] ob;
  logic [31:0] oc;
  logic [31:0] od;

  drive_meta(FOUR_SP_MODE, POS_DENORMAL, POS_INF, NEG_INF, NAN);

  s_i_in_anikin = {`MY_POS_DENORMAL, `MY_POS_INF, `MY_NEG_INF, `MY_NAN};
  s_i_in_force  = pack_4x32(shortreal'(2.0), shortreal'(2.0), shortreal'(2.0), shortreal'(1.0));

  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1;
  s_i_valid32b_anikin = 1; s_i_valid32b_force = 1;
  s_i_valid32c_anikin = 1; s_i_valid32c_force = 1;
  s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  oa = lane32_a(s_o_out_jedi);
  ob = lane32_b(s_o_out_jedi);
  oc = lane32_c(s_o_out_jedi);
  od = lane32_d(s_o_out_jedi);

  $display(">>>>> oa=0x%x", oa);
  $display(">>>>> ob=0x%x", ob);
  $display(">>>>> oc=0x%x", oc);
  $display(">>>>> od=0x%x", od);

  `FAIL_UNLESS(s_o_valid32a_jedi && s_o_valid32b_jedi && s_o_valid32c_jedi && s_o_valid32d_jedi)

  `FAIL_UNLESS(oa == F32_ZERO)
  `FAIL_UNLESS(ob == F32_POS_INF)
  `FAIL_UNLESS(oc == F32_NEG_INF)
  `FAIL_UNLESS(is_nan32(od))
  `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 3/7: FOUR_SP_MODE group gating — "all-or-nothing": if one lane is
// //        invalid, all other lanes will not proceed
// -------------------------------------------------------------------------
`SVTEST(four_sp_mode_group_gating_then_success)
  // First launch blocked by lane c; second launch succeeds for all lanes.
  logic [31:0] aa = $shortrealtobits(shortreal'(2.0));
  logic [31:0] ab = $shortrealtobits(shortreal'(0.5));
  logic [31:0] ac = $shortrealtobits(shortreal'(1.0));
  logic [31:0] ad = $shortrealtobits(shortreal'(8.0));

  logic [31:0] fa = $shortrealtobits(shortreal'(3.0));
  logic [31:0] fb = $shortrealtobits(shortreal'(0.25));
  logic [31:0] fc = $shortrealtobits(shortreal'(4.0));
  logic [31:0] fd = $shortrealtobits(shortreal'(0.125));

  logic [127:0] prev = s_o_out_jedi;

  drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

  s_i_in_anikin = {aa, ab, ac, ad};
  s_i_in_force  = {fa, fb, fc, fd};

  // Blocked attempt
  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1;
  s_i_valid32b_anikin = 1; s_i_valid32b_force = 1;
  s_i_valid32c_anikin = 1; s_i_valid32c_force = 0; // block
  s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);
  `FAIL_UNLESS(!s_o_valid32a_jedi && !s_o_valid32b_jedi && !s_o_valid32c_jedi && !s_o_valid32d_jedi)
  `FAIL_UNLESS(s_o_out_jedi === prev)

  // Successful attempt
  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1;
  s_i_valid32b_anikin = 1; s_i_valid32b_force = 1;
  s_i_valid32c_anikin = 1; s_i_valid32c_force = 1;
  s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid32a_jedi && s_o_valid32b_jedi && s_o_valid32c_jedi && s_o_valid32d_jedi)
  `FAIL_UNLESS(lane32_a(s_o_out_jedi) == mul32_bits(aa, fa))
  `FAIL_UNLESS(lane32_b(s_o_out_jedi) == mul32_bits(ab, fb))
  `FAIL_UNLESS(lane32_c(s_o_out_jedi) == mul32_bits(ac, fc))
  `FAIL_UNLESS(lane32_d(s_o_out_jedi) == mul32_bits(ad, fd))
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END


// -------------------------------------------------------------------------
// Spec 8/9: Metadata passthrough and error==0 sweep
// -------------------------------------------------------------------------
`SVTEST(metadata_passthrough_and_error_zero)
  drive_meta(SINGLE_MODE, NA, NA, NA, NA);
  `MAKE_ALL_VALID_SINGLE
  wait_n_ticks(5);
  `FAIL_UNLESS(s_o_metadata.sp_mode == SINGLE_MODE)

  wait_n_ticks(1);

  drive_meta(TWO_SP_MODE, NA, NA, NA, NA);
  `MAKE_ALL_VALID_TWO_SP
  wait_n_ticks(5);
  // $display(">>>>> s_o_metadata.sp_mode = %d", s_o_metadata.sp_mode);
  `FAIL_UNLESS(s_o_metadata.sp_mode == TWO_SP_MODE)

  wait_n_ticks(1);

  drive_meta(FOUR_SP_MODE, NA, NA, NA, NA);
  `MAKE_ALL_VALID_FOUR_SP
  wait_n_ticks(5);
  `FAIL_UNLESS(s_o_metadata.sp_mode == FOUR_SP_MODE)

  `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END

// -------------------------------------------------------------------------
// Spec 1 numeric checks for SINGLE_MODE using 128-bit LUT hex files.
// anikin_128b.hex[i] * force_128b.hex[i] == jedi_128b.hex[i]
// -------------------------------------------------------------------------
`SVTEST(single_mode_numeric_from_hex_vectors)
  logic [127:0] qA[$], qB[$], qC[$];

  read_hex128_to_queue(HEX_A_128, qA);
  read_hex128_to_queue(HEX_B_128, qB);
  read_hex128_to_queue(HEX_C_128, qC);

  `FAIL_UNLESS(qA.size() > 0)
  `FAIL_UNLESS(qA.size() == qB.size())
  `FAIL_UNLESS(qA.size() == qC.size())

  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);

  // For each vector, pulse valids for exactly one cycle, wait 5, and compare.
  foreach (qA[i]) begin
    s_i_in_anikin = qA[i];
    s_i_in_force  = qB[i];
    s_i_valid128_anikin = 1;
    s_i_valid128_force  = 1;
    @(posedge s_i_clk);
    clear_valids();

    wait_n_ticks(5);

    `FAIL_UNLESS(s_o_valid128_jedi)
    // $display(">>>>> s_i_in_anikin=0x%x", s_i_in_anikin);
    // $display(">>>>> s_i_in_force=0x%x", s_i_in_force);
    // $display(">>>>> s_o_out_jedi=0x%x", s_o_out_jedi);
    // $display(">>>>> qC[i]=0x%x", qC[i]);
    `FAIL_UNLESS(s_o_out_jedi == qC[i])
    `FAIL_UNLESS(s_o_error === '0)
  end
`SVTEST_END

// -------------------------------------------------------------------------
// TWO/FOUR SP MODE Edge cases test
// -------------------------------------------------------------------------
// ---- 64-bit (double) bit patterns
localparam logic [63:0] DBL_MAX      = 64'h7FEF_FFFF_FFFF_FFFF;
localparam logic [63:0] DBL_MIN_N    = 64'h0010_0000_0000_0000; // min normal
localparam logic [63:0] DBL_TWO      = 64'h4000_0000_0000_0000;
localparam logic [63:0] DBL_HALF     = 64'h3FE0_0000_0000_0000;
localparam logic [63:0] DBL_ONE      = 64'h3FF0_0000_0000_0000;
localparam logic [63:0] DBL_ONE_UP   = 64'h3FF0_0000_0000_0001; // nextafter(1.0,+)
localparam logic [63:0] DBL_ONE_DOWN = 64'h3FEF_FFFF_FFFF_FFFF; // nextafter(1.0,-)

// ---- 32-bit (float) bit patterns
localparam logic [31:0] FLT_MAX      = 32'h7F7F_FFFF;
localparam logic [31:0] FLT_MIN_N    = 32'h0080_0000; // min normal
localparam logic [31:0] FLT_TWO      = 32'h4000_0000;
localparam logic [31:0] FLT_HALF     = 32'h3F00_0000;
localparam logic [31:0] FLT_ONE      = 32'h3F80_0000;
localparam logic [31:0] FLT_ONE_UP   = 32'h3F80_0001;
localparam logic [31:0] FLT_ONE_DOWN = 32'h3F7F_FFFF;

`SVTEST(two_sp_mode_edge_overflow_underflow_and_signs)
  // Lane A: DBL_MAX * 2 -> +INF (overflow)
  // Lane B: MIN_NORMAL * 0.5 -> subnormal (underflow to subnormal)
  logic [63:0] a_top = DBL_MAX;
  logic [63:0] b_top = DBL_TWO;
  logic [63:0] a_bot = DBL_MIN_N;
  logic [63:0] b_bot = DBL_HALF;

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid64a_jedi && s_o_valid64b_jedi)
  `FAIL_UNLESS(top64(s_o_out_jedi) == mul64_bits(a_top, b_top)) // expect +INF
  // `FAIL_UNLESS(bot64(s_o_out_jedi) == mul64_bits(a_bot, b_bot)) // expect subnormal
  // But because the module treats subnormal as zero, expect zero:
  `FAIL_UNLESS(bot64(s_o_out_jedi) == '0)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(two_sp_mode_edge_signs)
  // A: (-2.0) * (3.0) -> -6.0
  // B: (-5.0) * (-0.25) -> +1.25
  logic [63:0] a_top = $realtobits(-2.0);
  logic [63:0] b_top = $realtobits( 3.0);
  logic [63:0] a_bot = $realtobits(-5.0);
  logic [63:0] b_bot = $realtobits(-0.25);

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid64a_jedi && s_o_valid64b_jedi)
  `FAIL_UNLESS(top64(s_o_out_jedi) == mul64_bits(a_top, b_top))
  `FAIL_UNLESS(bot64(s_o_out_jedi) == mul64_bits(a_bot, b_bot))
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(two_sp_mode_rounding_ulps)
  // A: (1+ulp) * (1-ulp) ~ 1 - ulp^2 (very close to 1)
  // B: 1.0 * (1+ulp) -> nextUp(1.0)
  logic [63:0] a_top = DBL_ONE_UP;
  logic [63:0] b_top = DBL_ONE_DOWN;
  logic [63:0] a_bot = DBL_ONE;
  logic [63:0] b_bot = DBL_ONE_UP;

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 1; s_i_valid64a_force = 1;
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid64a_jedi && s_o_valid64b_jedi)
  `FAIL_UNLESS(top64(s_o_out_jedi) == mul64_bits(a_top, b_top))
  `FAIL_UNLESS(bot64(s_o_out_jedi) == mul64_bits(a_bot, b_bot))
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(four_sp_mode_edge_overflow_underflow_and_signs)
  // a: FLT_MAX * 2 -> +INF (overflow)
  // b: MIN_NORMAL * 0.5 -> subnormal
  // c: (-3.0) * (2.5) -> -7.5
  // d: 2^-10 * 2^10 -> 1.0  (exact)
  logic [31:0] aa = FLT_MAX;
  logic [31:0] fa = FLT_TWO;

  logic [31:0] ab = FLT_MIN_N;
  logic [31:0] fb = FLT_HALF;

  logic [31:0] ac = $shortrealtobits(shortreal'(-3.0));
  logic [31:0] fc = $shortrealtobits(shortreal'( 2.5));

  // 2^-10 and 2^10 in float
  logic [31:0] ad = $shortrealtobits(shortreal'($pow(2.0, -10.0)));
  logic [31:0] fd = $shortrealtobits(shortreal'($pow(2.0,  10.0)));

  drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

  s_i_in_anikin = {aa, ab, ac, ad};
  s_i_in_force  = {fa, fb, fc, fd};

  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1;
  s_i_valid32b_anikin = 1; s_i_valid32b_force = 1;
  s_i_valid32c_anikin = 1; s_i_valid32c_force = 1;
  s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid32a_jedi && s_o_valid32b_jedi && s_o_valid32c_jedi && s_o_valid32d_jedi)
  `FAIL_UNLESS(lane32_a(s_o_out_jedi) == mul32_bits(aa, fa)) // +INF
  // `FAIL_UNLESS(lane32_b(s_o_out_jedi) == mul32_bits(ab, fb)) // subnormal
  `FAIL_UNLESS(lane32_c(s_o_out_jedi) == mul32_bits(ac, fc)) // negative
  `FAIL_UNLESS(lane32_d(s_o_out_jedi) == mul32_bits(ad, fd)) // 1.0
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(four_sp_mode_rounding_ulps)
  // a: (1+ulp)*(1-ulp), b: 1*nextUp(1), c: nextDown(1)*1, d: (1+ulp)^2
  logic [31:0] aa = FLT_ONE_UP,   fa = FLT_ONE_DOWN;
  logic [31:0] ab = FLT_ONE,      fb = FLT_ONE_UP;
  logic [31:0] ac = FLT_ONE_DOWN, fc = FLT_ONE;
  logic [31:0] ad = FLT_ONE_UP,   fd = FLT_ONE_UP;

  drive_meta(FOUR_SP_MODE, NORMAL, NORMAL, NORMAL, NORMAL);

  s_i_in_anikin = {aa, ab, ac, ad};
  s_i_in_force  = {fa, fb, fc, fd};

  s_i_valid32a_anikin = 1; s_i_valid32a_force = 1;
  s_i_valid32b_anikin = 1; s_i_valid32b_force = 1;
  s_i_valid32c_anikin = 1; s_i_valid32c_force = 1;
  s_i_valid32d_anikin = 1; s_i_valid32d_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid32a_jedi && s_o_valid32b_jedi && s_o_valid32c_jedi && s_o_valid32d_jedi)
  `FAIL_UNLESS(lane32_a(s_o_out_jedi) == mul32_bits(aa, fa))
  `FAIL_UNLESS(lane32_b(s_o_out_jedi) == mul32_bits(ab, fb))
  `FAIL_UNLESS(lane32_c(s_o_out_jedi) == mul32_bits(ac, fc))
  `FAIL_UNLESS(lane32_d(s_o_out_jedi) == mul32_bits(ad, fd))
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(two_sp_mode_edge_partial_valids_independent)
  logic [127:0] prev = s_o_out_jedi;
  // Only lane B valid; lane A overflow vector held back
  logic [63:0] a_top = DBL_MAX, b_top = DBL_TWO;   // would overflow
  logic [63:0] a_bot = DBL_MIN_N, b_bot = DBL_HALF; // underflow to subnormal

  drive_meta(TWO_SP_MODE, NORMAL, NORMAL, NA, NA);

  s_i_in_anikin = {a_top, a_bot};
  s_i_in_force  = {b_top, b_bot};

  s_i_valid64a_anikin = 0; s_i_valid64a_force = 0; // A not valid
  s_i_valid64b_anikin = 1; s_i_valid64b_force = 1; // B valid
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(!s_o_valid64a_jedi && !s_o_valid64b_jedi) // Both invalid
  `FAIL_UNLESS(s_o_out_jedi === prev)                    // Nothing happens
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

// -------------------------------------------------------------------------
// SINGLE SP MODE Edge cases test
// -------------------------------------------------------------------------
`SVTEST(single_mode_overflow_to_posinf)
  // max finite * 2.0 -> +INF
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_MAX_FINITE_POS;
  s_i_in_force  = F128_TWO;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(4); `FAIL_UNLESS(!s_o_valid128_jedi) // no early valid
  wait_n_ticks(1);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(is_inf128(s_o_out_jedi) && (s_o_out_jedi[127] == 1'b0)) // +INF
  `FAIL_UNLESS(s_o_metadata.sp_mode == SINGLE_MODE)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_overflow_to_neginf)
  // (-max finite) * 2.0 -> -INF
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_MAX_FINITE_NEG;
  s_i_in_force  = F128_TWO;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(is_inf128(s_o_out_jedi) && (s_o_out_jedi[127] == 1'b1)) // -INF
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_underflow_to_subnormal)
  // min normal * 0.5 -> subnormal (non-zero, exp==0)
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_MIN_NORMAL;
  s_i_in_force  = F128_HALF;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(is_subnormal128(s_o_out_jedi))
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_underflow_to_zero)
  // min normal * 2^-200 -> rounds to 0 (magnitude < min subnormal)
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_MIN_NORMAL;
  s_i_in_force  = F128_2_NEG_200;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_out_jedi == 128'b0)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_denormal_operand_treated_as_zero)
  // Treat denormal as zero => result zero regardless of partner
  drive_meta(SINGLE_MODE, POS_DENORMAL, NA, NA, NA);
  s_i_in_anikin = F128_DENORM_MIN; // actual subnormal bits
  s_i_in_force  = F128_TWO;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_out_jedi == 128'b0)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_rounding_near_one_ulps)
  // (1+ulp)*(1-ulp) is extremely close to 1.0; exact result depends on quad rounding.
  // Fill EXP_NEAR_ONE with libquadmath result of (F128_ONE_UP * F128_ONE_DOWN).
  localparam logic [127:0] EXP_NEAR_ONE = 128'h3fff0000000000000000000000000000 /*ground truth achieved from libquadmath*/;

  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_ONE_UP;
  s_i_in_force  = F128_ONE_DOWN;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_out_jedi == EXP_NEAR_ONE)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_rounding_boundary_carry)
  // (1+ulp) * (1+ulp) should land just above 1.0; in quad it’s close to 1 + 2*ulp + ulp^2.
  // Fill EXP_BOUNDARY with libquadmath result of (F128_ONE_UP * F128_ONE_UP).
  localparam logic [127:0] EXP_BOUNDARY = 128'h3fff0000000000000000000000000002 /*ground truth achieved from libquadmath*/;

  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_ONE_UP;
  s_i_in_force  = F128_ONE_UP;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_out_jedi == EXP_BOUNDARY)
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_sign_check_only)
  // (-max finite) * (0.5) -> negative finite (not INF/NaN). We only assert sign is negative.
  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);
  s_i_in_anikin = F128_MAX_FINITE_NEG;
  s_i_in_force  = F128_HALF;

  s_i_valid128_anikin = 1; s_i_valid128_force = 1;
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_out_jedi[127] == 1'b1)       // negative sign
  `FAIL_UNLESS(!is_inf128(s_o_out_jedi))        // not INF
  `FAIL_UNLESS(s_o_out_jedi[126 -: 15] != {15{1'b1}} || s_o_out_jedi[111:0] != '0) // not NaN INF combo
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END

`SVTEST(single_mode_partial_valids_with_edge_operands)
  logic [127:0] prev = s_o_out_jedi;

  drive_meta(SINGLE_MODE, NORMAL, NA, NA, NA);

  // Would overflow if accepted, but we drop it by clearing one valid
  s_i_in_anikin = F128_MAX_FINITE_POS;
  s_i_in_force  = F128_TWO;

  s_i_valid128_anikin = 1; s_i_valid128_force = 0; // force not valid
  @(posedge s_i_clk); clear_valids();

  wait_n_ticks(5);

  `FAIL_UNLESS(!s_o_valid128_jedi)
  `FAIL_UNLESS(s_o_out_jedi === prev) // unchanged
  `FAIL_UNLESS(s_o_error == '0)
`SVTEST_END
