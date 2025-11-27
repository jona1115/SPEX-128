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