`SVTEST(single_mode_early_exit_latency)
  int cycle;

  for (cycle = 0; cycle < (SINGLE_MODE_LATENCY + 1); cycle++) begin
    if (cycle == 0) begin
      step_single(1'b1, 4'd3);
    end
    else begin
      step_single(1'b0, '0);
    end

    if (cycle == (SINGLE_MODE_LATENCY - 1)) begin
      check_single_output(1'b1, 4'd3);
    end
    else begin
      check_single_output(1'b0, '0);
    end
  end
`SVTEST_END

`SVTEST(two_sp_mode_early_exit_latency)
  int cycle;

  for (cycle = 0; cycle < (TWO_SP_MODE_LATENCY + 1); cycle++) begin
    if (cycle == 0) begin
      step_two(1'b1, 4'd7, 4'd11);
    end
    else begin
      step_two(1'b0, '0, '0);
    end

    if (cycle == (TWO_SP_MODE_LATENCY - 1)) begin
      check_two_output(1'b1, 4'd7, 4'd11);
    end
    else begin
      check_two_output(1'b0, '0, '0);
    end
  end
`SVTEST_END

`SVTEST(four_sp_mode_pipeline_end_latency)
  int cycle;

  for (cycle = 0; cycle < (FOUR_SP_MODE_LATENCY + 1); cycle++) begin
    if (cycle == 0) begin
      step_four(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);
    end
    else begin
      step_four(1'b0, '0, '0, '0, '0);
    end

    if (cycle == (FOUR_SP_MODE_LATENCY - 1)) begin
      check_four_output(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);
    end
    else begin
      check_four_output(1'b0, '0, '0, '0, '0);
    end
  end
`SVTEST_END

`SVTEST(single_mode_pipeline_b2b_and_bubble)
  int cycle;
  int src_cycle;

  for (cycle = 0; cycle < (4 + SINGLE_MODE_LATENCY); cycle++) begin
    case (cycle)
      0: step_single(1'b1, 4'd1);
      1: step_single(1'b1, 4'd2);
      3: step_single(1'b1, 4'd5);
      default: step_single(1'b0, '0);
    endcase

    src_cycle = cycle - (SINGLE_MODE_LATENCY - 1);
    case (src_cycle)
      0: check_single_output(1'b1, 4'd1);
      1: check_single_output(1'b1, 4'd2);
      2: check_single_output(1'b0, '0); // Bubble propagation
      3: check_single_output(1'b1, 4'd5);
      default: check_single_output(1'b0, '0);
    endcase
  end
`SVTEST_END

`SVTEST(two_sp_mode_pipeline_b2b_and_bubble)
  int cycle;
  int src_cycle;

  for (cycle = 0; cycle < (4 + TWO_SP_MODE_LATENCY); cycle++) begin
    case (cycle)
      0: step_two(1'b1, 4'd1, 4'd2);
      1: step_two(1'b1, 4'd3, 4'd4);
      3: step_two(1'b1, 4'd7, 4'd8);
      default: step_two(1'b0, '0, '0);
    endcase

    src_cycle = cycle - (TWO_SP_MODE_LATENCY - 1);
    case (src_cycle)
      0: check_two_output(1'b1, 4'd1, 4'd2);
      1: check_two_output(1'b1, 4'd3, 4'd4);
      2: check_two_output(1'b0, '0, '0); // Bubble propagation
      3: check_two_output(1'b1, 4'd7, 4'd8);
      default: check_two_output(1'b0, '0, '0);
    endcase
  end
`SVTEST_END

`SVTEST(four_sp_mode_pipeline_b2b_and_bubble)
  int cycle;
  int src_cycle;

  // FOUR_SP_MODE uses a single true dual-port BRAM. Lanes c/d are read one
  // cycle later, so the input stream must be bubbled (valid every other cycle).
  for (cycle = 0; cycle < (5 + FOUR_SP_MODE_LATENCY); cycle++) begin
    case (cycle)
      0: step_four(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);
      2: step_four(1'b1, 4'd5, 4'd6, 4'd7, 4'd8);
      4: step_four(1'b1, 4'd9, 4'd10, 4'd11, 4'd12);
      default: step_four(1'b0, '0, '0, '0, '0);
    endcase

    src_cycle = cycle - (FOUR_SP_MODE_LATENCY - 1);
    case (src_cycle)
      0: check_four_output(1'b1, 4'd1, 4'd2, 4'd3, 4'd4);
      1: check_four_output(1'b0, '0, '0, '0, '0); // Bubble propagation
      2: check_four_output(1'b1, 4'd5, 4'd6, 4'd7, 4'd8);
      3: check_four_output(1'b0, '0, '0, '0, '0); // Bubble propagation
      4: check_four_output(1'b1, 4'd9, 4'd10, 4'd11, 4'd12);
      default: check_four_output(1'b0, '0, '0, '0, '0);
    endcase
  end
`SVTEST_END
