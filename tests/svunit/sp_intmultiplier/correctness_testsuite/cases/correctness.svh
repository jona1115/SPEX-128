`SVTEST(handwritten_0)
  // Make sure EX_MAN_BITS_128 is set to 6 to run this
  s_i_anikin        = 6'b110011;
  s_i_force         = 6'b011001;
  s_i_valid_anikin  = '1;
  s_i_valid_force   = '1;
  // s_o_jedi      = ;

  wait_n_ticks(`LATENCY);
  
  `PRINT_INTERMEDIATE_RESULTS

  // `FAIL_UNLESS(s_o_out_jedi === prev)
  // `FAIL_UNLESS(!s_o_valid128_jedi)
  // `FAIL_UNLESS(!s_o_valid64a_jedi && !s_o_valid64b_jedi)
  // `FAIL_UNLESS(!s_o_valid32a_jedi && !s_o_valid32b_jedi && !s_o_valid32c_jedi && !s_o_valid32d_jedi)
  // `FAIL_UNLESS(s_o_error === '0)
`SVTEST_END