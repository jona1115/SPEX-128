/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/27/2025
 * 
 ********************************************************************
 * 
 * Description:
 * This is a subword parallel floating point multiplier. IEEE-754
 * compliant (almost).
 * 
 * Naming convension:
 *  jedi = anikin * force
 * 
 ********************************************************************
 * 
 * Modification history:
 *    Ver   |  Who       |  Date	      |  Changes
 *  ------- + ---------- + ------------ + --------------------------
 *    1.00  |  Jonathan  |  11/27/2025  |  Birth of this file
 *    1.01  |  Jonathan  |  1/27/2026   |  Renamed file from sp_multiplier.sv to sp_fpmultiplier.sv
 * 
 *******************************************************************/

`include "config.svh" // Here lives a bunch of macro flags...

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;
import fixed128_pkg::*;
import fixed64_pkg::*;
import fixed32_pkg::*;
import unbiasing_pkg::*;

module sp_fpmultiplier #(
  parameter int NUM_BITS_128  = 128,
  parameter int NUM_BITS_64   = 64,
  parameter int NUM_BITS_32   = 32,

  // Multiplier pipeline latency (cycles from mul start to valid product)
`ifdef USE_DSP
  parameter int INTMUL_LATENCY = 9, // DSP intmult path latency (3 mult stages + 6 tree stages)
`else
  parameter int INTMUL_LATENCY = 3, // non-DSP intmult path latency
`endif
  parameter int MODULE_LATENCY = INTMUL_LATENCY + 4,

  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32,

  parameter int DEBUG_PRINT_EN = 0,

  // Identifier const
  parameter logic [3:0] MODULE_IDENTIFIER = 4'b0000
) (
  input   logic                                   i_clk,
  input   logic                                   i_rst_n, // Synchronous

  // Metadata stuff
  input   var float_metadata_t                    i_metadata,
  output  var float_metadata_t                    o_metadata,

  // Data
  input   logic [NUM_BITS_128-1:0]                i_in_anikin,
  input   logic [NUM_BITS_128-1:0]                i_in_force,
  output  logic [NUM_BITS_128-1:0]                o_out_jedi,

  // Upstream Handshake
  input   logic                                   i_valid128_anikin,
  input   logic                                   i_valid128_force,
  input   logic                                   i_valid64a_anikin,
  input   logic                                   i_valid64a_force,
  input   logic                                   i_valid64b_anikin,
  input   logic                                   i_valid64b_force,
  input   logic                                   i_valid32a_anikin,
  input   logic                                   i_valid32a_force,
  input   logic                                   i_valid32b_anikin,
  input   logic                                   i_valid32b_force,
  input   logic                                   i_valid32c_anikin,
  input   logic                                   i_valid32c_force,
  input   logic                                   i_valid32d_anikin,
  input   logic                                   i_valid32d_force,

  // Downstream Handshake
  output  logic                                   o_valid128_jedi,
  output  logic                                   o_valid64a_jedi,
  output  logic                                   o_valid64b_jedi,
  output  logic                                   o_valid32a_jedi,
  output  logic                                   o_valid32b_jedi,
  output  logic                                   o_valid32c_jedi,
  output  logic                                   o_valid32d_jedi,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic [NUM_BITS_128-1:0]            s_i_in_anikin;
logic [NUM_BITS_128-1:0]            s_i_in_force;
logic [NUM_BITS_128-1:0]            s_o_out_jedi;
logic                               s_o_sanity_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0]   s_o_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0]   s_o_debug;


//=====================================================================================
// Module body
//=====================================================================================
/**
 * Decode the packed inputs into typed lane views for readability.
 */
binary128_t s_S0_128_anikin;
binary128_t s_S0_128_force;
binary64_t  s_S0_64a_anikin;
binary64_t  s_S0_64a_force;
binary64_t  s_S0_64b_anikin;
binary64_t  s_S0_64b_force;
binary32_t  s_S0_32a_anikin;
binary32_t  s_S0_32a_force;
binary32_t  s_S0_32b_anikin;
binary32_t  s_S0_32b_force;
binary32_t  s_S0_32c_anikin;
binary32_t  s_S0_32c_force;
binary32_t  s_S0_32d_anikin;
binary32_t  s_S0_32d_force;
assign s_S0_128_anikin = binary128_t'(i_in_anikin);
assign s_S0_128_force  = binary128_t'(i_in_force);
assign s_S0_64a_anikin = binary64_t'(i_in_anikin[127:64]);
assign s_S0_64a_force  = binary64_t'(i_in_force[127:64]);
assign s_S0_64b_anikin = binary64_t'(i_in_anikin[63:0]);
assign s_S0_64b_force  = binary64_t'(i_in_force[63:0]);
assign s_S0_32a_anikin = binary32_t'(i_in_anikin[127:96]);
assign s_S0_32a_force  = binary32_t'(i_in_force[127:96]);
assign s_S0_32b_anikin = binary32_t'(i_in_anikin[95:64]);
assign s_S0_32b_force  = binary32_t'(i_in_force[95:64]);
assign s_S0_32c_anikin = binary32_t'(i_in_anikin[63:32]);
assign s_S0_32c_force  = binary32_t'(i_in_force[63:32]);
assign s_S0_32d_anikin = binary32_t'(i_in_anikin[31:0]);
assign s_S0_32d_force  = binary32_t'(i_in_force[31:0]);


// Default stuff out
always_ff @( posedge i_clk ) begin : defaulter
  if (!i_rst_n) begin
    s_o_debug <= '0;
  end
  // else begin // commented out because there are drivers of these signals in other always_ff blocks, but by commenting this part out might lead to infer latches
  //   s_o_error <= s_o_error;
  //   s_o_debug <= s_o_debug;
  // end
end


//=====================================================================================
// Stage 0
//=====================================================================================
/**
 * Decoding valid bit: This block checks the "all or nothing" spec
 * 
 * "All or nothing": For TWO and FOUR SP modes, all subword (a, and b, for TWO; a, b, c, d for
 *                   FOUR) from both input (anikin and force) has to be valid for anything to 
 *                   proceed. For SINGLE mode, both anikin and force has to be valid.
 */
logic s_S0_valid128_anikin;
logic s_S0_valid128_force;
logic s_S0_valid64a_anikin;
logic s_S0_valid64a_force;
logic s_S0_valid64b_anikin;
logic s_S0_valid64b_force;
logic s_S0_valid32a_anikin;
logic s_S0_valid32a_force;
logic s_S0_valid32b_anikin;
logic s_S0_valid32b_force;
logic s_S0_valid32c_anikin;
logic s_S0_valid32c_force;
logic s_S0_valid32d_anikin;
logic s_S0_valid32d_force;
always_comb begin : valid_bit_decoder
  // Default
  s_S0_valid128_anikin  = 1'b0;
  s_S0_valid128_force   = 1'b0;
  s_S0_valid64a_anikin  = 1'b0;
  s_S0_valid64a_force   = 1'b0;
  s_S0_valid64b_anikin  = 1'b0;
  s_S0_valid64b_force   = 1'b0;
  s_S0_valid32a_anikin  = 1'b0;
  s_S0_valid32a_force   = 1'b0;
  s_S0_valid32b_anikin  = 1'b0;
  s_S0_valid32b_force   = 1'b0;
  s_S0_valid32c_anikin  = 1'b0;
  s_S0_valid32c_force   = 1'b0;
  s_S0_valid32d_anikin  = 1'b0;
  s_S0_valid32d_force   = 1'b0;

  // Per-lane valid decoding is kept explicit so the "all or nothing" checks read
  // directly against the active subword mode.
  case (i_metadata.sp_mode)
    SINGLE_MODE: begin
      if (i_valid128_anikin === 1'b1 && i_valid128_force === 1'b1) begin
        s_S0_valid128_anikin = 1'b1;
        s_S0_valid128_force  = 1'b1;
      end
    end // SINGLE_MODE

    TWO_SP_MODE: begin
      if (i_valid64a_anikin === 1'b1 && i_valid64a_force === 1'b1) begin
        s_S0_valid64a_anikin = 1'b1;
        s_S0_valid64a_force  = 1'b1;
      end

      if (i_valid64b_anikin === 1'b1 && i_valid64b_force === 1'b1) begin
        s_S0_valid64b_anikin = 1'b1;
        s_S0_valid64b_force  = 1'b1;
      end
    end // TWO_SP_MODE

    FOUR_SP_MODE: begin
      if (i_valid32a_anikin === 1'b1 && i_valid32a_force === 1'b1) begin
        s_S0_valid32a_anikin = 1'b1;
        s_S0_valid32a_force  = 1'b1;
      end

      if (i_valid32b_anikin === 1'b1 && i_valid32b_force === 1'b1) begin
        s_S0_valid32b_anikin = 1'b1;
        s_S0_valid32b_force  = 1'b1;
      end

      if (i_valid32c_anikin === 1'b1 && i_valid32c_force === 1'b1) begin
        s_S0_valid32c_anikin = 1'b1;
        s_S0_valid32c_force  = 1'b1;
      end

      if (i_valid32d_anikin === 1'b1 && i_valid32d_force === 1'b1) begin
        s_S0_valid32d_anikin = 1'b1;
        s_S0_valid32d_force  = 1'b1;
      end
    end // FOUR_SP_MODE

    default: begin
    //   assert (0);
    end
  endcase // case (i_metadata.sp_mode)
end

always_ff @( posedge i_clk ) begin : error_invalid_sp_mode
  if (!i_rst_n) begin
    s_o_error[0] <= 1'b0;
    s_o_error[ERROR_SIGNAL_NUM_BITS-1:20] <= '0;
  end
  else if (!(i_metadata.sp_mode == SINGLE_MODE ||
             i_metadata.sp_mode == TWO_SP_MODE ||
             i_metadata.sp_mode == FOUR_SP_MODE)) begin
    s_o_error[0] <= 1'b1;
  end
end

/**
 * Classify input: Classify input float into one of the float types (NaN, Zero, Normal, etc...)
 */
float_metadata_t s_S0_metadata_anikin, s_S0_metadata_force;
float_classifier #() my_float_classifier_anikin (
  .i_current_sp(i_metadata.sp_mode),
  .i_float(i_in_anikin),
  .o_metadata(s_S0_metadata_anikin)
);
float_classifier #() my_float_classifier_force (
  .i_current_sp(i_metadata.sp_mode),
  .i_float(i_in_force),
  .o_metadata(s_S0_metadata_force)
);

/**
 * Pipeline naming convention:
 *   - S0_*: combinational input decode, validation, and classification
 *   - S1_*: first registered stage before the integer multiplier
 *   - sink_*: unnumbered alignment path through the integer multiplier latency
 *   - S2_*: first registered stage after the multiplier (round + carry fixup)
 *   - S3_*: second registered stage after the multiplier (renormalize)
 *   - S4_*: final registered output stage (pack + valid/metadata passthrough)
 *
 * The integer multiplier latency is intentionally not counted as a numbered stage.
 */
logic s_S1_en, s_S2_en, s_S3_en, s_S4_en;
logic s_fire;
localparam int MUL_LAUNCH_OFFSET = 0;
localparam int S2_OFFSET = MUL_LAUNCH_OFFSET + INTMUL_LATENCY;
localparam int S3_OFFSET = S2_OFFSET + 1;
localparam int S4_OFFSET = S3_OFFSET + 1;
localparam int PIPE_DEPTH = S4_OFFSET + 1;
logic [PIPE_DEPTH-1:0] s_pipe_valid;
logic [PIPE_DEPTH-1:0] s_pipe_valid_next;
logic s_mul_launch;

always_comb begin : stage_fire_decode
  s_fire = 1'b0;
  unique case (i_metadata.sp_mode)
    SINGLE_MODE: begin
      s_fire = (s_S0_valid128_anikin === 1'b1) && (s_S0_valid128_force === 1'b1);
    end
    TWO_SP_MODE: begin
      s_fire = (s_S0_valid64a_anikin === 1'b1) && (s_S0_valid64a_force === 1'b1) &&
               (s_S0_valid64b_anikin === 1'b1) && (s_S0_valid64b_force === 1'b1);
    end
    FOUR_SP_MODE: begin
      s_fire = (s_S0_valid32a_anikin === 1'b1) && (s_S0_valid32a_force === 1'b1) &&
               (s_S0_valid32b_anikin === 1'b1) && (s_S0_valid32b_force === 1'b1) &&
               (s_S0_valid32c_anikin === 1'b1) && (s_S0_valid32c_force === 1'b1) &&
               (s_S0_valid32d_anikin === 1'b1) && (s_S0_valid32d_force === 1'b1);
    end
    default: begin
      s_fire = 1'b0;
    end
  endcase
end

always_ff @(posedge i_clk) begin : pipeline_valid_shiftreg
  if (!i_rst_n) begin
    s_pipe_valid <= '0;
  end
  else begin
    s_pipe_valid <= s_pipe_valid_next;
  end
end

assign s_pipe_valid_next = {s_pipe_valid[PIPE_DEPTH-2:0], s_fire};

assign s_mul_launch = s_pipe_valid[MUL_LAUNCH_OFFSET];
assign s_S1_en = s_fire;
assign s_S2_en = s_pipe_valid[S2_OFFSET];
assign s_S3_en = s_pipe_valid[S3_OFFSET];
assign s_S4_en = s_pipe_valid[S4_OFFSET];

//=====================================================================================
// Stage 1
//=====================================================================================
// Outputs
binary128_t s_S1_128_jedi;
binary64_t  s_S1_64a_jedi;
binary64_t  s_S1_64b_jedi;
binary32_t  s_S1_32a_jedi;
binary32_t  s_S1_32b_jedi;
binary32_t  s_S1_32c_jedi;
binary32_t  s_S1_32d_jedi;
/**
 * Stage 1: precompute sign and biased exponent in one register block.
 */
// This is basically a max(x, 0) function
`define MAX_0(x, y, b) ($signed($signed((x)) + $signed((y)) - (b)) < 0 ? '0 : ((x) + (y) - (b)))
always_ff @( posedge i_clk ) begin : stage1_sign_and_exp
  if (!i_rst_n) begin
    s_S1_128_jedi <= '0;
    s_S1_64a_jedi <= '0;
    s_S1_64b_jedi <= '0;
    s_S1_32a_jedi <= '0;
    s_S1_32b_jedi <= '0;
    s_S1_32c_jedi <= '0;
    s_S1_32d_jedi <= '0;
    s_o_error[1]  <= 1'b0;
    s_o_error[2]  <= 1'b0;
    s_o_error[5]  <= 1'b0;
    s_o_error[6]  <= 1'b0;
  end
  else begin
    if (s_S1_en) begin
      if (!(s_S0_metadata_anikin.sp_mode === s_S0_metadata_force.sp_mode)) begin
        s_o_error[5] <= 1'b1;
        s_o_error[6] <= 1'b1;
        // $fatal(1, "Bad things had happened, (s_S0_metadata_anikin.sp_mode === s_S0_metadata_force.sp_mode) is false.");
      end

      case (s_S0_metadata_anikin.sp_mode)
        SINGLE_MODE: begin
          s_S1_128_jedi.sign <= s_S0_128_anikin.sign ^ s_S0_128_force.sign; // Reminder: ^ is xor
          s_S1_128_jedi.exp  <= `MAX_0({1'b0, s_S0_128_anikin.exp}, {1'b0, s_S0_128_force.exp}, 16'sd16383);
        end

        TWO_SP_MODE: begin
          s_S1_64a_jedi.sign <= s_S0_64a_anikin.sign ^ s_S0_64a_force.sign;
          s_S1_64b_jedi.sign <= s_S0_64b_anikin.sign ^ s_S0_64b_force.sign;
          s_S1_64a_jedi.exp  <= `MAX_0({5'b0, s_S0_64a_anikin.exp}, {5'b0, s_S0_64a_force.exp}, 15'sd1023);
          s_S1_64b_jedi.exp  <= `MAX_0({5'b0, s_S0_64b_anikin.exp}, {5'b0, s_S0_64b_force.exp}, 15'sd1023);
        end

        FOUR_SP_MODE: begin
          s_S1_32a_jedi.sign <= s_S0_32a_anikin.sign ^ s_S0_32a_force.sign;
          s_S1_32b_jedi.sign <= s_S0_32b_anikin.sign ^ s_S0_32b_force.sign;
          s_S1_32c_jedi.sign <= s_S0_32c_anikin.sign ^ s_S0_32c_force.sign;
          s_S1_32d_jedi.sign <= s_S0_32d_anikin.sign ^ s_S0_32d_force.sign;
          s_S1_32a_jedi.exp  <= `MAX_0({8'b0, s_S0_32a_anikin.exp}, {8'b0, s_S0_32a_force.exp}, 15'sd127);
          s_S1_32b_jedi.exp  <= `MAX_0({8'b0, s_S0_32b_anikin.exp}, {8'b0, s_S0_32b_force.exp}, 15'sd127);
          s_S1_32c_jedi.exp  <= `MAX_0({8'b0, s_S0_32c_anikin.exp}, {8'b0, s_S0_32c_force.exp}, 15'sd127);
          s_S1_32d_jedi.exp  <= `MAX_0({8'b0, s_S0_32d_anikin.exp}, {8'b0, s_S0_32d_force.exp}, 15'sd127);
        end

        default: begin
          assert (0) else begin
            s_o_error[1] <= 1'b1;
            s_o_error[2] <= 1'b1;
          end
        end
      endcase // case (i_metadata.sp_mode)
    end // if (s_S1_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

/**
 * Stage 1c: Signal passthrough, for proper pipelining
 */
logic             s_S1_valid128_jedi;
logic             s_S1_valid64a_jedi, s_S1_valid64b_jedi;
logic             s_S1_valid32a_jedi, s_S1_valid32b_jedi, s_S1_valid32c_jedi, s_S1_valid32d_jedi;
binary128_t       s_S1_128_anikin, s_S1_128_force;
binary64_t        s_S1_64a_anikin, s_S1_64a_force;
binary64_t        s_S1_64b_anikin, s_S1_64b_force;
binary32_t        s_S1_32a_anikin, s_S1_32a_force;
binary32_t        s_S1_32b_anikin, s_S1_32b_force;
binary32_t        s_S1_32c_anikin, s_S1_32c_force;
binary32_t        s_S1_32d_anikin, s_S1_32d_force;
float_metadata_t  s_S1_metadata_anikin, s_S1_metadata_force;
always_ff @( posedge i_clk ) begin : stage1c_signal_passthrough
  if (!i_rst_n) begin
    s_S1_valid128_jedi    <= '0;
    s_S1_valid64a_jedi    <= '0;
    s_S1_valid64b_jedi    <= '0;
    s_S1_valid32a_jedi    <= '0;
    s_S1_valid32b_jedi    <= '0;
    s_S1_valid32c_jedi    <= '0;
    s_S1_valid32d_jedi    <= '0;
    s_S1_metadata_anikin  <= '0;
    s_S1_metadata_force   <= '0;
  end
  else begin
    if (s_S1_en) begin
      // Pass the valid signals through, they are all invalid for now
      s_S1_valid128_jedi    <= s_S0_valid128_anikin & s_S0_valid128_force;
      s_S1_valid64a_jedi    <= s_S0_valid64a_anikin & s_S0_valid64a_force;
      s_S1_valid64b_jedi    <= s_S0_valid64b_anikin & s_S0_valid64b_force;
      s_S1_valid32a_jedi    <= s_S0_valid32a_anikin & s_S0_valid32a_force;
      s_S1_valid32b_jedi    <= s_S0_valid32b_anikin & s_S0_valid32b_force;
      s_S1_valid32c_jedi    <= s_S0_valid32c_anikin & s_S0_valid32c_force;
      s_S1_valid32d_jedi    <= s_S0_valid32d_anikin & s_S0_valid32d_force;

      // Input (anikin and force) pass through
      s_S1_128_anikin       <= s_S0_128_anikin;
      s_S1_128_force        <= s_S0_128_force;
      s_S1_64a_anikin       <= s_S0_64a_anikin;
      s_S1_64a_force        <= s_S0_64a_force;
      s_S1_64b_anikin       <= s_S0_64b_anikin;
      s_S1_64b_force        <= s_S0_64b_force;
      s_S1_32a_anikin       <= s_S0_32a_anikin;
      s_S1_32a_force        <= s_S0_32a_force;
      s_S1_32b_anikin       <= s_S0_32b_anikin;
      s_S1_32b_force        <= s_S0_32b_force;
      s_S1_32c_anikin       <= s_S0_32c_anikin;
      s_S1_32c_force        <= s_S0_32c_force;
      s_S1_32d_anikin       <= s_S0_32d_anikin;
      s_S1_32d_force        <= s_S0_32d_force;

      // Metadata stays aligned with the data path all the way to the output stage.
      s_S1_metadata_anikin  <= s_S0_metadata_anikin;
      s_S1_metadata_force   <= s_S0_metadata_force;
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Integer Multiplier Latency Path
//=====================================================================================
// extended mantissa (hs, helper signals)
logic [112:0] hs_S1_128_anikin_mantissa_extended, hs_S1_128_force_mantissa_extended;
logic [52:0]  hs_S1_64a_anikin_mantissa_extended, hs_S1_64a_force_mantissa_extended;
logic [52:0]  hs_S1_64b_anikin_mantissa_extended, hs_S1_64b_force_mantissa_extended;
logic [23:0]  hs_S1_32a_anikin_mantissa_extended, hs_S1_32a_force_mantissa_extended;
logic [23:0]  hs_S1_32b_anikin_mantissa_extended, hs_S1_32b_force_mantissa_extended;
logic [23:0]  hs_S1_32c_anikin_mantissa_extended, hs_S1_32c_force_mantissa_extended;
logic [23:0]  hs_S1_32d_anikin_mantissa_extended, hs_S1_32d_force_mantissa_extended;
`define NOT_DENORMAL(ft) ((ft) !== POS_DENORMAL && (ft) !== NEG_DENORMAL)
assign hs_S1_128_anikin_mantissa_extended = {`NOT_DENORMAL(s_S1_metadata_anikin.float_type_a) ? 1'b1 : 1'b0, s_S1_128_anikin.mantissa};
assign hs_S1_128_force_mantissa_extended  = {`NOT_DENORMAL(s_S1_metadata_force.float_type_a)  ? 1'b1 : 1'b0, s_S1_128_force.mantissa};
assign hs_S1_64a_anikin_mantissa_extended = {`NOT_DENORMAL(s_S1_metadata_anikin.float_type_a) ? 1'b1 : 1'b0, s_S1_64a_anikin.mantissa};
assign hs_S1_64a_force_mantissa_extended  = {`NOT_DENORMAL(s_S1_metadata_force.float_type_a)  ? 1'b1 : 1'b0, s_S1_64a_force.mantissa};
assign hs_S1_64b_anikin_mantissa_extended = {`NOT_DENORMAL(s_S1_metadata_anikin.float_type_b) ? 1'b1 : 1'b0, s_S1_64b_anikin.mantissa};
assign hs_S1_64b_force_mantissa_extended  = {`NOT_DENORMAL(s_S1_metadata_force.float_type_b)  ? 1'b1 : 1'b0, s_S1_64b_force.mantissa};
assign hs_S1_32a_anikin_mantissa_extended = {`NOT_DENORMAL(s_S1_metadata_anikin.float_type_a) ? 1'b1 : 1'b0, s_S1_32a_anikin.mantissa};
assign hs_S1_32a_force_mantissa_extended  = {`NOT_DENORMAL(s_S1_metadata_force.float_type_a)  ? 1'b1 : 1'b0, s_S1_32a_force.mantissa};
assign hs_S1_32b_anikin_mantissa_extended = {`NOT_DENORMAL(s_S1_metadata_anikin.float_type_b) ? 1'b1 : 1'b0, s_S1_32b_anikin.mantissa};
assign hs_S1_32b_force_mantissa_extended  = {`NOT_DENORMAL(s_S1_metadata_force.float_type_b)  ? 1'b1 : 1'b0, s_S1_32b_force.mantissa};
assign hs_S1_32c_anikin_mantissa_extended = {`NOT_DENORMAL(s_S1_metadata_anikin.float_type_c) ? 1'b1 : 1'b0, s_S1_32c_anikin.mantissa};
assign hs_S1_32c_force_mantissa_extended  = {`NOT_DENORMAL(s_S1_metadata_force.float_type_c)  ? 1'b1 : 1'b0, s_S1_32c_force.mantissa};
assign hs_S1_32d_anikin_mantissa_extended = {`NOT_DENORMAL(s_S1_metadata_anikin.float_type_d) ? 1'b1 : 1'b0, s_S1_32d_anikin.mantissa};
assign hs_S1_32d_force_mantissa_extended  = {`NOT_DENORMAL(s_S1_metadata_force.float_type_d)  ? 1'b1 : 1'b0, s_S1_32d_force.mantissa};
// Outputs
logic [225:0] s_sink_128_mult_out_full;
logic [105:0] s_sink_64a_mult_out_full, s_sink_64b_mult_out_full;
logic [47:0]  s_sink_32a_mult_out_full, s_sink_32b_mult_out_full, s_sink_32c_mult_out_full, s_sink_32d_mult_out_full;

logic [225:0] s_sp_intmultiplier_jedi;
logic [3:0]   unused_sp_intmultiplier_sanity_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] unused_sp_intmultiplier_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] unused_sp_intmultiplier_debug;
logic [115-1 : 0]                 unused_ds_S1_pp [0 : 58-1];
logic [6327 : 0]                  unused_ds_S2_S;
logic [6327 : 0]                  unused_ds_S2_C;
logic [229 : 0]                   unused_ds_S3_z0;
logic [229 : 0]                   unused_ds_S3_z1;
logic [113*2-1:0]                 unused_ds_S3_jedi;
logic                             unused_ds_S3_valid;
`ifdef USE_DSP
(* use_dsp = "yes" *) sp_intmultiplier #(
`else
sp_intmultiplier #(
`endif
  .MODULE_LATENCY(INTMUL_LATENCY)
) my_sp_intmultiplier (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_S1_metadata_anikin),
  .i_anikin(s_S1_metadata_anikin.sp_mode === SINGLE_MODE ? hs_S1_128_anikin_mantissa_extended                                                               : // lane a is [112:0]
            s_S1_metadata_anikin.sp_mode === TWO_SP_MODE ? {5'b00000, hs_S1_64a_anikin_mantissa_extended, 2'b00, hs_S1_64b_anikin_mantissa_extended}        : // lane a is [107:55], b is [52:0]
                                        /*FOUR_SP_MODE*/   {10'b00000_00000, hs_S1_32a_anikin_mantissa_extended, 2'b00, hs_S1_32b_anikin_mantissa_extended,   // lane a is [102:79], b is [76:53]
                                                            3'b000, hs_S1_32c_anikin_mantissa_extended, 2'b00, hs_S1_32d_anikin_mantissa_extended}            // lane c is [49:26], d is [23:0]
            ),
  .i_force(s_S1_metadata_anikin.sp_mode === SINGLE_MODE ? hs_S1_128_force_mantissa_extended                                                                 :
           s_S1_metadata_anikin.sp_mode === TWO_SP_MODE ? {5'b00000, hs_S1_64a_force_mantissa_extended, 2'b00, hs_S1_64b_force_mantissa_extended}           :
                                       /*FOUR_SP_MODE*/   {10'b00000_00000, hs_S1_32a_force_mantissa_extended, 2'b00, hs_S1_32b_force_mantissa_extended,
                                                          3'b000, hs_S1_32c_force_mantissa_extended, 2'b00, hs_S1_32d_force_mantissa_extended}
            ),
  .o_jedi(s_sp_intmultiplier_jedi),
  .i_valid_anikin(s_mul_launch),
  .i_valid_force(s_mul_launch),
  .o_valid_jedi(),
  .o_sanity_identifier(unused_sp_intmultiplier_sanity_identifier),
  .o_error(unused_sp_intmultiplier_error),
  .o_debug(unused_sp_intmultiplier_debug)
);
always_comb begin : sp_intmultiplier_output_unpack
  s_sink_128_mult_out_full = '0;
  s_sink_64a_mult_out_full = '0;
  s_sink_64b_mult_out_full = '0;
  s_sink_32a_mult_out_full = '0;
  s_sink_32b_mult_out_full = '0;
  s_sink_32c_mult_out_full = '0;
  s_sink_32d_mult_out_full = '0;

  case (s_db_metadata_anikin[INTMUL_LATENCY-1].sp_mode)
    SINGLE_MODE: begin
      s_sink_128_mult_out_full = s_sp_intmultiplier_jedi;
    end
    TWO_SP_MODE: begin
      s_sink_64a_mult_out_full = s_sp_intmultiplier_jedi[215:110];
      s_sink_64b_mult_out_full = s_sp_intmultiplier_jedi[105:0];
    end
    FOUR_SP_MODE: begin
      s_sink_32a_mult_out_full = s_sp_intmultiplier_jedi[205:158];
      s_sink_32b_mult_out_full = s_sp_intmultiplier_jedi[153:106];
      s_sink_32c_mult_out_full = s_sp_intmultiplier_jedi[99:52];
      s_sink_32d_mult_out_full = s_sp_intmultiplier_jedi[47:0];
    end
    default: begin
      // Keep all-zero defaults.
    end
  endcase // case (i_metadata.sp_mode)
end

/**
 * Delay buffer that keeps stage-1 sideband data aligned with the multiplier result.
 */
binary128_t s_db_128_jedi           [INTMUL_LATENCY-1 : 0];
binary128_t s_db_128_jedi_next      [INTMUL_LATENCY-1 : 0];
binary64_t  s_db_64a_jedi           [INTMUL_LATENCY-1 : 0],
            s_db_64b_jedi           [INTMUL_LATENCY-1 : 0];
binary64_t  s_db_64a_jedi_next      [INTMUL_LATENCY-1 : 0],
            s_db_64b_jedi_next      [INTMUL_LATENCY-1 : 0];
binary32_t  s_db_32a_jedi           [INTMUL_LATENCY-1 : 0],
            s_db_32b_jedi           [INTMUL_LATENCY-1 : 0],
            s_db_32c_jedi           [INTMUL_LATENCY-1 : 0],
            s_db_32d_jedi           [INTMUL_LATENCY-1 : 0];
binary32_t  s_db_32a_jedi_next      [INTMUL_LATENCY-1 : 0],
            s_db_32b_jedi_next      [INTMUL_LATENCY-1 : 0],
            s_db_32c_jedi_next      [INTMUL_LATENCY-1 : 0],
            s_db_32d_jedi_next      [INTMUL_LATENCY-1 : 0];
logic       s_db_valid128_jedi      [INTMUL_LATENCY-1 : 0];
logic       s_db_valid128_jedi_next [INTMUL_LATENCY-1 : 0];
logic       s_db_valid64a_jedi      [INTMUL_LATENCY-1 : 0],
            s_db_valid64b_jedi      [INTMUL_LATENCY-1 : 0];
logic       s_db_valid64a_jedi_next [INTMUL_LATENCY-1 : 0],
            s_db_valid64b_jedi_next [INTMUL_LATENCY-1 : 0];
logic       s_db_valid32a_jedi      [INTMUL_LATENCY-1 : 0],
            s_db_valid32b_jedi      [INTMUL_LATENCY-1 : 0],
            s_db_valid32c_jedi      [INTMUL_LATENCY-1 : 0],
            s_db_valid32d_jedi      [INTMUL_LATENCY-1 : 0];
logic       s_db_valid32a_jedi_next [INTMUL_LATENCY-1 : 0],
            s_db_valid32b_jedi_next [INTMUL_LATENCY-1 : 0],
            s_db_valid32c_jedi_next [INTMUL_LATENCY-1 : 0],
            s_db_valid32d_jedi_next [INTMUL_LATENCY-1 : 0];
assign s_db_128_jedi_next       = {s_db_128_jedi[INTMUL_LATENCY-2 : 0], s_S1_128_jedi};
assign s_db_valid128_jedi_next  = {s_db_valid128_jedi[INTMUL_LATENCY-2 : 0], s_S1_valid128_jedi};
assign s_db_64a_jedi_next       = {s_db_64a_jedi[INTMUL_LATENCY-2 : 0], s_S1_64a_jedi};
assign s_db_valid64a_jedi_next  = {s_db_valid64a_jedi[INTMUL_LATENCY-2 : 0], s_S1_valid64a_jedi};
assign s_db_64b_jedi_next       = {s_db_64b_jedi[INTMUL_LATENCY-2 : 0], s_S1_64b_jedi};
assign s_db_valid64b_jedi_next  = {s_db_valid64b_jedi[INTMUL_LATENCY-2 : 0], s_S1_valid64b_jedi};
assign s_db_32a_jedi_next       = {s_db_32a_jedi[INTMUL_LATENCY-2 : 0], s_S1_32a_jedi};
assign s_db_valid32a_jedi_next  = {s_db_valid32a_jedi[INTMUL_LATENCY-2 : 0], s_S1_valid32a_jedi};
assign s_db_32b_jedi_next       = {s_db_32b_jedi[INTMUL_LATENCY-2 : 0], s_S1_32b_jedi};
assign s_db_valid32b_jedi_next  = {s_db_valid32b_jedi[INTMUL_LATENCY-2 : 0], s_S1_valid32b_jedi};
assign s_db_32c_jedi_next       = {s_db_32c_jedi[INTMUL_LATENCY-2 : 0], s_S1_32c_jedi};
assign s_db_valid32c_jedi_next  = {s_db_valid32c_jedi[INTMUL_LATENCY-2 : 0], s_S1_valid32c_jedi};
assign s_db_32d_jedi_next       = {s_db_32d_jedi[INTMUL_LATENCY-2 : 0], s_S1_32d_jedi};
assign s_db_valid32d_jedi_next  = {s_db_valid32d_jedi[INTMUL_LATENCY-2 : 0], s_S1_valid32d_jedi};
// Now the metadata
float_metadata_t  s_db_metadata_anikin        [INTMUL_LATENCY-1 : 0],
                  s_db_metadata_force         [INTMUL_LATENCY-1 : 0];
float_metadata_t  s_db_metadata_anikin_next   [INTMUL_LATENCY-1 : 0],
                  s_db_metadata_force_next    [INTMUL_LATENCY-1 : 0];
assign s_db_metadata_anikin_next  = {s_db_metadata_anikin[INTMUL_LATENCY-2 : 0], s_S1_metadata_anikin};
assign s_db_metadata_force_next   = {s_db_metadata_force[INTMUL_LATENCY-2 : 0], s_S1_metadata_force};
always_ff @( posedge i_clk ) begin : intmult_sideband_delay
  if (!i_rst_n) begin
    s_db_128_jedi           <= '{default:'0};
    s_db_64a_jedi           <= '{default:'0};
    s_db_64b_jedi           <= '{default:'0};
    s_db_32a_jedi           <= '{default:'0};
    s_db_32b_jedi           <= '{default:'0};
    s_db_32c_jedi           <= '{default:'0};
    s_db_32d_jedi           <= '{default:'0};
    s_db_valid128_jedi      <= '{default:'0};
    s_db_valid64a_jedi      <= '{default:'0};
    s_db_valid64b_jedi      <= '{default:'0};
    s_db_valid32a_jedi      <= '{default:'0};
    s_db_valid32b_jedi      <= '{default:'0};
    s_db_valid32c_jedi      <= '{default:'0};
    s_db_valid32d_jedi      <= '{default:'0};
    
    s_db_metadata_anikin    <= '{default:'0};
    s_db_metadata_force     <= '{default:'0};
  end
  else begin
    s_db_128_jedi           <= s_db_128_jedi_next;
    s_db_64a_jedi           <= s_db_64a_jedi_next;
    s_db_64b_jedi           <= s_db_64b_jedi_next;
    s_db_32a_jedi           <= s_db_32a_jedi_next;
    s_db_32b_jedi           <= s_db_32b_jedi_next;
    s_db_32c_jedi           <= s_db_32c_jedi_next;
    s_db_32d_jedi           <= s_db_32d_jedi_next;
    s_db_valid128_jedi      <= s_db_valid128_jedi_next;
    s_db_valid64a_jedi      <= s_db_valid64a_jedi_next;
    s_db_valid64b_jedi      <= s_db_valid64b_jedi_next;
    s_db_valid32a_jedi      <= s_db_valid32a_jedi_next;
    s_db_valid32b_jedi      <= s_db_valid32b_jedi_next;
    s_db_valid32c_jedi      <= s_db_valid32c_jedi_next;
    s_db_valid32d_jedi      <= s_db_valid32d_jedi_next;

    s_db_metadata_anikin    <= s_db_metadata_anikin_next;
    s_db_metadata_force     <= s_db_metadata_force_next;
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

binary128_t       s_sink_128_jedi;
binary64_t        s_sink_64a_jedi, s_sink_64b_jedi;
binary32_t        s_sink_32a_jedi, s_sink_32b_jedi, s_sink_32c_jedi, s_sink_32d_jedi;
logic             s_sink_valid128_jedi;
logic             s_sink_valid64a_jedi, s_sink_valid64b_jedi;
logic             s_sink_valid32a_jedi, s_sink_valid32b_jedi, s_sink_valid32c_jedi, s_sink_valid32d_jedi;
float_metadata_t  s_sink_metadata_anikin, s_sink_metadata_force;
assign s_sink_128_jedi        = s_db_128_jedi[INTMUL_LATENCY-1];
assign s_sink_64a_jedi        = s_db_64a_jedi[INTMUL_LATENCY-1];
assign s_sink_64b_jedi        = s_db_64b_jedi[INTMUL_LATENCY-1];
assign s_sink_32a_jedi        = s_db_32a_jedi[INTMUL_LATENCY-1];
assign s_sink_32b_jedi        = s_db_32b_jedi[INTMUL_LATENCY-1];
assign s_sink_32c_jedi        = s_db_32c_jedi[INTMUL_LATENCY-1];
assign s_sink_32d_jedi        = s_db_32d_jedi[INTMUL_LATENCY-1];
assign s_sink_valid128_jedi   = s_db_valid128_jedi[INTMUL_LATENCY-1];
assign s_sink_valid64a_jedi   = s_db_valid64a_jedi[INTMUL_LATENCY-1];
assign s_sink_valid64b_jedi   = s_db_valid64b_jedi[INTMUL_LATENCY-1];
assign s_sink_valid32a_jedi   = s_db_valid32a_jedi[INTMUL_LATENCY-1];
assign s_sink_valid32b_jedi   = s_db_valid32b_jedi[INTMUL_LATENCY-1];
assign s_sink_valid32c_jedi   = s_db_valid32c_jedi[INTMUL_LATENCY-1];
assign s_sink_valid32d_jedi   = s_db_valid32d_jedi[INTMUL_LATENCY-1];
assign s_sink_metadata_anikin = s_db_metadata_anikin[INTMUL_LATENCY-1];
assign s_sink_metadata_force  = s_db_metadata_force[INTMUL_LATENCY-1];


/**
 * Round-to-nearest-even helpers used by stage 2.
*/
`define CARRY_IS_A_ONE(cb) ((cb) === 1'b1) // Checks if the top carry bit from n*n multiply is a 1.
function automatic logic [113:0] fn_round_postmul_128(input logic [225:0] i_full);
  logic hs_carry, hs_guard, hs_round, hs_sticky, hs_lsb, hs_round_up;
  logic [112:0] hs_kept;
  begin
    hs_carry = `CARRY_IS_A_ONE(i_full[225]);
    hs_kept  = hs_carry ? i_full[225:113] : i_full[224:112];
    hs_guard = hs_carry ? i_full[112] : i_full[111];
    hs_round = hs_carry ? i_full[111] : i_full[110];
    hs_sticky = hs_carry ? |i_full[110:0] : |i_full[109:0];
    hs_lsb = hs_carry ? i_full[113] : i_full[112];
    hs_round_up = (hs_guard === 1'b1) &&
                  ((hs_round === 1'b1) || (hs_sticky === 1'b1) || (hs_lsb === 1'b1));
    fn_round_postmul_128 = {1'b0, hs_kept} + hs_round_up;
  end
endfunction

function automatic logic [53:0] fn_round_postmul_64(input logic [105:0] i_full);
  logic hs_carry, hs_guard, hs_round, hs_sticky, hs_lsb, hs_round_up;
  logic [52:0] hs_kept;
  begin
    hs_carry = `CARRY_IS_A_ONE(i_full[105]);
    hs_kept  = hs_carry ? i_full[105:53] : i_full[104:52];
    hs_guard = hs_carry ? i_full[52] : i_full[51];
    hs_round = hs_carry ? i_full[51] : i_full[50];
    hs_sticky = hs_carry ? |i_full[50:0] : |i_full[49:0];
    hs_lsb = hs_carry ? i_full[53] : i_full[52];
    hs_round_up = (hs_guard === 1'b1) &&
                  ((hs_round === 1'b1) || (hs_sticky === 1'b1) || (hs_lsb === 1'b1));
    fn_round_postmul_64 = {1'b0, hs_kept} + hs_round_up;
  end
endfunction

function automatic logic [24:0] fn_round_postmul_32(input logic [47:0] i_full);
  logic hs_carry, hs_guard, hs_round, hs_sticky, hs_lsb, hs_round_up;
  logic [23:0] hs_kept;
  begin
    hs_carry = `CARRY_IS_A_ONE(i_full[47]);
    hs_kept  = hs_carry ? i_full[47:24] : i_full[46:23];
    hs_guard = hs_carry ? i_full[23] : i_full[22];
    hs_round = hs_carry ? i_full[22] : i_full[21];
    hs_sticky = hs_carry ? |i_full[21:0] : |i_full[20:0];
    hs_lsb = hs_carry ? i_full[24] : i_full[23];
    hs_round_up = (hs_guard === 1'b1) &&
                  ((hs_round === 1'b1) || (hs_sticky === 1'b1) || (hs_lsb === 1'b1));
    fn_round_postmul_32 = {1'b0, hs_kept} + hs_round_up;
  end
endfunction

//=====================================================================================
// Stage 2: rounding and carry-based exponent adjustment
//=====================================================================================
/**
 * After multiplication, we have the product (using binary128 as example):
 *              P_full = 1.b_1b_2b_3...b_112b_113b_114b_115...
 * To round it, or "normalize" it to 113 bits (including implicit 1), we need not only
 * the 113 bits (1.b_1b_2b_3...b_112), but also:
 *                              guard bit G = b_113
 *                              round bit R = b_114
 *                              sticky bit S = OR(b_115, b_116, ...)
 * 
 * So, rounding rule is:
 * 1. if G == 0: 1.b_1b_2b_3...b_112 is the rounded product P_norm
 * 2. if G == 1:
 *        if R == 1 or S == 1, P_norm = 1.b_1b_2b_3...b_112 + 1
 *        if R == 0 and S == 0,
 *            if b_112 == 1, P_norm = 1.b_1b_2b_3...b_112 + 1
 *            if b_112 == 0, P_norm = 1.b_1b_2b_3...b_112
 * 
 * Stage 2 will be:
 * After rounding, we need to check that the rounding didn't cause overflow (ie we 
 * get a 10.0000.... after we increment by 1)
 * if that is the case (overflow), we increment the exponent by 1 again and shift
 * P_norm right by 1 so that it goes back to being 1.000000....
 * 
 * This is called RN-even: Round to nearest, ties to even
 */
logic [113:0] s_S2_128_potential_result;
logic [53:0]  s_S2_64a_potential_result;
logic [53:0]  s_S2_64b_potential_result;
logic [24:0]  s_S2_32a_potential_result;
logic [24:0]  s_S2_32b_potential_result;
logic [24:0]  s_S2_32c_potential_result;
logic [24:0]  s_S2_32d_potential_result;
binary128_t   s_S2_128_jedi;
binary64_t    s_S2_64a_jedi, s_S2_64b_jedi;
binary32_t    s_S2_32a_jedi, s_S2_32b_jedi, s_S2_32c_jedi, s_S2_32d_jedi;
logic         s_S2_valid128_jedi;
logic         s_S2_valid64a_jedi, s_S2_valid64b_jedi;
logic         s_S2_valid32a_jedi, s_S2_valid32b_jedi, s_S2_valid32c_jedi, s_S2_valid32d_jedi;
float_metadata_t s_S2_metadata_anikin, s_S2_metadata_force;
always_ff @( posedge i_clk ) begin : stage2_round
  logic [113:0] hs_S2_128_potential_result;
  logic [53:0]  hs_S2_64a_potential_result;
  logic [53:0]  hs_S2_64b_potential_result;
  logic [24:0]  hs_S2_32a_potential_result;
  logic [24:0]  hs_S2_32b_potential_result;
  logic [24:0]  hs_S2_32c_potential_result;
  logic [24:0]  hs_S2_32d_potential_result;
  binary128_t   hs_S2_128_jedi;
  binary64_t    hs_S2_64a_jedi, hs_S2_64b_jedi;
  binary32_t    hs_S2_32a_jedi, hs_S2_32b_jedi, hs_S2_32c_jedi, hs_S2_32d_jedi;

  if (!i_rst_n) begin
    s_S2_128_jedi             <= '0;
    s_S2_64a_jedi             <= '0;
    s_S2_64b_jedi             <= '0;
    s_S2_32a_jedi             <= '0;
    s_S2_32b_jedi             <= '0;
    s_S2_32c_jedi             <= '0;
    s_S2_32d_jedi             <= '0;
    s_S2_128_potential_result <= '0;
    s_S2_64a_potential_result <= '0;
    s_S2_64b_potential_result <= '0;
    s_S2_32a_potential_result <= '0;
    s_S2_32b_potential_result <= '0;
    s_S2_32c_potential_result <= '0;
    s_S2_32d_potential_result <= '0;
    s_S2_valid128_jedi        <= '0;
    s_S2_valid64a_jedi        <= '0;
    s_S2_valid64b_jedi        <= '0;
    s_S2_valid32a_jedi        <= '0;
    s_S2_valid32b_jedi        <= '0;
    s_S2_valid32c_jedi        <= '0;
    s_S2_valid32d_jedi        <= '0;
    s_S2_metadata_anikin      <= '0;
    s_S2_metadata_force       <= '0;

    s_o_error[3]              <= 1'b0;
    s_o_error[4]              <= 1'b0;
    s_o_error[7]              <= 1'b0;
    s_o_error[8]              <= 1'b0;
    s_o_error[9]              <= 1'b0;
    s_o_error[10]             <= 1'b0;
  end
  else begin
    if (s_S2_en) begin
      hs_S2_128_potential_result = fn_round_postmul_128(s_sink_128_mult_out_full);
      hs_S2_64a_potential_result = fn_round_postmul_64(s_sink_64a_mult_out_full);
      hs_S2_64b_potential_result = fn_round_postmul_64(s_sink_64b_mult_out_full);
      hs_S2_32a_potential_result = fn_round_postmul_32(s_sink_32a_mult_out_full);
      hs_S2_32b_potential_result = fn_round_postmul_32(s_sink_32b_mult_out_full);
      hs_S2_32c_potential_result = fn_round_postmul_32(s_sink_32c_mult_out_full);
      hs_S2_32d_potential_result = fn_round_postmul_32(s_sink_32d_mult_out_full);

      hs_S2_128_jedi = s_sink_128_jedi;
      hs_S2_64a_jedi = s_sink_64a_jedi;
      hs_S2_64b_jedi = s_sink_64b_jedi;
      hs_S2_32a_jedi = s_sink_32a_jedi;
      hs_S2_32b_jedi = s_sink_32b_jedi;
      hs_S2_32c_jedi = s_sink_32c_jedi;
      hs_S2_32d_jedi = s_sink_32d_jedi;
      hs_S2_128_jedi.exp = `CARRY_IS_A_ONE(s_sink_128_mult_out_full[225]) ? (s_sink_128_jedi.exp + 1'b1) : s_sink_128_jedi.exp;
      hs_S2_64a_jedi.exp = `CARRY_IS_A_ONE(s_sink_64a_mult_out_full[105]) ? (s_sink_64a_jedi.exp + 1'b1) : s_sink_64a_jedi.exp;
      hs_S2_64b_jedi.exp = `CARRY_IS_A_ONE(s_sink_64b_mult_out_full[105]) ? (s_sink_64b_jedi.exp + 1'b1) : s_sink_64b_jedi.exp;
      hs_S2_32a_jedi.exp = `CARRY_IS_A_ONE(s_sink_32a_mult_out_full[47])  ? (s_sink_32a_jedi.exp + 1'b1) : s_sink_32a_jedi.exp;
      hs_S2_32b_jedi.exp = `CARRY_IS_A_ONE(s_sink_32b_mult_out_full[47])  ? (s_sink_32b_jedi.exp + 1'b1) : s_sink_32b_jedi.exp;
      hs_S2_32c_jedi.exp = `CARRY_IS_A_ONE(s_sink_32c_mult_out_full[47])  ? (s_sink_32c_jedi.exp + 1'b1) : s_sink_32c_jedi.exp;
      hs_S2_32d_jedi.exp = `CARRY_IS_A_ONE(s_sink_32d_mult_out_full[47])  ? (s_sink_32d_jedi.exp + 1'b1) : s_sink_32d_jedi.exp;

      assert (s_sink_metadata_anikin.sp_mode === s_sink_metadata_force.sp_mode) else begin
        s_o_error[7] <= 1'b1;
        s_o_error[8] <= 1'b1;
        s_o_error[9] <= 1'b1;
      end

      case (s_sink_metadata_anikin.sp_mode)
        SINGLE_MODE: begin
          s_S2_128_jedi             <= hs_S2_128_jedi;
          s_S2_128_potential_result <= hs_S2_128_potential_result;
        end

        TWO_SP_MODE: begin
          s_S2_64a_jedi             <= hs_S2_64a_jedi;
          s_S2_64a_potential_result <= hs_S2_64a_potential_result;
          s_S2_64b_jedi             <= hs_S2_64b_jedi;
          s_S2_64b_potential_result <= hs_S2_64b_potential_result;
        end

        FOUR_SP_MODE: begin
          s_S2_32a_jedi             <= hs_S2_32a_jedi;
          s_S2_32a_potential_result <= hs_S2_32a_potential_result;
          s_S2_32b_jedi             <= hs_S2_32b_jedi;
          s_S2_32b_potential_result <= hs_S2_32b_potential_result;
          s_S2_32c_jedi             <= hs_S2_32c_jedi;
          s_S2_32c_potential_result <= hs_S2_32c_potential_result;
          s_S2_32d_jedi             <= hs_S2_32d_jedi;
          s_S2_32d_potential_result <= hs_S2_32d_potential_result;
        end

        default: begin
          assert (0) else begin
            s_o_error[3]  <= 1'b1;
            s_o_error[4]  <= 1'b1;
            s_o_error[10] <= 1'b1;
          end
        end
      endcase

      s_S2_valid128_jedi   <= s_sink_valid128_jedi;
      s_S2_valid64a_jedi   <= s_sink_valid64a_jedi;
      s_S2_valid64b_jedi   <= s_sink_valid64b_jedi;
      s_S2_valid32a_jedi   <= s_sink_valid32a_jedi;
      s_S2_valid32b_jedi   <= s_sink_valid32b_jedi;
      s_S2_valid32c_jedi   <= s_sink_valid32c_jedi;
      s_S2_valid32d_jedi   <= s_sink_valid32d_jedi;
      s_S2_metadata_anikin <= s_sink_metadata_anikin;
      s_S2_metadata_force  <= s_sink_metadata_force;
    end
  end
end

//=====================================================================================
// Stage 3: Renormalize the rounded result if the stage-2 increment overflowed
//=====================================================================================
logic [113:0] s_S3_128_potential_result;
logic [53:0]  s_S3_64a_potential_result;
logic [53:0]  s_S3_64b_potential_result;
logic [24:0]  s_S3_32a_potential_result;
logic [24:0]  s_S3_32b_potential_result;
logic [24:0]  s_S3_32c_potential_result;
logic [24:0]  s_S3_32d_potential_result;
binary128_t   s_S3_128_jedi;
binary64_t    s_S3_64a_jedi, s_S3_64b_jedi;
binary32_t    s_S3_32a_jedi, s_S3_32b_jedi, s_S3_32c_jedi, s_S3_32d_jedi;
logic         s_S3_valid128_jedi;
logic         s_S3_valid64a_jedi, s_S3_valid64b_jedi;
logic         s_S3_valid32a_jedi, s_S3_valid32b_jedi, s_S3_valid32c_jedi, s_S3_valid32d_jedi;
float_metadata_t s_S3_metadata_anikin, s_S3_metadata_force;
always_ff @( posedge i_clk ) begin : stage3_renormalize
  if (!i_rst_n) begin
    s_S3_128_jedi             <= '0;
    s_S3_64a_jedi             <= '0;
    s_S3_64b_jedi             <= '0;
    s_S3_32a_jedi             <= '0;
    s_S3_32b_jedi             <= '0;
    s_S3_32c_jedi             <= '0;
    s_S3_32d_jedi             <= '0;
    s_S3_128_potential_result <= '0;
    s_S3_64a_potential_result <= '0;
    s_S3_64b_potential_result <= '0;
    s_S3_32a_potential_result <= '0;
    s_S3_32b_potential_result <= '0;
    s_S3_32c_potential_result <= '0;
    s_S3_32d_potential_result <= '0;
    s_S3_valid128_jedi        <= '0;
    s_S3_valid64a_jedi        <= '0;
    s_S3_valid64b_jedi        <= '0;
    s_S3_valid32a_jedi        <= '0;
    s_S3_valid32b_jedi        <= '0;
    s_S3_valid32c_jedi        <= '0;
    s_S3_valid32d_jedi        <= '0;
    s_S3_metadata_anikin      <= '0;
    s_S3_metadata_force       <= '0;
  end
  else begin
    if (s_S3_en) begin
      case (s_S2_metadata_anikin.sp_mode)
        SINGLE_MODE: begin
          if (s_S2_128_potential_result[113] === 1'b1) begin
            s_S3_128_jedi.exp         <= s_S2_128_jedi.exp + 1'b1;
            s_S3_128_jedi.sign        <= s_S2_128_jedi.sign;
            s_S3_128_jedi.mantissa    <= s_S2_128_jedi.mantissa;
            s_S3_128_potential_result <= {1'b0, s_S2_128_potential_result[113:1]};
          end
          else begin
            s_S3_128_jedi             <= s_S2_128_jedi;
            s_S3_128_potential_result <= s_S2_128_potential_result;
          end
        end

        TWO_SP_MODE: begin
          if (s_S2_64a_potential_result[53] === 1'b1) begin
            s_S3_64a_jedi.exp         <= s_S2_64a_jedi.exp + 1'b1;
            s_S3_64a_jedi.sign        <= s_S2_64a_jedi.sign;
            s_S3_64a_jedi.mantissa    <= s_S2_64a_jedi.mantissa;
            s_S3_64a_potential_result <= {1'b0, s_S2_64a_potential_result[53:1]};
          end
          else begin
            s_S3_64a_jedi             <= s_S2_64a_jedi;
            s_S3_64a_potential_result <= s_S2_64a_potential_result;
          end

          if (s_S2_64b_potential_result[53] === 1'b1) begin
            s_S3_64b_jedi.exp         <= s_S2_64b_jedi.exp + 1'b1;
            s_S3_64b_jedi.sign        <= s_S2_64b_jedi.sign;
            s_S3_64b_jedi.mantissa    <= s_S2_64b_jedi.mantissa;
            s_S3_64b_potential_result <= {1'b0, s_S2_64b_potential_result[53:1]};
          end
          else begin
            s_S3_64b_jedi             <= s_S2_64b_jedi;
            s_S3_64b_potential_result <= s_S2_64b_potential_result;
          end
        end

        FOUR_SP_MODE: begin
          if (s_S2_32a_potential_result[24] === 1'b1) begin
            s_S3_32a_jedi.exp         <= s_S2_32a_jedi.exp + 1'b1;
            s_S3_32a_jedi.sign        <= s_S2_32a_jedi.sign;
            s_S3_32a_jedi.mantissa    <= s_S2_32a_jedi.mantissa;
            s_S3_32a_potential_result <= {1'b0, s_S2_32a_potential_result[24:1]};
          end
          else begin
            s_S3_32a_jedi             <= s_S2_32a_jedi;
            s_S3_32a_potential_result <= s_S2_32a_potential_result;
          end

          if (s_S2_32b_potential_result[24] === 1'b1) begin
            s_S3_32b_jedi.exp         <= s_S2_32b_jedi.exp + 1'b1;
            s_S3_32b_jedi.sign        <= s_S2_32b_jedi.sign;
            s_S3_32b_jedi.mantissa    <= s_S2_32b_jedi.mantissa;
            s_S3_32b_potential_result <= {1'b0, s_S2_32b_potential_result[24:1]};
          end
          else begin
            s_S3_32b_jedi             <= s_S2_32b_jedi;
            s_S3_32b_potential_result <= s_S2_32b_potential_result;
          end

          if (s_S2_32c_potential_result[24] === 1'b1) begin
            s_S3_32c_jedi.exp         <= s_S2_32c_jedi.exp + 1'b1;
            s_S3_32c_jedi.sign        <= s_S2_32c_jedi.sign;
            s_S3_32c_jedi.mantissa    <= s_S2_32c_jedi.mantissa;
            s_S3_32c_potential_result <= {1'b0, s_S2_32c_potential_result[24:1]};
          end
          else begin
            s_S3_32c_jedi             <= s_S2_32c_jedi;
            s_S3_32c_potential_result <= s_S2_32c_potential_result;
          end

          if (s_S2_32d_potential_result[24] === 1'b1) begin
            s_S3_32d_jedi.exp         <= s_S2_32d_jedi.exp + 1'b1;
            s_S3_32d_jedi.sign        <= s_S2_32d_jedi.sign;
            s_S3_32d_jedi.mantissa    <= s_S2_32d_jedi.mantissa;
            s_S3_32d_potential_result <= {1'b0, s_S2_32d_potential_result[24:1]};
          end
          else begin
            s_S3_32d_jedi             <= s_S2_32d_jedi;
            s_S3_32d_potential_result <= s_S2_32d_potential_result;
          end
        end

        default: begin
          // Keep previous contents on invalid mode.
        end
      endcase

      s_S3_valid128_jedi   <= s_S2_valid128_jedi;
      s_S3_valid64a_jedi   <= s_S2_valid64a_jedi;
      s_S3_valid64b_jedi   <= s_S2_valid64b_jedi;
      s_S3_valid32a_jedi   <= s_S2_valid32a_jedi;
      s_S3_valid32b_jedi   <= s_S2_valid32b_jedi;
      s_S3_valid32c_jedi   <= s_S2_valid32c_jedi;
      s_S3_valid32d_jedi   <= s_S2_valid32d_jedi;
      s_S3_metadata_anikin <= s_S2_metadata_anikin;
      s_S3_metadata_force  <= s_S2_metadata_force;
    end
  end
end


//=====================================================================================
// Stage 4: Pack the rounded mantissa and handle special-case outputs
//=====================================================================================
binary128_t   s_S4_128_jedi;
binary64_t    s_S4_64a_jedi, s_S4_64b_jedi;
binary32_t    s_S4_32a_jedi, s_S4_32b_jedi, s_S4_32c_jedi, s_S4_32d_jedi;
always_ff @( posedge i_clk ) begin : stage4_pack_output
  if (!i_rst_n) begin
    s_S4_128_jedi <= '0;
    s_S4_64a_jedi <= '0;
    s_S4_64b_jedi <= '0;
    s_S4_32a_jedi <= '0;
    s_S4_32b_jedi <= '0;
    s_S4_32c_jedi <= '0;
    s_S4_32d_jedi <= '0;
    s_o_error[11] <= 1'b0;
    s_o_error[12] <= 1'b0;
    s_o_error[13] <= 1'b0;
    s_o_error[14] <= 1'b0;
    s_o_error[15] <= 1'b0;
    s_o_error[16] <= 1'b0;
    s_o_error[17] <= 1'b0;
    s_o_error[18] <= 1'b0;
    s_o_error[19] <= 1'b0;
  end
  else begin
    if (s_S4_en) begin
      assert (s_S3_metadata_anikin.sp_mode === s_S3_metadata_force.sp_mode) else begin
        s_o_error[11] <= 1'b1;
        // $fatal(1, "Bad things had happened, (s_S3_metadata_anikin.sp_mode === s_S3_metadata_force.sp_mode) is false.");
      end
      case (s_S3_metadata_anikin.sp_mode)
        SINGLE_MODE: begin
          if (!(s_S3_metadata_anikin.float_type_a === ZERO || s_S3_metadata_force.float_type_a === ZERO) && 
              ((s_S3_metadata_anikin.float_type_a === NAN || s_S3_metadata_force.float_type_a === NAN) ||
              (s_S3_128_jedi.exp === '1 && s_S3_128_potential_result[111:0] !== '0 && s_S3_128_potential_result[111:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S4_128_jedi.sign      <= s_S3_128_jedi.sign;
            s_S4_128_jedi.exp       <= '1;
            s_S4_128_jedi.mantissa  <= 112'hA; // non-0
          end
          else if (s_S3_metadata_anikin.float_type_a === ZERO || s_S3_metadata_force.float_type_a === ZERO) begin
            // If either is a zero, output will be a zero
            s_S4_128_jedi.sign      <= s_S3_128_jedi.sign;
            s_S4_128_jedi.exp       <= '0;
            s_S4_128_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_a === POS_INF || s_S3_metadata_force.float_type_a === POS_INF) ||
                   (s_S3_128_jedi.sign === '0 && s_S3_128_jedi.exp === '1 && s_S3_128_potential_result[111:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S4_128_jedi.sign      <= 1'b0;
            s_S4_128_jedi.exp       <= '1;
            s_S4_128_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_a === NEG_INF || s_S3_metadata_force.float_type_a === NEG_INF) ||
                   (s_S3_128_jedi.sign === '1 && s_S3_128_jedi.exp === '1 && s_S3_128_potential_result[111:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S4_128_jedi.sign      <= 1'b1;
            s_S4_128_jedi.exp       <= '1;
            s_S4_128_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S3_metadata_anikin.float_type_a === POS_DENORMAL || s_S3_metadata_force.float_type_a === POS_DENORMAL) ||
                   (s_S3_metadata_anikin.float_type_a === NEG_DENORMAL || s_S3_metadata_force.float_type_a === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S4_128_jedi.sign      <= s_S3_128_jedi.sign;
            s_S4_128_jedi.exp       <= '0;
            s_S4_128_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S3_128_potential_result[112] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[12] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S4_128_jedi.sign      <= s_S3_128_jedi.sign;
            s_S4_128_jedi.exp       <= s_S3_128_jedi.exp;
            s_S4_128_jedi.mantissa  <= s_S3_128_potential_result[111:0];
          end
        end // SINGLE_MODE

        TWO_SP_MODE: begin
          if (!(s_S3_metadata_anikin.float_type_a === ZERO || s_S3_metadata_force.float_type_a === ZERO) &&
              ((s_S3_metadata_anikin.float_type_a === NAN || s_S3_metadata_force.float_type_a === NAN) ||
              (s_S3_64a_jedi.exp === '1 && s_S3_64a_potential_result[51:0] !== '0 && s_S3_64a_potential_result[51:0] !== '1))) begin
            // If either is NaN, output will be NaN.
            s_S4_64a_jedi.sign      <= s_S3_64a_jedi.sign;
            s_S4_64a_jedi.exp       <= '1;
            s_S4_64a_jedi.mantissa  <= 52'hA; // non-0
          end
          else if (s_S3_metadata_anikin.float_type_a === ZERO || s_S3_metadata_force.float_type_a === ZERO) begin
            // If either is a zero, output will be a zero
            s_S4_64a_jedi.sign      <= s_S3_64a_jedi.sign;
            s_S4_64a_jedi.exp       <= '0;
            s_S4_64a_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_a === POS_INF || s_S3_metadata_force.float_type_a === POS_INF) ||
                   (s_S3_64a_jedi.sign === '0 && s_S3_64a_jedi.exp === '1 && s_S3_64a_potential_result[51:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S4_64a_jedi.sign      <= 1'b0;
            s_S4_64a_jedi.exp       <= '1;
            s_S4_64a_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_a === NEG_INF || s_S3_metadata_force.float_type_a === NEG_INF) ||
                   (s_S3_64a_jedi.sign === '1 && s_S3_64a_jedi.exp === '1 && s_S3_64a_potential_result[51:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S4_64a_jedi.sign      <= 1'b1;
            s_S4_64a_jedi.exp       <= '1;
            s_S4_64a_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S3_metadata_anikin.float_type_a === POS_DENORMAL || s_S3_metadata_force.float_type_a === POS_DENORMAL) ||
                   (s_S3_metadata_anikin.float_type_a === NEG_DENORMAL || s_S3_metadata_force.float_type_a === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S4_64a_jedi.sign      <= s_S3_64a_jedi.sign;
            s_S4_64a_jedi.exp       <= '0;
            s_S4_64a_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S3_64a_potential_result[52] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[13] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S4_64a_jedi.sign      <= s_S3_64a_jedi.sign;
            s_S4_64a_jedi.exp       <= s_S3_64a_jedi.exp;
            s_S4_64a_jedi.mantissa  <= s_S3_64a_potential_result[51:0];
          end

          if (!(s_S3_metadata_anikin.float_type_b === ZERO || s_S3_metadata_force.float_type_b === ZERO) &&
              ((s_S3_metadata_anikin.float_type_b === NAN || s_S3_metadata_force.float_type_b === NAN) ||
              (s_S3_64b_jedi.exp === '1 && s_S3_64b_potential_result[51:0] !== '0 && s_S3_64b_potential_result[51:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S4_64b_jedi.sign      <= s_S3_64b_jedi.sign;
            s_S4_64b_jedi.exp       <= '1;
            s_S4_64b_jedi.mantissa  <= 52'hA; // non-0
          end
          else if (s_S3_metadata_anikin.float_type_b === ZERO || s_S3_metadata_force.float_type_b === ZERO) begin
            // If either is a zero, output will be a zero
            s_S4_64b_jedi.sign      <= s_S3_64b_jedi.sign;
            s_S4_64b_jedi.exp       <= '0;
            s_S4_64b_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_b === POS_INF || s_S3_metadata_force.float_type_b === POS_INF) ||
                   (s_S3_64b_jedi.sign === '0 && s_S3_64b_jedi.exp === '1 && s_S3_64b_potential_result[51:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S4_64b_jedi.sign      <= 1'b0;
            s_S4_64b_jedi.exp       <= '1;
            s_S4_64b_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_b === NEG_INF || s_S3_metadata_force.float_type_b === NEG_INF) ||
                   (s_S3_64b_jedi.sign === '1 && s_S3_64b_jedi.exp === '1 && s_S3_64b_potential_result[51:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S4_64b_jedi.sign      <= 1'b1;
            s_S4_64b_jedi.exp       <= '1;
            s_S4_64b_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S3_metadata_anikin.float_type_b === POS_DENORMAL || s_S3_metadata_force.float_type_b === POS_DENORMAL) ||
                   (s_S3_metadata_anikin.float_type_b === NEG_DENORMAL || s_S3_metadata_force.float_type_b === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S4_64b_jedi.sign      <= s_S3_64b_jedi.sign;
            s_S4_64b_jedi.exp       <= '0;
            s_S4_64b_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S3_64b_potential_result[52] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[14] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S4_64b_jedi.sign      <= s_S3_64b_jedi.sign;
            s_S4_64b_jedi.exp       <= s_S3_64b_jedi.exp;
            s_S4_64b_jedi.mantissa  <= s_S3_64b_potential_result[51:0];
          end
        end // TWO_SP_MODE

        FOUR_SP_MODE: begin
          if (!(s_S3_metadata_anikin.float_type_a === ZERO || s_S3_metadata_force.float_type_a === ZERO) &&
              ((s_S3_metadata_anikin.float_type_a === NAN || s_S3_metadata_force.float_type_a === NAN) ||
              (s_S3_32a_jedi.exp === '1 && s_S3_32a_potential_result[22:0] !== '0 && s_S3_32a_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S4_32a_jedi.sign      <= s_S3_32a_jedi.sign;
            s_S4_32a_jedi.exp       <= '1;
            s_S4_32a_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S3_metadata_anikin.float_type_a === ZERO || s_S3_metadata_force.float_type_a === ZERO) begin
            // If either is a zero, output will be a zero
            s_S4_32a_jedi.sign      <= s_S3_32a_jedi.sign;
            s_S4_32a_jedi.exp       <= '0;
            s_S4_32a_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_a === POS_INF || s_S3_metadata_force.float_type_a === POS_INF) ||
                   (s_S3_32a_jedi.sign === '0 && s_S3_32a_jedi.exp === '1 && s_S3_32a_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S4_32a_jedi.sign      <= 1'b0;
            s_S4_32a_jedi.exp       <= '1;
            s_S4_32a_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_a === NEG_INF || s_S3_metadata_force.float_type_a === NEG_INF) ||
                   (s_S3_32a_jedi.sign === '1 && s_S3_32a_jedi.exp === '1 && s_S3_32a_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S4_32a_jedi.sign      <= 1'b1;
            s_S4_32a_jedi.exp       <= '1;
            s_S4_32a_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S3_metadata_anikin.float_type_a === POS_DENORMAL || s_S3_metadata_force.float_type_a === POS_DENORMAL) ||
                   (s_S3_metadata_anikin.float_type_a === NEG_DENORMAL || s_S3_metadata_force.float_type_a === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S4_32a_jedi.sign      <= s_S3_32a_jedi.sign;
            s_S4_32a_jedi.exp       <= '0;
            s_S4_32a_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S3_32a_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[15] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S4_32a_jedi.sign      <= s_S3_32a_jedi.sign;
            s_S4_32a_jedi.exp       <= s_S3_32a_jedi.exp;
            s_S4_32a_jedi.mantissa  <= s_S3_32a_potential_result[22:0];
          end


          if (!(s_S3_metadata_anikin.float_type_b === ZERO || s_S3_metadata_force.float_type_b === ZERO) &&
              ((s_S3_metadata_anikin.float_type_b === NAN || s_S3_metadata_force.float_type_b === NAN) ||
              (s_S3_32b_jedi.exp === '1 && s_S3_32b_potential_result[22:0] !== '0 && s_S3_32b_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S4_32b_jedi.sign      <= s_S3_32b_jedi.sign;
            s_S4_32b_jedi.exp       <= '1;
            s_S4_32b_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S3_metadata_anikin.float_type_b === ZERO || s_S3_metadata_force.float_type_b === ZERO) begin
            // If either is a zero, output will be a zero
            s_S4_32b_jedi.sign      <= s_S3_32b_jedi.sign;
            s_S4_32b_jedi.exp       <= '0;
            s_S4_32b_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_b === POS_INF || s_S3_metadata_force.float_type_b === POS_INF) ||
                   (s_S3_32b_jedi.sign === '0 && s_S3_32b_jedi.exp === '1 && s_S3_32b_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S4_32b_jedi.sign      <= 1'b0;
            s_S4_32b_jedi.exp       <= '1;
            s_S4_32b_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_b === NEG_INF || s_S3_metadata_force.float_type_b === NEG_INF) ||
                   (s_S3_32b_jedi.sign === '1 && s_S3_32b_jedi.exp === '1 && s_S3_32b_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S4_32b_jedi.sign      <= 1'b1;
            s_S4_32b_jedi.exp       <= '1;
            s_S4_32b_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S3_metadata_anikin.float_type_b === POS_DENORMAL || s_S3_metadata_force.float_type_b === POS_DENORMAL) ||
                   (s_S3_metadata_anikin.float_type_b === NEG_DENORMAL || s_S3_metadata_force.float_type_b === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S4_32b_jedi.sign      <= s_S3_32b_jedi.sign;
            s_S4_32b_jedi.exp       <= '0;
            s_S4_32b_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S3_32b_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[16] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S4_32b_jedi.sign      <= s_S3_32b_jedi.sign;
            s_S4_32b_jedi.exp       <= s_S3_32b_jedi.exp;
            s_S4_32b_jedi.mantissa  <= s_S3_32b_potential_result[22:0];
          end


          if (!(s_S3_metadata_anikin.float_type_c === ZERO || s_S3_metadata_force.float_type_c === ZERO) &&
              ((s_S3_metadata_anikin.float_type_c === NAN || s_S3_metadata_force.float_type_c === NAN) ||
              (s_S3_32c_jedi.exp === '1 && s_S3_32c_potential_result[22:0] !== '0 && s_S3_32c_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S4_32c_jedi.sign      <= s_S3_32c_jedi.sign;
            s_S4_32c_jedi.exp       <= '1;
            s_S4_32c_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S3_metadata_anikin.float_type_c === ZERO || s_S3_metadata_force.float_type_c === ZERO) begin
            // If either is a zero, output will be a zero
            s_S4_32c_jedi.sign      <= s_S3_32c_jedi.sign;
            s_S4_32c_jedi.exp       <= '0;
            s_S4_32c_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_c === POS_INF || s_S3_metadata_force.float_type_c === POS_INF) ||
                   (s_S3_32c_jedi.sign === '0 && s_S3_32c_jedi.exp === '1 && s_S3_32c_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S4_32c_jedi.sign      <= 1'b0;
            s_S4_32c_jedi.exp       <= '1;
            s_S4_32c_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_c === NEG_INF || s_S3_metadata_force.float_type_c === NEG_INF) ||
                   (s_S3_32c_jedi.sign === '1 && s_S3_32c_jedi.exp === '1 && s_S3_32c_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S4_32c_jedi.sign      <= 1'b1;
            s_S4_32c_jedi.exp       <= '1;
            s_S4_32c_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S3_metadata_anikin.float_type_c === POS_DENORMAL || s_S3_metadata_force.float_type_c === POS_DENORMAL) ||
                   (s_S3_metadata_anikin.float_type_c === NEG_DENORMAL || s_S3_metadata_force.float_type_c === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S4_32c_jedi.sign      <= s_S3_32c_jedi.sign;
            s_S4_32c_jedi.exp       <= '0;
            s_S4_32c_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S3_32c_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[17] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S4_32c_jedi.sign      <= s_S3_32c_jedi.sign;
            s_S4_32c_jedi.exp       <= s_S3_32c_jedi.exp;
            s_S4_32c_jedi.mantissa  <= s_S3_32c_potential_result[22:0];
          end

          
          if (!(s_S3_metadata_anikin.float_type_d === ZERO || s_S3_metadata_force.float_type_d === ZERO) &&
              ((s_S3_metadata_anikin.float_type_d === NAN || s_S3_metadata_force.float_type_d === NAN) ||
              (s_S3_32d_jedi.exp === '1 && s_S3_32d_potential_result[22:0] !== '0 && s_S3_32d_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S4_32d_jedi.sign      <= s_S3_32d_jedi.sign;
            s_S4_32d_jedi.exp       <= '1;
            s_S4_32d_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S3_metadata_anikin.float_type_d === ZERO || s_S3_metadata_force.float_type_d === ZERO) begin
            // If either is a zero, output will be a zero
            s_S4_32d_jedi.sign      <= s_S3_32d_jedi.sign;
            s_S4_32d_jedi.exp       <= '0;
            s_S4_32d_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_d === POS_INF || s_S3_metadata_force.float_type_d === POS_INF) ||
                   (s_S3_32d_jedi.sign === '0 && s_S3_32d_jedi.exp === '1 && s_S3_32d_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S4_32d_jedi.sign      <= 1'b0;
            s_S4_32d_jedi.exp       <= '1;
            s_S4_32d_jedi.mantissa  <= '0;
          end
          else if ((s_S3_metadata_anikin.float_type_d === NEG_INF || s_S3_metadata_force.float_type_d === NEG_INF) ||
                   (s_S3_32d_jedi.sign === '1 && s_S3_32d_jedi.exp === '1 && s_S3_32d_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S4_32d_jedi.sign      <= 1'b1;
            s_S4_32d_jedi.exp       <= '1;
            s_S4_32d_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S3_metadata_anikin.float_type_d === POS_DENORMAL || s_S3_metadata_force.float_type_d === POS_DENORMAL) ||
                   (s_S3_metadata_anikin.float_type_d === NEG_DENORMAL || s_S3_metadata_force.float_type_d === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S4_32d_jedi.sign      <= s_S3_32d_jedi.sign;
            s_S4_32d_jedi.exp       <= '0;
            s_S4_32d_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S3_32d_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[18] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S4_32d_jedi.sign      <= s_S3_32d_jedi.sign;
            s_S4_32d_jedi.exp       <= s_S3_32d_jedi.exp;
            s_S4_32d_jedi.mantissa  <= s_S3_32d_potential_result[22:0];
          end
        end // FOUR_SP_MODE

        default: begin
          assert (0) else begin
            s_o_error[19] <= 1'b1;
          end
        end
      endcase // case (i_metadata.sp_mode)
    end // if (s_S4_en) begin
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

/**
 * Final valid/metadata passthrough.
 */
logic             s_S4_valid128_jedi;
logic             s_S4_valid64a_jedi, s_S4_valid64b_jedi;
logic             s_S4_valid32a_jedi, s_S4_valid32b_jedi, s_S4_valid32c_jedi, s_S4_valid32d_jedi;
float_metadata_t  s_S4_metadata_anikin, s_S4_metadata_force;
always_ff @( posedge i_clk ) begin : stage4_signal_passthrough
  if (!i_rst_n) begin
    s_S4_valid128_jedi    <= '0;
    s_S4_valid64a_jedi    <= '0;
    s_S4_valid64b_jedi    <= '0;
    s_S4_valid32a_jedi    <= '0;
    s_S4_valid32b_jedi    <= '0;
    s_S4_valid32c_jedi    <= '0;
    s_S4_valid32d_jedi    <= '0;

    s_S4_metadata_anikin  <= '0;
    s_S4_metadata_force   <= '0;
  end
  else begin
    if (s_S4_en) begin
      // valid bit pass through
      s_S4_valid128_jedi    <= s_S3_valid128_jedi;
      s_S4_valid64a_jedi    <= s_S3_valid64a_jedi;
      s_S4_valid64b_jedi    <= s_S3_valid64b_jedi;
      s_S4_valid32a_jedi    <= s_S3_valid32a_jedi;
      s_S4_valid32b_jedi    <= s_S3_valid32b_jedi;
      s_S4_valid32c_jedi    <= s_S3_valid32c_jedi;
      s_S4_valid32d_jedi    <= s_S3_valid32d_jedi;

      // metadata
      s_S4_metadata_anikin  <= s_S3_metadata_anikin;
      s_S4_metadata_force   <= s_S3_metadata_force;
    end // if (s_S4_en) begin
    else begin
      s_S4_valid128_jedi    <= '0;
      s_S4_valid64a_jedi    <= '0;
      s_S4_valid64b_jedi    <= '0;
      s_S4_valid32a_jedi    <= '0;
      s_S4_valid32b_jedi    <= '0;
      s_S4_valid32c_jedi    <= '0;
      s_S4_valid32d_jedi    <= '0;
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata           = s_S4_metadata_anikin; // mirrored metadata copies should match
assign o_out_jedi           = (s_S4_metadata_anikin.sp_mode === SINGLE_MODE)  ? s_S4_128_jedi                                                 :
                              (s_S4_metadata_anikin.sp_mode === TWO_SP_MODE)  ? {s_S4_64a_jedi, s_S4_64b_jedi}                                :
                              (s_S4_metadata_anikin.sp_mode === FOUR_SP_MODE) ? {s_S4_32a_jedi, s_S4_32b_jedi, s_S4_32c_jedi, s_S4_32d_jedi}  :
                              128'hB1B1; // https://youtu.be/smdmEhkIRVc?si=WFrAqEqgQmf-JaDX
assign o_valid128_jedi      = s_S4_valid128_jedi;
assign o_valid64a_jedi      = s_S4_valid64a_jedi;
assign o_valid64b_jedi      = s_S4_valid64b_jedi;
assign o_valid32a_jedi      = s_S4_valid32a_jedi;
assign o_valid32b_jedi      = s_S4_valid32b_jedi;
assign o_valid32c_jedi      = s_S4_valid32c_jedi;
assign o_valid32d_jedi      = s_S4_valid32d_jedi;
assign o_sanity_identifier  = MODULE_IDENTIFIER;
assign o_error              = s_o_error;
assign o_debug              = s_o_debug;

//=====================================================================================
// Debug: optional cycle-by-cycle visibility
//=====================================================================================
always_ff @(posedge i_clk) begin : dbg_spmul
  if (i_rst_n && DEBUG_PRINT_EN === 1) begin
    $display("[%0t] %m sp_mode=%0d i_v128_a=%b i_v128_f=%b s0_v128_a=%b s0_v128_f=%b s_fire=%b s_S4_en=%b o_v128=%b",
             $time,
             i_metadata.sp_mode,
             i_valid128_anikin, i_valid128_force,
             s_S0_valid128_anikin, s_S0_valid128_force,
             s_fire, s_S4_en, o_valid128_jedi);
  end
end


endmodule // module sp_fpmultiplier #()
