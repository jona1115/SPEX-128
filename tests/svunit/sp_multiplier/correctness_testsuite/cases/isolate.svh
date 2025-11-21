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