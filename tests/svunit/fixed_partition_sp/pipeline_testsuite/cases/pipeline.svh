`SVTEST(single_mode_early_exit_latency)
  step_single(1'b1, 4'd3);
  check_single_output(1'b0, '0);

  step_single(1'b0, '0);
  check_single_output(1'b1, 4'd3);

  step_single(1'b0, '0);
  check_single_output(1'b0, '0);
`SVTEST_END

`SVTEST(two_sp_mode_early_exit_latency)
  step_two(1'b1, 4'd7, 4'd11);
  check_two_output(1'b0, '0, '0);

  step_two(1'b0, '0, '0);
  check_two_output(1'b0, '0, '0);

  step_two(1'b0, '0, '0);
  check_two_output(1'b1, 4'd7, 4'd11);

  step_two(1'b0, '0, '0);
  check_two_output(1'b0, '0, '0);
`SVTEST_END

`SVTEST(four_sp_mode_pipeline_end_latency)
  step_four(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);
  check_four_output(1'b0, '0, '0, '0, '0);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b0, '0, '0, '0, '0);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b0, '0, '0, '0, '0);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b0, '0, '0, '0, '0);
`SVTEST_END

`SVTEST(single_mode_pipeline_b2b_and_bubble)
  step_single(1'b1, 4'd1);
  check_single_output(1'b0, '0);

  step_single(1'b1, 4'd2);
  check_single_output(1'b1, 4'd1);

  step_single(1'b0, '0);
  check_single_output(1'b1, 4'd2);

  step_single(1'b1, 4'd5);
  check_single_output(1'b0, '0);

  step_single(1'b0, '0);
  check_single_output(1'b1, 4'd5);

  step_single(1'b0, '0);
  check_single_output(1'b0, '0);
`SVTEST_END

`SVTEST(two_sp_mode_pipeline_b2b_and_bubble)
  step_two(1'b1, 4'd1, 4'd2);
  check_two_output(1'b0, '0, '0);

  step_two(1'b1, 4'd3, 4'd4);
  check_two_output(1'b0, '0, '0);

  step_two(1'b0, '0, '0);
  check_two_output(1'b1, 4'd1, 4'd2);

  step_two(1'b1, 4'd7, 4'd8);
  check_two_output(1'b1, 4'd3, 4'd4);

  step_two(1'b0, '0, '0);
  check_two_output(1'b0, '0, '0);

  step_two(1'b0, '0, '0);
  check_two_output(1'b1, 4'd7, 4'd8);

  step_two(1'b0, '0, '0);
  check_two_output(1'b0, '0, '0);
`SVTEST_END

`SVTEST(four_sp_mode_pipeline_b2b_and_bubble)
  step_four(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);
  check_four_output(1'b0, '0, '0, '0, '0);

  step_four(1'b1, 4'd5, 4'd6, 4'd7, 4'd8);
  check_four_output(1'b0, '0, '0, '0, '0);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b0, '0, '0, '0, '0);

  step_four(1'b1, 4'd9, 4'd10, 4'd11, 4'd12);
  check_four_output(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b1, 4'd5, 4'd6, 4'd7, 4'd8);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b0, '0, '0, '0, '0);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b1, 4'd9, 4'd10, 4'd11, 4'd12);

  step_four(1'b0, '0, '0, '0, '0);
  check_four_output(1'b0, '0, '0, '0, '0);
`SVTEST_END
