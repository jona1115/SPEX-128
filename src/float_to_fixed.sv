/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 11/04/2025
 * 
 ********************************************************************
 * 
 * Contains module to convert a subword parallel (SP) float(s) into
 * the internal partition encoding consumed by Level 2.
 *
 * Positive inputs are packed as ordinary unsigned fixed-point lanes.
 * Negative inputs are packed as: x = a + r, where a is the signed
 * coarse bucket consumed by partition A and r is a nonnegative
 * residual consumed by partitions B..F.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + --------------------------
 *       1.00  |  Jonathan  |  11/04/2025  |  Birth of this file
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

module float_to_fixed #(
  parameter int NUM_BITS_128              = 128,
  parameter int NUM_BITS_64               = 64,
  parameter int NUM_BITS_32               = 32,
  
  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS     = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS     = 32,

  parameter int MODULE_LATENCY            = 3, // Must match the explicit 3-stage pipeline below

  // Identifier const
  parameter logic [3:0] MODULE_IDENTIFIER = 4'b0000
) (
  input   logic                                   i_clk,
  input   logic                                   i_rst_n, // Synchronous

  input   logic [NUM_BITS_128-1:0]                i_float,
  input   logic [3:0]                             i_ctrl,
  output  logic [127:0]                           o_fixed,
  output  float_metadata_t                        o_metadata,

  // Handshake
  input   logic                                   i_valid,
  output  logic                                   o_valid,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
binary128_t s_binary128;
binary64_t s_binary64_a;
binary64_t s_binary64_b;
binary32_t s_binary32_a;
binary32_t s_binary32_b;
binary32_t s_binary32_c;
binary32_t s_binary32_d;
logic [127:0] s_fixed_packed_q;
// Mantissa extended
logic [112:0] s_binary128_mantissa_extended;
logic [52:0]  s_binary64_a_mantissa_extended;
logic [52:0]  s_binary64_b_mantissa_extended;
logic [23:0]  s_binary32_a_mantissa_extended;
logic [23:0]  s_binary32_b_mantissa_extended;
logic [23:0]  s_binary32_c_mantissa_extended;
logic [23:0]  s_binary32_d_mantissa_extended;
// Error and debug signals
logic [ERROR_SIGNAL_NUM_BITS-1:0] s_o_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] s_o_debug;
float_metadata_t s_S0_metadata_q;
float_metadata_t s_S1_metadata_q;
float_metadata_t s_metadata_q;

// Determine what sp (subword parallel) mode we are in based on input control signals.
// Using assign will make it "continuous assignment", so it is eval-ed before always_comb 
// blocks, usually we use assign for decoders. -ChatGPT
sp_mode_t s_current_sp;
sp_mode_t s_S0_current_sp_q;
sp_mode_t s_S1_current_sp_q;

float_metadata_t s_metadata_decoded;
logic s_S0_binary128_sign_q;
logic s_S0_binary64_a_sign_q;
logic s_S0_binary64_b_sign_q;
logic s_S0_binary32_a_sign_q;
logic s_S0_binary32_b_sign_q;
logic s_S0_binary32_c_sign_q;
logic s_S0_binary32_d_sign_q;
logic [NUM_BITS_128-1:0] s_S0_fixed128_temp_q;
logic [NUM_BITS_64-1:0]  s_S0_fixed64_a_temp_q;
logic [NUM_BITS_64-1:0]  s_S0_fixed64_b_temp_q;
logic [NUM_BITS_32-1:0]  s_S0_fixed32_a_temp_q;
logic [NUM_BITS_32-1:0]  s_S0_fixed32_b_temp_q;
logic [NUM_BITS_32-1:0]  s_S0_fixed32_c_temp_q;
logic [NUM_BITS_32-1:0]  s_S0_fixed32_d_temp_q;
sh_t s_S0_shift_amount_a_q;
sh_t s_S0_shift_amount_b_q;
sh_t s_S0_shift_amount_c_q;
sh_t s_S0_shift_amount_d_q;
logic s_S1_binary128_sign_q;
logic s_S1_binary64_a_sign_q;
logic s_S1_binary64_b_sign_q;
logic s_S1_binary32_a_sign_q;
logic s_S1_binary32_b_sign_q;
logic s_S1_binary32_c_sign_q;
logic s_S1_binary32_d_sign_q;
logic [NUM_BITS_128-1:0] s_S1_fixed128_shifted_q;
logic [NUM_BITS_64-1:0]  s_S1_fixed64_a_shifted_q;
logic [NUM_BITS_64-1:0]  s_S1_fixed64_b_shifted_q;
logic [NUM_BITS_32-1:0]  s_S1_fixed32_a_shifted_q;
logic [NUM_BITS_32-1:0]  s_S1_fixed32_b_shifted_q;
logic [NUM_BITS_32-1:0]  s_S1_fixed32_c_shifted_q;
logic [NUM_BITS_32-1:0]  s_S1_fixed32_d_shifted_q;
logic s_S1_exact128_mag_q;
logic s_S1_exact64_a_mag_q;
logic s_S1_exact64_b_mag_q;
logic s_S1_exact32_a_mag_q;
logic s_S1_exact32_b_mag_q;
logic s_S1_exact32_c_mag_q;
logic s_S1_exact32_d_mag_q;
localparam logic [NUM_BITS_128-1:0] EXACT128_MAG = {{10{1'b0}}, 1'b1, {117{1'b0}}};
localparam logic [NUM_BITS_64-1:0]  EXACT64_MAG  = {{10{1'b0}}, 1'b1, {53{1'b0}}};
localparam logic [NUM_BITS_32-1:0]  EXACT32_MAG  = {{10{1'b0}}, 1'b1, {21{1'b0}}};
assign s_current_sp =
  (i_ctrl[1:0] == 2'b00) ? SINGLE_MODE  :
  (i_ctrl[1:0] == 2'b01) ? TWO_SP_MODE  :
  (i_ctrl[1:0] == 2'b10) ? FOUR_SP_MODE : INVALID_SP_MODE;
// // Check that INVALID_SP_MODE should never be passed into this module; commented because cant do this ouside a always block or need to use property, but todo we still want to perform this check
// assert(s_current_sp != INVALID_SP_MODE && i_valid == 1'b1) else begin
//   s_o_error[2] <= 1'b1;
//  $fatal(1, "INVALID_SP_MODE detected"); // This is for simulator not synthesis
// end

// Generate a bunch of helper signals as decoders
// single mode
assign s_binary128.sign       = i_float[127];
assign s_binary128.exp        = i_float[126:112];
assign s_binary128.mantissa   = i_float[111:0];
// two sp mode
assign s_binary64_a.sign      = i_float[127];
assign s_binary64_a.exp       = i_float[126:116];
assign s_binary64_a.mantissa  = i_float[115:64];
assign s_binary64_b.sign      = i_float[63];
assign s_binary64_b.exp       = i_float[62:52];
assign s_binary64_b.mantissa  = i_float[51:0];
// four sp mode
assign s_binary32_a.sign      = i_float[127];
assign s_binary32_a.exp       = i_float[126:119];
assign s_binary32_a.mantissa  = i_float[118:96];
assign s_binary32_b.sign      = i_float[95];
assign s_binary32_b.exp       = i_float[94:87];
assign s_binary32_b.mantissa  = i_float[86:64];
assign s_binary32_c.sign      = i_float[63];
assign s_binary32_c.exp       = i_float[62:55];
assign s_binary32_c.mantissa  = i_float[54:32];
assign s_binary32_d.sign      = i_float[31];
assign s_binary32_d.exp       = i_float[30:23];
assign s_binary32_d.mantissa  = i_float[22:0];
// extended mantissa
assign s_binary128_mantissa_extended = {1'b1, s_binary128.mantissa};
assign s_binary64_a_mantissa_extended = {1'b1, s_binary64_a.mantissa};
assign s_binary64_b_mantissa_extended = {1'b1, s_binary64_b.mantissa};
assign s_binary32_a_mantissa_extended = {1'b1, s_binary32_a.mantissa};
assign s_binary32_b_mantissa_extended = {1'b1, s_binary32_b.mantissa};
assign s_binary32_c_mantissa_extended = {1'b1, s_binary32_c.mantissa};
assign s_binary32_d_mantissa_extended = {1'b1, s_binary32_d.mantissa};

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

/**
 * Decoder to determine what the output float types are based on s_current_sp
 */
float_classifier #() my_float_classifier_0 (
  .i_current_sp(s_current_sp),
  .i_float(i_float),
  .o_metadata(s_metadata_decoded)
);

function automatic logic [NUM_BITS_128-1:0] apply_shift_128(
  input logic [NUM_BITS_128-1:0] i_fixed_temp,
  input sh_t                     i_shift_amount
);
  logic [NUM_BITS_128-1:0] fixed_shifted;

  if ((i_shift_amount >= 0) && (i_shift_amount <= 9)) begin
    fixed_shifted = i_fixed_temp << i_shift_amount;
  end
  else if (i_shift_amount < 0) begin
    fixed_shifted = i_fixed_temp >> -i_shift_amount;
  end
  else begin
    fixed_shifted = '1;
  end
  return fixed_shifted;
endfunction

function automatic logic [NUM_BITS_64-1:0] apply_shift_64(
  input logic [NUM_BITS_64-1:0] i_fixed_temp,
  input sh_t                    i_shift_amount
);
  logic [NUM_BITS_64-1:0] fixed_shifted;

  if ((i_shift_amount >= 0) && (i_shift_amount <= 9)) begin
    fixed_shifted = i_fixed_temp << i_shift_amount;
  end
  else if (i_shift_amount < 0) begin
    fixed_shifted = i_fixed_temp >> -i_shift_amount;
  end
  else begin
    fixed_shifted = '1;
  end
  return fixed_shifted;
endfunction

function automatic logic [NUM_BITS_32-1:0] apply_shift_32(
  input logic [NUM_BITS_32-1:0] i_fixed_temp,
  input sh_t                    i_shift_amount
);
  logic [NUM_BITS_32-1:0] fixed_shifted;

  if ((i_shift_amount >= 0) && (i_shift_amount <= 9)) begin
    fixed_shifted = i_fixed_temp << i_shift_amount;
  end
  else if (i_shift_amount < 0) begin
    fixed_shifted = i_fixed_temp >> -i_shift_amount;
  end
  else begin
    fixed_shifted = '1;
  end
  return fixed_shifted;
endfunction

function automatic logic [NUM_BITS_128-1:0] pack_lane_128(
  input logic                    i_is_negative,
  input logic [NUM_BITS_128-1:0] i_fixed_shifted,
  input logic                    i_is_exact_upper_bound
);
  logic [NUM_BITS_128-1:0] packed128;

  if (!i_is_negative) begin
    packed128 = {1'b0, i_fixed_shifted[126:117], i_fixed_shifted[116:0]};
  end
  else if (i_fixed_shifted == '0) begin
    packed128 = '0;
  end
  else if (i_is_exact_upper_bound) begin
    packed128 = {1'b1, {10{1'b1}}, {117{1'b0}}};
  end
  else if (i_fixed_shifted == '1) begin
    packed128 = {1'b1, i_fixed_shifted[126:117], i_fixed_shifted[116:0]};
  end
  else if (i_fixed_shifted[116:0] == '0) begin
    packed128 = {1'b1, i_fixed_shifted[126:117] - 10'd1, {117{1'b0}}};
  end
  else begin
    packed128 = {1'b1, i_fixed_shifted[126:117], (~i_fixed_shifted[116:0]) + 1'b1};
  end
  return packed128;
endfunction

function automatic logic [NUM_BITS_64-1:0] pack_lane_64(
  input logic                   i_is_negative,
  input logic [NUM_BITS_64-1:0] i_fixed_shifted,
  input logic                   i_is_exact_upper_bound
);
  logic [NUM_BITS_64-1:0] packed64;

  if (!i_is_negative) begin
    packed64 = {1'b0, i_fixed_shifted[62:52], i_fixed_shifted[51:0]};
  end
  else if (i_fixed_shifted == '0) begin
    packed64 = '0;
  end
  else if (i_is_exact_upper_bound) begin
    packed64 = {1'b1, {10{1'b1}}, {53{1'b0}}};
  end
  else if (i_fixed_shifted == '1) begin
    packed64 = {1'b1, i_fixed_shifted[62:52], i_fixed_shifted[51:0]};
  end
  else if (i_fixed_shifted[52:0] == '0) begin
    packed64 = {1'b1, i_fixed_shifted[62:53] - 10'd1, {53{1'b0}}};
  end
  else begin
    packed64 = {1'b1, i_fixed_shifted[62:53], (~i_fixed_shifted[52:0]) + 1'b1};
  end
  return packed64;
endfunction

function automatic logic [NUM_BITS_32-1:0] pack_lane_32(
  input logic                   i_is_negative,
  input logic [NUM_BITS_32-1:0] i_fixed_shifted,
  input logic                   i_is_exact_upper_bound
);
  logic [NUM_BITS_32-1:0] packed32;

  if (!i_is_negative) begin
    packed32 = {1'b0, i_fixed_shifted[30:21], i_fixed_shifted[20:0]};
  end
  else if (i_fixed_shifted == '0) begin
    packed32 = '0;
  end
  else if (i_is_exact_upper_bound) begin
    packed32 = {1'b1, {10{1'b1}}, {21{1'b0}}};
  end
  else if (i_fixed_shifted == '1) begin
    packed32 = {1'b1, i_fixed_shifted[30:21], i_fixed_shifted[20:0]};
  end
  else if (i_fixed_shifted[20:0] == '0) begin
    packed32 = {1'b1, i_fixed_shifted[30:21] - 10'd1, {21{1'b0}}};
  end
  else begin
    packed32 = {1'b1, i_fixed_shifted[30:21], (~i_fixed_shifted[20:0]) + 1'b1};
  end
  return packed32;
endfunction

/**
 * 
 * State transition control
 * 
 */
localparam int PIPE_DEPTH = MODULE_LATENCY;
logic [PIPE_DEPTH-1 : 0] s_pipe_valid;
logic [PIPE_DEPTH-1 : 0] s_pipe_valid_next;

logic s_fire;
logic s_S0_en;
logic s_S1_en;
logic s_S2_en;
assign s_fire = i_valid; // "decodes" the valid bit

generate
  if (PIPE_DEPTH == 1) begin : gen_pipe_valid_depth_1
    assign s_pipe_valid_next = s_fire;
  end
  else begin : gen_pipe_valid_depth_n
    assign s_pipe_valid_next = {s_pipe_valid[PIPE_DEPTH-2 : 0], s_fire};
  end
endgenerate

assign s_S0_en = s_fire;
generate
  if (PIPE_DEPTH > 1) begin : gen_stage1_enable
    assign s_S1_en = s_pipe_valid[0];
  end
  else begin : gen_stage1_disable
    assign s_S1_en = 1'b0;
  end

  if (PIPE_DEPTH > 2) begin : gen_stage2_enable
    assign s_S2_en = s_pipe_valid[1];
  end
  else begin : gen_stage2_disable
    assign s_S2_en = 1'b0;
  end
endgenerate

initial begin
  assert (MODULE_LATENCY == 3)
    else $error("float_to_fixed MODULE_LATENCY must be 3 for the explicit 3-stage pipeline.");
end

/**
 * FSM
 */
always_ff @( posedge i_clk ) begin : float_to_fixed_FSM
  if (!i_rst_n) begin
    s_pipe_valid <= '0;
  end
  else begin
    s_pipe_valid <= s_pipe_valid_next;
  end
end

//=====================================================================================
// Stage 0 (mantissa map + shift amount decode)
//=====================================================================================
always_ff @( posedge i_clk ) begin : stage0_prepare
  logic [NUM_BITS_128-1:0] fixed128_temp;
  logic [NUM_BITS_64-1:0] fixed64_a_temp;
  logic [NUM_BITS_64-1:0] fixed64_b_temp;
  logic [NUM_BITS_32-1:0] fixed32_a_temp;
  logic [NUM_BITS_32-1:0] fixed32_b_temp;
  logic [NUM_BITS_32-1:0] fixed32_c_temp;
  logic [NUM_BITS_32-1:0] fixed32_d_temp;
  sh_t shift_amount_a, shift_amount_b, shift_amount_c, shift_amount_d;

  if (!i_rst_n) begin
    s_S0_current_sp_q <= INVALID_SP_MODE;
    s_S0_metadata_q <= '0;
    s_S0_binary128_sign_q <= '0;
    s_S0_binary64_a_sign_q <= '0;
    s_S0_binary64_b_sign_q <= '0;
    s_S0_binary32_a_sign_q <= '0;
    s_S0_binary32_b_sign_q <= '0;
    s_S0_binary32_c_sign_q <= '0;
    s_S0_binary32_d_sign_q <= '0;
    s_S0_fixed128_temp_q <= '0;
    s_S0_fixed64_a_temp_q <= '0;
    s_S0_fixed64_b_temp_q <= '0;
    s_S0_fixed32_a_temp_q <= '0;
    s_S0_fixed32_b_temp_q <= '0;
    s_S0_fixed32_c_temp_q <= '0;
    s_S0_fixed32_d_temp_q <= '0;
    s_S0_shift_amount_a_q <= '0;
    s_S0_shift_amount_b_q <= '0;
    s_S0_shift_amount_c_q <= '0;
    s_S0_shift_amount_d_q <= '0;
    s_o_error <= '0;
  end
  else if (s_S0_en) begin
    shift_amount_a = '0;
    shift_amount_b = '0;
    shift_amount_c = '0;
    shift_amount_d = '0;

    fixed128_temp = '0;
    fixed64_a_temp = '0;
    fixed64_b_temp = '0;
    fixed32_a_temp = '0;
    fixed32_b_temp = '0;
    fixed32_c_temp = '0;
    fixed32_d_temp = '0;

    // Stage-0 only maps the significands into the fixed-point lanes and
    // precomputes unbiased exponents. Stage-1 gets only the wide shifts.
    // Stage-2 handles the signed pack step.
    fixed128_temp[117:5] = s_binary128_mantissa_extended;
    fixed64_a_temp[53:1] = s_binary64_a_mantissa_extended;
    fixed64_b_temp[53:1] = s_binary64_b_mantissa_extended;
    fixed32_a_temp[21:0] = s_binary32_a_mantissa_extended[23:2];
    fixed32_b_temp[21:0] = s_binary32_b_mantissa_extended[23:2];
    fixed32_c_temp[21:0] = s_binary32_c_mantissa_extended[23:2];
    fixed32_d_temp[21:0] = s_binary32_d_mantissa_extended[23:2];

    case (s_current_sp)
      SINGLE_MODE: begin
        shift_amount_a = unbias_q128(s_binary128.exp);
      end
      TWO_SP_MODE: begin
        shift_amount_a = unbias_q64(s_binary64_a.exp);
        shift_amount_b = unbias_q64(s_binary64_b.exp);
      end
      FOUR_SP_MODE: begin
        shift_amount_a = unbias_q32(s_binary32_a.exp);
        shift_amount_b = unbias_q32(s_binary32_b.exp);
        shift_amount_c = unbias_q32(s_binary32_c.exp);
        shift_amount_d = unbias_q32(s_binary32_d.exp);
      end
      default: begin
        assert (0) else begin
          s_o_error[1] <= 1'b1;
        end
      end
    endcase

    s_S0_current_sp_q <= s_current_sp;
    s_S0_metadata_q <= s_metadata_decoded;
    s_S0_binary128_sign_q <= s_binary128.sign;
    s_S0_binary64_a_sign_q <= s_binary64_a.sign;
    s_S0_binary64_b_sign_q <= s_binary64_b.sign;
    s_S0_binary32_a_sign_q <= s_binary32_a.sign;
    s_S0_binary32_b_sign_q <= s_binary32_b.sign;
    s_S0_binary32_c_sign_q <= s_binary32_c.sign;
    s_S0_binary32_d_sign_q <= s_binary32_d.sign;
    s_S0_fixed128_temp_q <= fixed128_temp;
    s_S0_fixed64_a_temp_q <= fixed64_a_temp;
    s_S0_fixed64_b_temp_q <= fixed64_b_temp;
    s_S0_fixed32_a_temp_q <= fixed32_a_temp;
    s_S0_fixed32_b_temp_q <= fixed32_b_temp;
    s_S0_fixed32_c_temp_q <= fixed32_c_temp;
    s_S0_fixed32_d_temp_q <= fixed32_d_temp;
    s_S0_shift_amount_a_q <= shift_amount_a;
    s_S0_shift_amount_b_q <= shift_amount_b;
    s_S0_shift_amount_c_q <= shift_amount_c;
    s_S0_shift_amount_d_q <= shift_amount_d;
  end
end

//=====================================================================================
// Stage 1 (wide shift)
//=====================================================================================
always_ff @( posedge i_clk ) begin : stage1_shift
  if (!i_rst_n) begin
    s_S1_current_sp_q <= INVALID_SP_MODE;
    s_S1_metadata_q <= '0;
    s_S1_binary128_sign_q <= '0;
    s_S1_binary64_a_sign_q <= '0;
    s_S1_binary64_b_sign_q <= '0;
    s_S1_binary32_a_sign_q <= '0;
    s_S1_binary32_b_sign_q <= '0;
    s_S1_binary32_c_sign_q <= '0;
    s_S1_binary32_d_sign_q <= '0;
    s_S1_fixed128_shifted_q <= '0;
    s_S1_fixed64_a_shifted_q <= '0;
    s_S1_fixed64_b_shifted_q <= '0;
    s_S1_fixed32_a_shifted_q <= '0;
    s_S1_fixed32_b_shifted_q <= '0;
    s_S1_fixed32_c_shifted_q <= '0;
    s_S1_fixed32_d_shifted_q <= '0;
    s_S1_exact128_mag_q <= 1'b0;
    s_S1_exact64_a_mag_q <= 1'b0;
    s_S1_exact64_b_mag_q <= 1'b0;
    s_S1_exact32_a_mag_q <= 1'b0;
    s_S1_exact32_b_mag_q <= 1'b0;
    s_S1_exact32_c_mag_q <= 1'b0;
    s_S1_exact32_d_mag_q <= 1'b0;
  end
  else if (s_S1_en) begin
    s_S1_current_sp_q <= s_S0_current_sp_q;
    s_S1_metadata_q <= s_S0_metadata_q;
    s_S1_binary128_sign_q <= s_S0_binary128_sign_q;
    s_S1_binary64_a_sign_q <= s_S0_binary64_a_sign_q;
    s_S1_binary64_b_sign_q <= s_S0_binary64_b_sign_q;
    s_S1_binary32_a_sign_q <= s_S0_binary32_a_sign_q;
    s_S1_binary32_b_sign_q <= s_S0_binary32_b_sign_q;
    s_S1_binary32_c_sign_q <= s_S0_binary32_c_sign_q;
    s_S1_binary32_d_sign_q <= s_S0_binary32_d_sign_q;
    s_S1_fixed128_shifted_q <= '0;
    s_S1_fixed64_a_shifted_q <= '0;
    s_S1_fixed64_b_shifted_q <= '0;
    s_S1_fixed32_a_shifted_q <= '0;
    s_S1_fixed32_b_shifted_q <= '0;
    s_S1_fixed32_c_shifted_q <= '0;
    s_S1_fixed32_d_shifted_q <= '0;
    s_S1_exact128_mag_q <= 1'b0;
    s_S1_exact64_a_mag_q <= 1'b0;
    s_S1_exact64_b_mag_q <= 1'b0;
    s_S1_exact32_a_mag_q <= 1'b0;
    s_S1_exact32_b_mag_q <= 1'b0;
    s_S1_exact32_c_mag_q <= 1'b0;
    s_S1_exact32_d_mag_q <= 1'b0;

    case (s_S0_current_sp_q)
      SINGLE_MODE: begin
        s_S1_fixed128_shifted_q <= apply_shift_128(s_S0_fixed128_temp_q, s_S0_shift_amount_a_q);
        s_S1_exact128_mag_q <= (s_S0_shift_amount_a_q == 10) && (s_S0_fixed128_temp_q == EXACT128_MAG);
      end

      TWO_SP_MODE: begin
        s_S1_fixed64_a_shifted_q <= apply_shift_64(s_S0_fixed64_a_temp_q, s_S0_shift_amount_a_q);
        s_S1_fixed64_b_shifted_q <= apply_shift_64(s_S0_fixed64_b_temp_q, s_S0_shift_amount_b_q);
        s_S1_exact64_a_mag_q <= (s_S0_shift_amount_a_q == 10) && (s_S0_fixed64_a_temp_q == EXACT64_MAG);
        s_S1_exact64_b_mag_q <= (s_S0_shift_amount_b_q == 10) && (s_S0_fixed64_b_temp_q == EXACT64_MAG);
      end

      FOUR_SP_MODE: begin
        s_S1_fixed32_a_shifted_q <= apply_shift_32(s_S0_fixed32_a_temp_q, s_S0_shift_amount_a_q);
        s_S1_fixed32_b_shifted_q <= apply_shift_32(s_S0_fixed32_b_temp_q, s_S0_shift_amount_b_q);
        s_S1_fixed32_c_shifted_q <= apply_shift_32(s_S0_fixed32_c_temp_q, s_S0_shift_amount_c_q);
        s_S1_fixed32_d_shifted_q <= apply_shift_32(s_S0_fixed32_d_temp_q, s_S0_shift_amount_d_q);
        s_S1_exact32_a_mag_q <= (s_S0_shift_amount_a_q == 10) && (s_S0_fixed32_a_temp_q == EXACT32_MAG);
        s_S1_exact32_b_mag_q <= (s_S0_shift_amount_b_q == 10) && (s_S0_fixed32_b_temp_q == EXACT32_MAG);
        s_S1_exact32_c_mag_q <= (s_S0_shift_amount_c_q == 10) && (s_S0_fixed32_c_temp_q == EXACT32_MAG);
        s_S1_exact32_d_mag_q <= (s_S0_shift_amount_d_q == 10) && (s_S0_fixed32_d_temp_q == EXACT32_MAG);
      end

      default: begin
      end
    endcase
  end
end

//=====================================================================================
// Stage 2 (signed pack)
//=====================================================================================
always_ff @( posedge i_clk ) begin : stage2_pack
  if (!i_rst_n) begin
    s_fixed_packed_q <= '0;
    s_metadata_q <= '0;
  end
  else if (s_S2_en) begin
    s_metadata_q <= s_S1_metadata_q;

    case (s_S1_current_sp_q)
      SINGLE_MODE: begin
        s_fixed_packed_q <= pack_lane_128(
          s_S1_binary128_sign_q,
          s_S1_fixed128_shifted_q,
          s_S1_exact128_mag_q
        );
      end

      TWO_SP_MODE: begin
        s_fixed_packed_q <= {
          pack_lane_64(s_S1_binary64_a_sign_q, s_S1_fixed64_a_shifted_q, s_S1_exact64_a_mag_q),
          pack_lane_64(s_S1_binary64_b_sign_q, s_S1_fixed64_b_shifted_q, s_S1_exact64_b_mag_q)
        };
      end

      FOUR_SP_MODE: begin
        s_fixed_packed_q <= {
          pack_lane_32(s_S1_binary32_a_sign_q, s_S1_fixed32_a_shifted_q, s_S1_exact32_a_mag_q),
          pack_lane_32(s_S1_binary32_b_sign_q, s_S1_fixed32_b_shifted_q, s_S1_exact32_b_mag_q),
          pack_lane_32(s_S1_binary32_c_sign_q, s_S1_fixed32_c_shifted_q, s_S1_exact32_c_mag_q),
          pack_lane_32(s_S1_binary32_d_sign_q, s_S1_fixed32_d_shifted_q, s_S1_exact32_d_mag_q)
        };
      end

      default: begin
        s_fixed_packed_q <= '0;
      end
    endcase
  end
end

//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata = s_metadata_q;

assign o_fixed = s_fixed_packed_q;

// This is the identifier (ie version number) of this block
assign o_sanity_identifier      = MODULE_IDENTIFIER;

assign o_error = s_o_error;
assign o_debug = s_o_debug;

assign o_valid = s_pipe_valid[PIPE_DEPTH-1];

endmodule // module float_to_fixed #()
