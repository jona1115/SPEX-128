`SVTEST(noop_when_valid_low)
  logic [127:0] snapshot;
  snapshot = s_o_exp_x;

  s_i_valid = '0;
  
  wait_n_ticks(`LATENCY + 2);
  $display(">>>>> snapshot=0x%x", snapshot);
  $display(">>>>> s_o_exp_x=0x%x", s_o_exp_x);
  `FAIL_UNLESS_EQUAL(snapshot, s_o_exp_x)
`SVTEST_END