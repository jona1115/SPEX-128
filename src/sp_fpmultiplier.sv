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
 ********************************************************************
 * 
 * Modification history:
 *    Ver   |  Who       |  Date	    |  Changes
 *  ------- + ---------- + ------------ + --------------------------
 *    1.00  |  Jonathan  |  11/27/2025   |  Birth of this file
 *    1.01  |  Jonathan  |  1/27/2026    |  Renamed file from sp_multiplier.sv to sp_fpmultiplier.sv
 * 
 *******************************************************************/

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

  // Error and debug parameters
  parameter int ERROR_SIGNAL_NUM_BITS = 32,
  parameter int DEBUG_SIGNAL_NUM_BITS = 32,

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
logic                               s_sp_intmultiplier_valid;


//=====================================================================================
// Module body
//=====================================================================================
/**
 * This section we decode the inputs i_in_anikin and i_in_force into its type, pretty
 * sure this does nothing in hardware but is for readability
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

  // This is an interesting way of implementing.... kinda... stupid and redundant now that I look back 2 days later
  // Welp too late, we are sticking to it now
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

    // default: begin
    //   assert (0);
    // end
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
 * FSM
 */
typedef enum logic [2:0] { 
  S0_IDLE     = 3'b000,
  S1          = 3'b001,
  S2          = 3'b010,
  S3          = 3'b011,
  S4          = 3'b100,
  S5          = 3'b101,
  S6          = 3'b110,
  S7          = 3'b111
} state_t;
state_t s_curr_state, s_next_state;
always_ff @( posedge i_clk ) begin : float_to_fixed_FSM
  if (!i_rst_n) begin
    s_curr_state <= S0_IDLE;
  end
  else begin
    s_curr_state <= s_next_state;
  end
end

/**
 * 
 * State transition control
 * 
 */
logic s_S0_en, s_S1_en, s_S2_en, s_S3_en, s_S4_en, s_S5_en, s_S6_en, s_S7_en;
always_comb begin : stage_en_control
  // Defaults
  s_next_state = s_curr_state;
  s_S0_en = '0;
  s_S1_en = '0;
  s_S2_en = '0;
  s_S3_en = '0;
  s_S4_en = '0;
  s_S5_en = '0;
  s_S6_en = '0;
  s_S7_en = '0;

  unique case (s_curr_state)
    S0_IDLE: begin
      s_next_state = S1;
    end
    S1: begin
      if ( // "All or nothing" enforcer - All anikin and force subwords of either sp_mode have to be valid for stage 0 to proceed:
        (i_metadata.sp_mode === SINGLE_MODE && s_S0_valid128_anikin === 1'b1 && s_S0_valid128_force === 1'b1) ||
        (i_metadata.sp_mode === TWO_SP_MODE && s_S0_valid64a_anikin === 1'b1 && s_S0_valid64a_force === 1'b1 && s_S0_valid64b_anikin === 1'b1 && s_S0_valid64b_force === 1'b1) ||
        (i_metadata.sp_mode === FOUR_SP_MODE && s_S0_valid32a_anikin === 1'b1 && s_S0_valid32a_force === 1'b1 && s_S0_valid32b_anikin === 1'b1 && s_S0_valid32b_force === 1'b1 && s_S0_valid32c_anikin === 1'b1 && s_S0_valid32c_force === 1'b1 && s_S0_valid32d_anikin === 1'b1 && s_S0_valid32d_force === 1'b1)
      ) begin
        s_S1_en = 1'b1;
        s_next_state = S2;
      end
    end
    S2: begin
      s_S2_en = 1'b1;
      if (s_sp_intmultiplier_valid) begin
        s_next_state = S3;
      end
      else begin // redundant statement but just to be explicit
        s_next_state = S2;
      end
    end
    S3: begin
      s_S3_en = 1'b1;
      s_next_state = S4;
    end
    S4: begin
      s_S4_en = 1'b1;
      s_next_state = S5;
    end
    S5: begin
      s_S5_en = 1'b1;
      s_next_state = S0_IDLE; // s5 is the last stage
    end
    S6: begin
      s_S6_en = 1'b1;
      s_next_state = S7;
    end
    S7: begin
      s_S7_en = 1'b1;
      s_next_state = S0_IDLE;
    end
    default: begin
      s_next_state = S0_IDLE;
    end
  endcase
end

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
 * Stage 1 block: Deal with sign bit and exponent in one block to avoid multi-driven nets
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

      // Pass the metadata through
      s_S1_metadata_anikin  <= s_S0_metadata_anikin;  // Notes to myself: We shall pass this through and use it at the end
      s_S1_metadata_force   <= s_S0_metadata_force;   // Notes to myself: We shall pass this through and use it at the end
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 2: Multiply
//=====================================================================================
/**
 * 2a: Process the multiply
 */
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
logic [225:0] s_S2_128_mult_out_full;
logic [105:0] s_S2_64a_mult_out_full, s_S2_64b_mult_out_full;
logic [47:0]  s_S2_32a_mult_out_full, s_S2_32b_mult_out_full, s_S2_32c_mult_out_full, s_S2_32d_mult_out_full;

logic [225:0] s_sp_intmultiplier_jedi;
logic [3:0]   unused_sp_intmultiplier_sanity_identifier;
logic [ERROR_SIGNAL_NUM_BITS-1:0] unused_sp_intmultiplier_error;
logic [DEBUG_SIGNAL_NUM_BITS-1:0] unused_sp_intmultiplier_debug;
sp_intmultiplier #() my_sp_intmultiplier (
  .i_clk(i_clk),
  .i_rst_n(i_rst_n),
  .i_metadata(s_S1_metadata_anikin),
  .i_anikin(s_S1_metadata_anikin.sp_mode === SINGLE_MODE ? hs_S1_128_anikin_mantissa_extended                                           :
            s_S1_metadata_anikin.sp_mode === TWO_SP_MODE ? {'0, hs_S1_64a_anikin_mantissa_extended, hs_S1_64b_anikin_mantissa_extended} :
                                                           {'0, hs_S1_32a_anikin_mantissa_extended, hs_S1_32b_anikin_mantissa_extended, 
                                                            hs_S1_32c_anikin_mantissa_extended, hs_S1_32d_anikin_mantissa_extended}
            ),
  .i_force(s_S1_metadata_anikin.sp_mode === SINGLE_MODE ? hs_S1_128_force_mantissa_extended                                             :
           s_S1_metadata_anikin.sp_mode === TWO_SP_MODE ? {'0, hs_S1_64a_force_mantissa_extended, hs_S1_64b_force_mantissa_extended}    :
                                                          {'0, hs_S1_32a_force_mantissa_extended, hs_S1_32b_force_mantissa_extended, 
                                                          hs_S1_32c_force_mantissa_extended, hs_S1_32d_force_mantissa_extended}
            ),
  .o_jedi(s_sp_intmultiplier_jedi),
  .i_valid_anikin(s_S2_en & s_S1_valid128_jedi),
  .i_valid_force(s_S2_en & s_S1_valid128_jedi),
  .o_valid_jedi(s_sp_intmultiplier_valid),
  .o_sanity_identifier(unused_sp_intmultiplier_sanity_identifier),
  .o_error(unused_sp_intmultiplier_error),
  .o_debug(unused_sp_intmultiplier_debug)
);
always_ff @( posedge i_clk ) begin : stage2a_extended_mantissa_mult
  if (!i_rst_n) begin
    s_S2_128_mult_out_full  <= '0;
    s_S2_64a_mult_out_full  <= '0;
    s_S2_64b_mult_out_full  <= '0;
    s_S2_32a_mult_out_full  <= '0;
    s_S2_32b_mult_out_full  <= '0;
    s_S2_32c_mult_out_full  <= '0;
    s_S2_32d_mult_out_full  <= '0;
    s_o_error[3]            <= 1'b0;
    s_o_error[7]            <= 1'b0;
  end
  else begin
    if (s_S2_en) begin
      assert (s_S1_metadata_anikin.sp_mode === s_S1_metadata_force.sp_mode) else begin
        s_o_error[7] <= 1'b1;
        // $fatal(1, "Bad things had happened, (s_S1_metadata_anikin.sp_mode === s_S1_metadata_force.sp_mode) is false.");
      end

      // todo we need to split s_sp_intmultiplier_jedi into:
      // s_S2_128_mult_out_full
      // s_S2_64a_mult_out_full
      // s_S2_64b_mult_out_full
      // s_S2_32a_mult_out_full
      // s_S2_32b_mult_out_full
      // s_S2_32c_mult_out_full
      // s_S2_32d_mult_out_full
      
      // case (s_S1_metadata_anikin.sp_mode)
      //   SINGLE_MODE: begin
      //     s_S2_128_mult_out_full <= hs_S1_128_anikin_mantissa_extended * hs_S1_128_force_mantissa_extended; // I can hear Jones screaming
      //   end
      //   TWO_SP_MODE: begin
      //     s_S2_64a_mult_out_full <= hs_S1_64a_anikin_mantissa_extended * hs_S1_64a_force_mantissa_extended;
      //     s_S2_64b_mult_out_full <= hs_S1_64b_anikin_mantissa_extended * hs_S1_64b_force_mantissa_extended;
      //   end
      //   FOUR_SP_MODE: begin
      //     s_S2_32a_mult_out_full <= hs_S1_32a_anikin_mantissa_extended * hs_S1_32a_force_mantissa_extended;
      //     s_S2_32b_mult_out_full <= hs_S1_32b_anikin_mantissa_extended * hs_S1_32b_force_mantissa_extended;
      //     s_S2_32c_mult_out_full <= hs_S1_32c_anikin_mantissa_extended * hs_S1_32c_force_mantissa_extended;
      //     s_S2_32d_mult_out_full <= hs_S1_32d_anikin_mantissa_extended * hs_S1_32d_force_mantissa_extended;
      //   end
      //   default: begin
      //     assert (0) else begin
      //       s_o_error[3] <= 1'b1;
      //     end
      //   end
      // endcase // case (i_metadata.sp_mode)
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

/**
 * 2b: Signal passthrough, for proper pipelining
 */
// Outputs
binary128_t       s_S2_128_jedi;
binary64_t        s_S2_64a_jedi, s_S2_64b_jedi;
binary32_t        s_S2_32a_jedi, s_S2_32b_jedi, s_S2_32c_jedi, s_S2_32d_jedi;
logic             s_S2_valid128_jedi;
logic             s_S2_valid64a_jedi, s_S2_valid64b_jedi;
logic             s_S2_valid32a_jedi, s_S2_valid32b_jedi, s_S2_valid32c_jedi, s_S2_valid32d_jedi;
float_metadata_t  s_S2_metadata_anikin, s_S2_metadata_force;
always_ff @( posedge i_clk ) begin : stage2b_signal_passthrough
  if (!i_rst_n) begin
    s_S2_128_jedi         <= '0;
    s_S2_64a_jedi         <= '0;
    s_S2_64b_jedi         <= '0;
    s_S2_32a_jedi         <= '0;
    s_S2_32b_jedi         <= '0;
    s_S2_32c_jedi         <= '0;
    s_S2_32d_jedi         <= '0;

    s_S2_valid128_jedi    <= '0;
    s_S2_valid64a_jedi    <= '0;
    s_S2_valid64b_jedi    <= '0;
    s_S2_valid32a_jedi    <= '0;
    s_S2_valid32b_jedi    <= '0;
    s_S2_valid32c_jedi    <= '0;
    s_S2_valid32d_jedi    <= '0;
    
    s_S2_metadata_anikin  <= '0;
    s_S2_metadata_force   <= '0;
  end
  else begin
    if (s_S2_en) begin
      // jedi passthrough
      s_S2_128_jedi         <= s_S1_128_jedi;
      s_S2_64a_jedi         <= s_S1_64a_jedi;
      s_S2_64b_jedi         <= s_S1_64b_jedi;
      s_S2_32a_jedi         <= s_S1_32a_jedi;
      s_S2_32b_jedi         <= s_S1_32b_jedi;
      s_S2_32c_jedi         <= s_S1_32c_jedi;
      s_S2_32d_jedi         <= s_S1_32d_jedi;

      // valid bit pass through
      s_S2_valid128_jedi    <= s_S1_valid128_jedi;
      s_S2_valid64a_jedi    <= s_S1_valid64a_jedi;
      s_S2_valid64b_jedi    <= s_S1_valid64b_jedi;
      s_S2_valid32a_jedi    <= s_S1_valid32a_jedi;
      s_S2_valid32b_jedi    <= s_S1_valid32b_jedi;
      s_S2_valid32c_jedi    <= s_S1_valid32c_jedi;
      s_S2_valid32d_jedi    <= s_S1_valid32d_jedi;

      // metadata
      s_S2_metadata_anikin  <= s_S1_metadata_anikin;  // Notes to myself: We shall pass this through and use it at the end
      s_S2_metadata_force   <= s_S1_metadata_force;   // Notes to myself: We shall pass this through and use it at the end
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 3: Rounding and normalization
//=====================================================================================
/**
 * 3a: 
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
 * Stage 4 will be:
 * After rounding, we need to check that the rounding didn't cause overflow (ie we 
 * get a 10.0000.... after we increment by 1)
 * if that is the case (overflow), we increment the exponent by 1 again and shift
 * P_norm right by 1 so that it goes back to being 1.000000....
 * 
 * This is called RN-even: Round to nearest, ties to even
 */
/**
 * 3a: Normalization
 */
// Guard bits:
logic s_S3_128_mult_out_full_G, s_S3_128_mult_out_full_R, s_S3_128_mult_out_full_S;
logic s_S3_64a_mult_out_full_G, s_S3_64a_mult_out_full_R, s_S3_64a_mult_out_full_S;
logic s_S3_64b_mult_out_full_G, s_S3_64b_mult_out_full_R, s_S3_64b_mult_out_full_S;
logic s_S3_32a_mult_out_full_G, s_S3_32a_mult_out_full_R, s_S3_32a_mult_out_full_S;
logic s_S3_32b_mult_out_full_G, s_S3_32b_mult_out_full_R, s_S3_32b_mult_out_full_S;
logic s_S3_32c_mult_out_full_G, s_S3_32c_mult_out_full_R, s_S3_32c_mult_out_full_S;
logic s_S3_32d_mult_out_full_G, s_S3_32d_mult_out_full_R, s_S3_32d_mult_out_full_S;
`define CARRY_IS_A_ONE(cb) ((cb) === 1'b1) // When you take n-bits * n-bits the result is a carry bit + (2n-1)-bits, this checks if the carry bit is a 1 or not
// G
assign s_S3_128_mult_out_full_G = `CARRY_IS_A_ONE(s_S2_128_mult_out_full[225])  ? s_S2_128_mult_out_full[112] : s_S2_128_mult_out_full[111];
assign s_S3_64a_mult_out_full_G = `CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105])  ? s_S2_64a_mult_out_full[52]  : s_S2_64a_mult_out_full[51];
assign s_S3_64b_mult_out_full_G = `CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105])  ? s_S2_64b_mult_out_full[52]  : s_S2_64b_mult_out_full[51];
assign s_S3_32a_mult_out_full_G = `CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47])   ? s_S2_32a_mult_out_full[23]  : s_S2_32a_mult_out_full[22];
assign s_S3_32b_mult_out_full_G = `CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47])   ? s_S2_32b_mult_out_full[23]  : s_S2_32b_mult_out_full[22];
assign s_S3_32c_mult_out_full_G = `CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47])   ? s_S2_32c_mult_out_full[23]  : s_S2_32c_mult_out_full[22];
assign s_S3_32d_mult_out_full_G = `CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47])   ? s_S2_32d_mult_out_full[23]  : s_S2_32d_mult_out_full[22];
// R
assign s_S3_128_mult_out_full_R = `CARRY_IS_A_ONE(s_S2_128_mult_out_full[225])  ? s_S2_128_mult_out_full[111] : s_S2_128_mult_out_full[110];
assign s_S3_64a_mult_out_full_R = `CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105])  ? s_S2_64a_mult_out_full[51]  : s_S2_64a_mult_out_full[50];
assign s_S3_64b_mult_out_full_R = `CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105])  ? s_S2_64b_mult_out_full[51]  : s_S2_64b_mult_out_full[50];
assign s_S3_32a_mult_out_full_R = `CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47])   ? s_S2_32a_mult_out_full[22]  : s_S2_32a_mult_out_full[21];
assign s_S3_32b_mult_out_full_R = `CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47])   ? s_S2_32b_mult_out_full[22]  : s_S2_32b_mult_out_full[21];
assign s_S3_32c_mult_out_full_R = `CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47])   ? s_S2_32c_mult_out_full[22]  : s_S2_32c_mult_out_full[21];
assign s_S3_32d_mult_out_full_R = `CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47])   ? s_S2_32d_mult_out_full[22]  : s_S2_32d_mult_out_full[21];
// S                                                                              // |logic infers an OR tree according to ChatGPT
assign s_S3_128_mult_out_full_S = `CARRY_IS_A_ONE(s_S2_128_mult_out_full[225])  ? |s_S2_128_mult_out_full[110:0] : |s_S2_128_mult_out_full[109:0];
assign s_S3_64a_mult_out_full_S = `CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105])  ? |s_S2_64a_mult_out_full[50:0]  : |s_S2_64a_mult_out_full[49:0];
assign s_S3_64b_mult_out_full_S = `CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105])  ? |s_S2_64b_mult_out_full[50:0]  : |s_S2_64b_mult_out_full[49:0];
assign s_S3_32a_mult_out_full_S = `CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47])   ? |s_S2_32a_mult_out_full[21:0]  : |s_S2_32a_mult_out_full[20:0];
assign s_S3_32b_mult_out_full_S = `CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47])   ? |s_S2_32b_mult_out_full[21:0]  : |s_S2_32b_mult_out_full[20:0];
assign s_S3_32c_mult_out_full_S = `CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47])   ? |s_S2_32c_mult_out_full[21:0]  : |s_S2_32c_mult_out_full[20:0];
assign s_S3_32d_mult_out_full_S = `CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47])   ? |s_S2_32d_mult_out_full[21:0]  : |s_S2_32d_mult_out_full[20:0];
// Potential (partial, candidate, etc whatever you want to call it) results
logic [113:0] s_S3_128_potential_result;
logic [53:0]  s_S3_64a_potential_result;
logic [53:0]  s_S3_64b_potential_result;
logic [24:0]  s_S3_32a_potential_result;
logic [24:0]  s_S3_32b_potential_result;
logic [24:0]  s_S3_32c_potential_result;
logic [24:0]  s_S3_32d_potential_result;
always_ff @( posedge i_clk ) begin : stage3a_ex_man_normalization
  if (!i_rst_n) begin
    s_S3_128_potential_result <= '0;
    s_S3_64a_potential_result <= '0;
    s_S3_64b_potential_result <= '0;
    s_S3_32a_potential_result <= '0;
    s_S3_32b_potential_result <= '0;
    s_S3_32c_potential_result <= '0;
    s_S3_32d_potential_result <= '0;
    s_o_error[4]              <= 1'b0;
    s_o_error[8]              <= 1'b0;
  end
  else begin
    if (s_S3_en) begin
      assert (s_S2_metadata_anikin.sp_mode === s_S2_metadata_force.sp_mode) else begin
        s_o_error[8] <= 1'b1;
        // $fatal(1, "Bad things had happened, (s_S2_metadata_anikin.sp_mode === s_S2_metadata_force.sp_mode) is false.");
      end
      
      case (s_S2_metadata_anikin.sp_mode)
        SINGLE_MODE: begin
          if (s_S3_128_mult_out_full_G === 1'b0) begin
            s_S3_128_potential_result <= {1'b0, (`CARRY_IS_A_ONE(s_S2_128_mult_out_full[225]) ? 
                                                  s_S2_128_mult_out_full[225:113] : s_S2_128_mult_out_full[224:112])};
          end
          else begin // s_S3_128_mult_out_full_G === 1'b1
            if (s_S3_128_mult_out_full_R === 1'b1 || s_S3_128_mult_out_full_S === 1'b1) begin
              s_S3_128_potential_result <= (`CARRY_IS_A_ONE(s_S2_128_mult_out_full[225]) ? 
                                            s_S2_128_mult_out_full[225:113] : s_S2_128_mult_out_full[224:112]) + 1'b1;
            end
            else if (s_S3_128_mult_out_full_R === 1'b0 && s_S3_128_mult_out_full_S === 1'b0) begin
              // Even rule
              if ((`CARRY_IS_A_ONE(s_S2_128_mult_out_full[225]) && s_S2_128_mult_out_full[113] === 1'b1) ||
                  (!(`CARRY_IS_A_ONE(s_S2_128_mult_out_full[225])) && s_S2_128_mult_out_full[112] === 1'b1)) begin
                s_S3_128_potential_result <= (`CARRY_IS_A_ONE(s_S2_128_mult_out_full[225]) ? 
                                              s_S2_128_mult_out_full[225:113] : s_S2_128_mult_out_full[224:112]) + 1'b1;
              end
              else begin // s_S2_128_mult_out_full[113/112] === 1'b0
                s_S3_128_potential_result <= {1'b0, (`CARRY_IS_A_ONE(s_S2_128_mult_out_full[225]) ? 
                                                      s_S2_128_mult_out_full[225:113] : s_S2_128_mult_out_full[224:112])};
              end
            end // R==0 && S==0
            else begin
              // this shouldnt logically happen, right?
            end // else
          end // s_S3_128_mult_out_full_G === 1'b1
        end // SINGLE_MODE

        TWO_SP_MODE: begin
          if (s_S3_64a_mult_out_full_G === 1'b0) begin
            s_S3_64a_potential_result <= (`CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105]) ?
                                           s_S2_64a_mult_out_full[105:53] : s_S2_64a_mult_out_full[104:52]);
          end
          else begin // s_S3_64a_mult_out_full_G === 1'b1
            if (s_S3_64a_mult_out_full_R === 1'b1 || s_S3_64a_mult_out_full_S === 1'b1) begin
              s_S3_64a_potential_result <= (`CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105]) ?
                                             s_S2_64a_mult_out_full[105:53] : s_S2_64a_mult_out_full[104:52]) + 1'b1;
            end
            else if (s_S3_64a_mult_out_full_R === 1'b0 && s_S3_64a_mult_out_full_S === 1'b0) begin
              // Even rule
              if ((`CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105]) && s_S2_64a_mult_out_full[53] === 1'b1) ||
                  (!(`CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105])) && s_S2_64a_mult_out_full[52] === 1'b1)) begin
                s_S3_64a_potential_result <= (`CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105]) ?
                                               s_S2_64a_mult_out_full[105:53] : s_S2_64a_mult_out_full[104:52]) + 1'b1;
              end
              else begin // s_S2_64a_mult_out_full[53/52] === 1'b0
                s_S3_64a_potential_result <= (`CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105]) ?
                                               s_S2_64a_mult_out_full[105:53] : s_S2_64a_mult_out_full[104:52]);
              end
            end // R==0 && S==0
            else begin
              // this shouldnt logically happen, right?
            end // else
          end // s_S3_64a_mult_out_full_G === 1'b1

          if (s_S3_64b_mult_out_full_G === 1'b0) begin
            s_S3_64b_potential_result <= (`CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105]) ?
                                           s_S2_64b_mult_out_full[105:53] : s_S2_64b_mult_out_full[104:52]);
          end
          else begin // s_S3_64b_mult_out_full_G === 1'b1
            if (s_S3_64b_mult_out_full_R === 1'b1 || s_S3_64b_mult_out_full_S === 1'b1) begin
              s_S3_64b_potential_result <= (`CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105]) ?
                                             s_S2_64b_mult_out_full[105:53] : s_S2_64b_mult_out_full[104:52]) + 1'b1;
            end
            else if (s_S3_64b_mult_out_full_R === 1'b0 && s_S3_64b_mult_out_full_S === 1'b0) begin
              // Even rule
              if ((`CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105]) && s_S2_64b_mult_out_full[53] === 1'b1) ||
                  (!(`CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105])) && s_S2_64b_mult_out_full[52] === 1'b1)) begin
                s_S3_64b_potential_result <= (`CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105]) ?
                                               s_S2_64b_mult_out_full[105:53] : s_S2_64b_mult_out_full[104:52]) + 1'b1;
              end
              else begin // s_S2_64b_mult_out_full[53/52] === 1'b0
                s_S3_64b_potential_result <= (`CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105]) ?
                                               s_S2_64b_mult_out_full[105:53] : s_S2_64b_mult_out_full[104:52]);
              end
            end // R==0 && S==0
            else begin
              // this shouldnt logically happen, right?
            end // else
          end // s_S3_64b_mult_out_full_G === 1'b1
        end // TWO_SP_MODE

        FOUR_SP_MODE: begin
          if (s_S3_32a_mult_out_full_G === 1'b0) begin
            s_S3_32a_potential_result <= (`CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47]) ?
                                           s_S2_32a_mult_out_full[47:24] : s_S2_32a_mult_out_full[46:23]);
          end
          else begin // s_S3_32a_mult_out_full_G === 1'b1
            if (s_S3_32a_mult_out_full_R === 1'b1 || s_S3_32a_mult_out_full_S === 1'b1) begin
              s_S3_32a_potential_result <= (`CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47]) ?
                                             s_S2_32a_mult_out_full[47:24] : s_S2_32a_mult_out_full[46:23]) + 1'b1;
            end
            else if (s_S3_32a_mult_out_full_R === 1'b0 && s_S3_32a_mult_out_full_S === 1'b0) begin
              // Even rule
              if ((`CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47]) && s_S2_32a_mult_out_full[24] === 1'b1) ||
                  (!(`CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47])) && s_S2_32a_mult_out_full[23] === 1'b1)) begin
                s_S3_32a_potential_result <= (`CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47]) ?
                                               s_S2_32a_mult_out_full[47:24] : s_S2_32a_mult_out_full[47:24]) + 1'b1;
              end
              else begin // s_S2_32a_mult_out_full[53/52] === 1'b0
                s_S3_32a_potential_result <= (`CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47]) ?
                                               s_S2_32a_mult_out_full[47:24] : s_S2_32a_mult_out_full[47:24]);
              end
            end // R==0 && S==0
            else begin
              // this shouldnt logically happen, right?
            end // else
          end // s_S3_32a_mult_out_full_G === 1'b1

          if (s_S3_32b_mult_out_full_G === 1'b0) begin
            s_S3_32b_potential_result <= (`CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47]) ?
                                           s_S2_32b_mult_out_full[47:24] : s_S2_32b_mult_out_full[46:23]);
          end
          else begin // s_S3_32b_mult_out_full_G === 1'b1
            if (s_S3_32b_mult_out_full_R === 1'b1 || s_S3_32b_mult_out_full_S === 1'b1) begin
              s_S3_32b_potential_result <= (`CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47]) ?
                                             s_S2_32b_mult_out_full[47:24] : s_S2_32b_mult_out_full[46:23]) + 1'b1;
            end
            else if (s_S3_32b_mult_out_full_R === 1'b0 && s_S3_32b_mult_out_full_S === 1'b0) begin
              // Even rule
              if ((`CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47]) && s_S2_32b_mult_out_full[24] === 1'b1) ||
                  (!(`CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47])) && s_S2_32b_mult_out_full[23] === 1'b1)) begin
                s_S3_32b_potential_result <= (`CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47]) ?
                                               s_S2_32b_mult_out_full[47:24] : s_S2_32b_mult_out_full[47:24]) + 1'b1;
              end
              else begin // s_S2_32b_mult_out_full[53/52] === 1'b0
                s_S3_32b_potential_result <= (`CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47]) ?
                                               s_S2_32b_mult_out_full[47:24] : s_S2_32b_mult_out_full[47:24]);
              end
            end // R==0 && S==0
            else begin
              // this shouldnt logically happen, right?
            end // else
          end // s_S3_32b_mult_out_full_G === 1'b1

          if (s_S3_32c_mult_out_full_G === 1'b0) begin
            s_S3_32c_potential_result <= (`CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47]) ?
                                           s_S2_32c_mult_out_full[47:24] : s_S2_32c_mult_out_full[46:23]);
          end
          else begin // s_S3_32c_mult_out_full_G === 1'b1
            if (s_S3_32c_mult_out_full_R === 1'b1 || s_S3_32c_mult_out_full_S === 1'b1) begin
              s_S3_32c_potential_result <= (`CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47]) ?
                                             s_S2_32c_mult_out_full[47:24] : s_S2_32c_mult_out_full[46:23]) + 1'b1;
            end
            else if (s_S3_32c_mult_out_full_R === 1'b0 && s_S3_32c_mult_out_full_S === 1'b0) begin
              // Even rule
              if ((`CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47]) && s_S2_32c_mult_out_full[24] === 1'b1) ||
                  (!(`CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47])) && s_S2_32c_mult_out_full[23] === 1'b1)) begin
                s_S3_32c_potential_result <= (`CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47]) ?
                                               s_S2_32c_mult_out_full[47:24] : s_S2_32c_mult_out_full[47:24]) + 1'b1;
              end
              else begin // s_S2_32c_mult_out_full[53/52] === 1'b0
                s_S3_32c_potential_result <= (`CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47]) ?
                                               s_S2_32c_mult_out_full[47:24] : s_S2_32c_mult_out_full[47:24]);
              end
            end // R==0 && S==0
            else begin
              // this shouldnt logically happen, right?
            end // else
          end // s_S3_32c_mult_out_full_G === 1'b1

          if (s_S3_32d_mult_out_full_G === 1'b0) begin
            s_S3_32d_potential_result <= (`CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47]) ?
                                           s_S2_32d_mult_out_full[47:24] : s_S2_32d_mult_out_full[46:23]);
          end
          else begin // s_S3_32d_mult_out_full_G === 1'b1
            if (s_S3_32d_mult_out_full_R === 1'b1 || s_S3_32d_mult_out_full_S === 1'b1) begin
              s_S3_32d_potential_result <= (`CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47]) ?
                                             s_S2_32d_mult_out_full[47:24] : s_S2_32d_mult_out_full[46:23]) + 1'b1;
            end
            else if (s_S3_32d_mult_out_full_R === 1'b0 && s_S3_32d_mult_out_full_S === 1'b0) begin
              // Even rule
              if ((`CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47]) && s_S2_32d_mult_out_full[24] === 1'b1) ||
                  (!(`CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47])) && s_S2_32d_mult_out_full[23] === 1'b1)) begin
                s_S3_32d_potential_result <= (`CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47]) ?
                                               s_S2_32d_mult_out_full[47:24] : s_S2_32d_mult_out_full[47:24]) + 1'b1;
              end
              else begin // s_S2_32d_mult_out_full[53/52] === 1'b0
                s_S3_32d_potential_result <= (`CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47]) ?
                                               s_S2_32d_mult_out_full[47:24] : s_S2_32d_mult_out_full[47:24]);
              end
            end // R==0 && S==0
            else begin
              // this shouldnt logically happen, right?
            end // else
          end // s_S3_32d_mult_out_full_G === 1'b1
        end // FOUR_SP_MODE

        default: begin
          assert (0) else begin
            s_o_error[4] <= 1'b1;
          end
        end
      endcase // case (i_metadata.sp_mode)
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

/**
 * 3b: Add 1 to the exponent
 */
binary128_t       s_S3_128_jedi;
binary64_t        s_S3_64a_jedi, s_S3_64b_jedi;
binary32_t        s_S3_32a_jedi, s_S3_32b_jedi, s_S3_32c_jedi, s_S3_32d_jedi;
always_ff @( posedge i_clk ) begin : stage3b_increment_exp
  if (!i_rst_n) begin
    s_S3_128_jedi <= '0;
    s_S3_64a_jedi <= '0;
    s_S3_64b_jedi <= '0;
    s_S3_32a_jedi <= '0;
    s_S3_32b_jedi <= '0;
    s_S3_32c_jedi <= '0;
    s_S3_32d_jedi <= '0;
  end
  else begin
    if (s_S3_en) begin
      s_S3_128_jedi.exp <= `CARRY_IS_A_ONE(s_S2_128_mult_out_full[225]) ? (s_S2_128_jedi.exp + 1'b1)
                                                                          : s_S2_128_jedi.exp;
      s_S3_64a_jedi.exp <= `CARRY_IS_A_ONE(s_S2_64a_mult_out_full[105]) ? (s_S2_64a_jedi.exp + 1'b1)
                                                                          : s_S2_64a_jedi.exp;
      s_S3_64b_jedi.exp <= `CARRY_IS_A_ONE(s_S2_64b_mult_out_full[105]) ? (s_S2_64b_jedi.exp + 1'b1)
                                                                          : s_S2_64b_jedi.exp;
      s_S3_32a_jedi.exp <= `CARRY_IS_A_ONE(s_S2_32a_mult_out_full[47])  ? (s_S2_32a_jedi.exp + 1'b1)
                                                                          : s_S2_32a_jedi.exp;
      s_S3_32b_jedi.exp <= `CARRY_IS_A_ONE(s_S2_32b_mult_out_full[47])  ? (s_S2_32b_jedi.exp + 1'b1)
                                                                          : s_S2_32b_jedi.exp;
      s_S3_32c_jedi.exp <= `CARRY_IS_A_ONE(s_S2_32c_mult_out_full[47])  ? (s_S2_32c_jedi.exp + 1'b1)
                                                                          : s_S2_32c_jedi.exp;
      s_S3_32d_jedi.exp <= `CARRY_IS_A_ONE(s_S2_32d_mult_out_full[47])  ? (s_S2_32d_jedi.exp + 1'b1)
                                                                          : s_S2_32d_jedi.exp;

      s_S3_128_jedi.sign <= s_S2_128_jedi.sign;
      s_S3_64a_jedi.sign <= s_S2_64a_jedi.sign;
      s_S3_64b_jedi.sign <= s_S2_64b_jedi.sign;
      s_S3_32a_jedi.sign <= s_S2_32a_jedi.sign;
      s_S3_32b_jedi.sign <= s_S2_32b_jedi.sign;
      s_S3_32c_jedi.sign <= s_S2_32c_jedi.sign;
      s_S3_32d_jedi.sign <= s_S2_32d_jedi.sign;
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


/**
 * 3c: Signal pass through
 */
// Outputs
logic             s_S3_valid128_jedi;
logic             s_S3_valid64a_jedi, s_S3_valid64b_jedi;
logic             s_S3_valid32a_jedi, s_S3_valid32b_jedi, s_S3_valid32c_jedi, s_S3_valid32d_jedi;
float_metadata_t  s_S3_metadata_anikin, s_S3_metadata_force;
always_ff @( posedge i_clk ) begin : stage3c_signal_passthrough
  if (!i_rst_n) begin
    s_S3_valid128_jedi    <= '0;
    s_S3_valid64a_jedi    <= '0;
    s_S3_valid64b_jedi    <= '0;
    s_S3_valid32a_jedi    <= '0;
    s_S3_valid32b_jedi    <= '0;
    s_S3_valid32c_jedi    <= '0;
    s_S3_valid32d_jedi    <= '0;

    s_S3_metadata_anikin  <= '0;
    s_S3_metadata_force   <= '0;
  end
  else begin
    if (s_S3_en) begin
      // valid bit pass through
      s_S3_valid128_jedi    <= s_S2_valid128_jedi;
      s_S3_valid64a_jedi    <= s_S2_valid64a_jedi;
      s_S3_valid64b_jedi    <= s_S2_valid64b_jedi;
      s_S3_valid32a_jedi    <= s_S2_valid32a_jedi;
      s_S3_valid32b_jedi    <= s_S2_valid32b_jedi;
      s_S3_valid32c_jedi    <= s_S2_valid32c_jedi;
      s_S3_valid32d_jedi    <= s_S2_valid32d_jedi;

      // metadata
      s_S3_metadata_anikin  <= s_S2_metadata_anikin;  // Notes to myself: We shall pass this through and use it at the end
      s_S3_metadata_force   <= s_S2_metadata_force;   // Notes to myself: We shall pass this through and use it at the end
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 4: Re-rounding and re-normalization
//=====================================================================================
/**
 * 
 * 4a: As stated in the comments of stage 3, there might be cases where overflow 
 * occured. The goal for this stage is to deal with that.
 * 
 */
logic [113:0] s_S4_128_potential_result;
logic [53:0]  s_S4_64a_potential_result;
logic [53:0]  s_S4_64b_potential_result;
logic [24:0]  s_S4_32a_potential_result;
logic [24:0]  s_S4_32b_potential_result;
logic [24:0]  s_S4_32c_potential_result;
logic [24:0]  s_S4_32d_potential_result;
binary128_t   s_S4_128_jedi;
binary64_t    s_S4_64a_jedi, s_S4_64b_jedi;
binary32_t    s_S4_32a_jedi, s_S4_32b_jedi, s_S4_32c_jedi, s_S4_32d_jedi;
always_ff @( posedge i_clk ) begin : stage4a_renormalize
  if (!i_rst_n) begin
    s_S4_128_jedi             <= '0;
    s_S4_64a_jedi             <= '0;
    s_S4_64b_jedi             <= '0;
    s_S4_32a_jedi             <= '0;
    s_S4_32b_jedi             <= '0;
    s_S4_32c_jedi             <= '0;
    s_S4_32d_jedi             <= '0;

    s_S4_128_potential_result <= '0;
    s_S4_64a_potential_result <= '0;
    s_S4_64b_potential_result <= '0;
    s_S4_32a_potential_result <= '0;
    s_S4_32b_potential_result <= '0;
    s_S4_32c_potential_result <= '0;
    s_S4_32d_potential_result <= '0;
    s_o_error[9]              <= 1'b0;
    s_o_error[10]             <= 1'b0;
  end
  else begin
    if (s_S4_en) begin
      assert (s_S3_metadata_anikin.sp_mode === s_S3_metadata_force.sp_mode) else begin
        s_o_error[9] <= 1'b1;
        // $fatal(1, "Bad things had happened, (s_S3_metadata_anikin.sp_mode === s_S3_metadata_force.sp_mode) is false.");
      end

      case (s_S3_metadata_anikin.sp_mode)
        SINGLE_MODE: begin
          if (s_S3_128_potential_result[113] === 1'b1) begin
            // s_S3_128_potential_result[113] will be a 1 if overflow occurred 
            // 1. Increment exponent
            s_S4_128_jedi.exp         <= s_S3_128_jedi.exp + 1'b1;
            // 2. Right shift
            s_S4_128_potential_result <= {1'b0, s_S3_128_potential_result[113:1]};

            // Pass through the rest
            s_S4_128_jedi.sign        <= s_S3_128_jedi.sign;
            s_S4_128_jedi.mantissa    <= s_S3_128_jedi.mantissa;
          end
          else begin
            // No overflow, pass through
            s_S4_128_jedi             <= s_S3_128_jedi;
            s_S4_128_potential_result <= s_S3_128_potential_result;
          end
        end // SINGLE_MODE

        TWO_SP_MODE: begin
          if (s_S3_64a_potential_result[53] === 1'b1) begin
            // s_S3_64a_potential_result[53] will be a 1 if overflow occurred 
            // 1. Increment exponent
            s_S4_64a_jedi.exp         <= s_S3_64a_jedi.exp + 1'b1;
            // 2. Right shift
            s_S4_64a_potential_result <= {1'b0, s_S3_64a_potential_result[53:1]};

            // Pass through the rest
            s_S4_64a_jedi.sign        <= s_S3_64a_jedi.sign;
            s_S4_64a_jedi.mantissa    <= s_S3_64a_jedi.mantissa;
          end
          else begin
            // No overflow, pass through
            s_S4_64a_jedi             <= s_S3_64a_jedi;
            s_S4_64a_potential_result <= s_S3_64a_potential_result;
          end

          if (s_S3_64b_potential_result[53] === 1'b1) begin
            // s_S3_64b_potential_result[53] will be a 1 if overflow occurred 
            // 1. Increment exponent
            s_S4_64b_jedi.exp         <= s_S3_64b_jedi.exp + 1'b1;
            // 2. Right shift
            s_S4_64b_potential_result <= {1'b0, s_S3_64b_potential_result[53:1]};

            // Pass through the rest
            s_S4_64b_jedi.sign        <= s_S3_64b_jedi.sign;
            s_S4_64b_jedi.mantissa    <= s_S3_64b_jedi.mantissa;
          end
          else begin
            // No overflow, pass through
            s_S4_64b_jedi             <= s_S3_64b_jedi;
            s_S4_64b_potential_result <= s_S3_64b_potential_result;
          end
        end // TWO_SP_MODE

        FOUR_SP_MODE: begin
          if (s_S3_32a_potential_result[24] === 1'b1) begin
            // s_S3_32a_potential_result[24] will be a 1 if overflow occurred 
            // 1. Increment exponent
            s_S4_32a_jedi.exp         <= s_S3_32a_jedi.exp + 1'b1;
            // 2. Right shift
            s_S4_32a_potential_result <= {1'b0, s_S3_32a_potential_result[24:1]};

            // Pass through the rest
            s_S4_32a_jedi.sign        <= s_S3_32a_jedi.sign;
            s_S4_32a_jedi.mantissa    <= s_S3_32a_jedi.mantissa;
          end
          else begin
            // No overflow, pass through
            s_S4_32a_jedi             <= s_S3_32a_jedi;
            s_S4_32a_potential_result <= s_S3_32a_potential_result;
          end

          if (s_S3_32b_potential_result[24] === 1'b1) begin
            // s_S3_32b_potential_result[24] will be a 1 if overflow occurred 
            // 1. Increment exponent
            s_S4_32b_jedi.exp         <= s_S3_32b_jedi.exp + 1'b1;
            // 2. Right shift
            s_S4_32b_potential_result <= {1'b0, s_S3_32b_potential_result[24:1]};

            // Pass through the rest
            s_S4_32b_jedi.sign        <= s_S3_32b_jedi.sign;
            s_S4_32b_jedi.mantissa    <= s_S3_32b_jedi.mantissa;
          end
          else begin
            // No overflow, pass through
            s_S4_32b_jedi             <= s_S3_32b_jedi;
            s_S4_32b_potential_result <= s_S3_32b_potential_result;
          end

          if (s_S3_32c_potential_result[24] === 1'b1) begin
            // s_S3_32c_potential_result[24] will be a 1 if overflow occurred 
            // 1. Increment exponent
            s_S4_32c_jedi.exp         <= s_S3_32c_jedi.exp + 1'b1;
            // 2. Right shift
            s_S4_32c_potential_result <= {1'b0, s_S3_32c_potential_result[24:1]};

            // Pass through the rest
            s_S4_32c_jedi.sign        <= s_S3_32c_jedi.sign;
            s_S4_32c_jedi.mantissa    <= s_S3_32c_jedi.mantissa;
          end
          else begin
            // No overflow, pass through
            s_S4_32c_jedi             <= s_S3_32c_jedi;
            s_S4_32c_potential_result <= s_S3_32c_potential_result;
          end

          if (s_S3_32d_potential_result[24] === 1'b1) begin
            // s_S3_32d_potential_result[24] will be a 1 if overflow occurred 
            // 1. Increment exponent
            s_S4_32d_jedi.exp         <= s_S3_32d_jedi.exp + 1'b1;
            // 2. Right shift
            s_S4_32d_potential_result <= {1'b0, s_S3_32d_potential_result[24:1]};

            // Pass through the rest
            s_S4_32d_jedi.sign        <= s_S3_32d_jedi.sign;
            s_S4_32d_jedi.mantissa    <= s_S3_32d_jedi.mantissa;
          end
          else begin
            // No overflow, pass through
            s_S4_32d_jedi             <= s_S3_32d_jedi;
            s_S4_32d_potential_result <= s_S3_32d_potential_result;
          end
        end // FOUR_SP_MODE

        default: begin
          assert (0) else begin
            s_o_error[10] <= 1'b1;
          end
        end
      endcase // case (i_metadata.sp_mode)
    end // if (s_S4_en) begin
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

/**
 * 4b: Signal passthrough
 */
logic             s_S4_valid128_jedi;
logic             s_S4_valid64a_jedi, s_S4_valid64b_jedi;
logic             s_S4_valid32a_jedi, s_S4_valid32b_jedi, s_S4_valid32c_jedi, s_S4_valid32d_jedi;
float_metadata_t  s_S4_metadata_anikin, s_S4_metadata_force;
always_ff @( posedge i_clk ) begin : stage4b_signal_passthrough
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
      s_S4_metadata_anikin  <= s_S3_metadata_anikin;  // Notes to myself: We shall pass this through and use it at the end
      s_S4_metadata_force   <= s_S3_metadata_force;   // Notes to myself: We shall pass this through and use it at the end
    end // if (s_S4_en) begin
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 5: Finally, we can map the s_Sx_xxx_potential_result into the mantissa of
//          jedi!
//=====================================================================================
/**
 * 5a: Map potential result into mantissa
 */
binary128_t   s_S5_128_jedi;
binary64_t    s_S5_64a_jedi, s_S5_64b_jedi;
binary32_t    s_S5_32a_jedi, s_S5_32b_jedi, s_S5_32c_jedi, s_S5_32d_jedi;
always_ff @( posedge i_clk ) begin : stage5a_map_pot_res_into_mantissa
  if (!i_rst_n) begin
    s_S5_128_jedi <= '0;
    s_S5_64a_jedi <= '0;
    s_S5_64b_jedi <= '0;
    s_S5_32a_jedi <= '0;
    s_S5_32b_jedi <= '0;
    s_S5_32c_jedi <= '0;
    s_S5_32d_jedi <= '0;
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
    if (s_S5_en) begin
      assert (s_S4_metadata_anikin.sp_mode === s_S4_metadata_force.sp_mode) else begin
        s_o_error[11] <= 1'b1;
        // $fatal(1, "Bad things had happened, (s_S4_metadata_anikin.sp_mode === s_S4_metadata_force.sp_mode) is false.");
      end
      case (s_S4_metadata_anikin.sp_mode)
        SINGLE_MODE: begin
          if (!(s_S4_metadata_anikin.float_type_a === ZERO || s_S4_metadata_force.float_type_a === ZERO) && 
              ((s_S4_metadata_anikin.float_type_a === NAN || s_S4_metadata_force.float_type_a === NAN) ||
              (s_S4_128_jedi.exp === '1 && s_S4_128_potential_result[111:0] !== '0 && s_S4_128_potential_result[111:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S5_128_jedi.sign      <= s_S4_128_jedi.sign;
            s_S5_128_jedi.exp       <= '1;
            s_S5_128_jedi.mantissa  <= 112'hA; // non-0
          end
          else if (s_S4_metadata_anikin.float_type_a === ZERO || s_S4_metadata_force.float_type_a === ZERO) begin
            // If either is a zero, output will be a zero
            s_S5_128_jedi.sign      <= s_S4_128_jedi.sign;
            s_S5_128_jedi.exp       <= '0;
            s_S5_128_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_a === POS_INF || s_S4_metadata_force.float_type_a === POS_INF) ||
                   (s_S4_128_jedi.sign === '0 && s_S4_128_jedi.exp === '1 && s_S4_128_potential_result[111:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S5_128_jedi.sign      <= 1'b0;
            s_S5_128_jedi.exp       <= '1;
            s_S5_128_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_a === NEG_INF || s_S4_metadata_force.float_type_a === NEG_INF) ||
                   (s_S4_128_jedi.sign === '1 && s_S4_128_jedi.exp === '1 && s_S4_128_potential_result[111:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S5_128_jedi.sign      <= 1'b1;
            s_S5_128_jedi.exp       <= '1;
            s_S5_128_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S4_metadata_anikin.float_type_a === POS_DENORMAL || s_S4_metadata_force.float_type_a === POS_DENORMAL) ||
                   (s_S4_metadata_anikin.float_type_a === NEG_DENORMAL || s_S4_metadata_force.float_type_a === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S5_128_jedi.sign      <= s_S4_128_jedi.sign;
            s_S5_128_jedi.exp       <= '0;
            s_S5_128_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S4_128_potential_result[112] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[12] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S5_128_jedi.sign      <= s_S4_128_jedi.sign;
            s_S5_128_jedi.exp       <= s_S4_128_jedi.exp;
            s_S5_128_jedi.mantissa  <= s_S4_128_potential_result[111:0];
          end
        end // SINGLE_MODE

        TWO_SP_MODE: begin
          if (!(s_S4_metadata_anikin.float_type_a === ZERO || s_S4_metadata_force.float_type_a === ZERO) &&
              ((s_S4_metadata_anikin.float_type_a === NAN || s_S4_metadata_force.float_type_a === NAN) ||
              (s_S4_64a_jedi.exp === '1 && s_S4_64a_potential_result[51:0] !== '0 && s_S4_64a_potential_result[51:0] !== '1))) begin
            // If either is NaN, output will be NaN
            // $display(">>>>> boba tea gnarly");
            s_S5_64a_jedi.sign      <= s_S4_64a_jedi.sign;
            s_S5_64a_jedi.exp       <= '1;
            s_S5_64a_jedi.mantissa  <= 52'hA; // non-0
          end
          else if (s_S4_metadata_anikin.float_type_a === ZERO || s_S4_metadata_force.float_type_a === ZERO) begin
            // If either is a zero, output will be a zero
            s_S5_64a_jedi.sign      <= s_S4_64a_jedi.sign;
            s_S5_64a_jedi.exp       <= '0;
            s_S5_64a_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_a === POS_INF || s_S4_metadata_force.float_type_a === POS_INF) ||
                   (s_S4_64a_jedi.sign === '0 && s_S4_64a_jedi.exp === '1 && s_S4_64a_potential_result[51:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S5_64a_jedi.sign      <= 1'b0;
            s_S5_64a_jedi.exp       <= '1;
            s_S5_64a_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_a === NEG_INF || s_S4_metadata_force.float_type_a === NEG_INF) ||
                   (s_S4_64a_jedi.sign === '1 && s_S4_64a_jedi.exp === '1 && s_S4_64a_potential_result[51:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S5_64a_jedi.sign      <= 1'b1;
            s_S5_64a_jedi.exp       <= '1;
            s_S5_64a_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S4_metadata_anikin.float_type_a === POS_DENORMAL || s_S4_metadata_force.float_type_a === POS_DENORMAL) ||
                   (s_S4_metadata_anikin.float_type_a === NEG_DENORMAL || s_S4_metadata_force.float_type_a === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S5_64a_jedi.sign      <= s_S4_64a_jedi.sign;
            s_S5_64a_jedi.exp       <= '0;
            s_S5_64a_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S4_64a_potential_result[52] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[13] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S5_64a_jedi.sign      <= s_S4_64a_jedi.sign;
            s_S5_64a_jedi.exp       <= s_S4_64a_jedi.exp;
            s_S5_64a_jedi.mantissa  <= s_S4_64a_potential_result[51:0];
          end

          if (!(s_S4_metadata_anikin.float_type_b === ZERO || s_S4_metadata_force.float_type_b === ZERO) &&
              ((s_S4_metadata_anikin.float_type_b === NAN || s_S4_metadata_force.float_type_b === NAN) ||
              (s_S4_64b_jedi.exp === '1 && s_S4_64a_potential_result[51:0] !== '0))) begin
            // If either is NaN, output will be NaN
            s_S5_64b_jedi.sign      <= s_S4_64b_jedi.sign;
            s_S5_64b_jedi.exp       <= '1;
            s_S5_64b_jedi.mantissa  <= 52'hA; // non-0
          end
          else if (s_S4_metadata_anikin.float_type_b === ZERO || s_S4_metadata_force.float_type_b === ZERO) begin
            // If either is a zero, output will be a zero
            s_S5_64b_jedi.sign      <= s_S4_64b_jedi.sign;
            s_S5_64b_jedi.exp       <= '0;
            s_S5_64b_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_b === POS_INF || s_S4_metadata_force.float_type_b === POS_INF) ||
                   (s_S4_64b_jedi.sign === '0 && s_S4_64b_jedi.exp === '1 && s_S4_64b_potential_result[51:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S5_64b_jedi.sign      <= 1'b0;
            s_S5_64b_jedi.exp       <= '1;
            s_S5_64b_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_b === NEG_INF || s_S4_metadata_force.float_type_b === NEG_INF) ||
                   (s_S4_64b_jedi.sign === '1 && s_S4_64b_jedi.exp === '1 && s_S4_64b_potential_result[51:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S5_64b_jedi.sign      <= 1'b1;
            s_S5_64b_jedi.exp       <= '1;
            s_S5_64b_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S4_metadata_anikin.float_type_b === POS_DENORMAL || s_S4_metadata_force.float_type_b === POS_DENORMAL) ||
                   (s_S4_metadata_anikin.float_type_b === NEG_DENORMAL || s_S4_metadata_force.float_type_b === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S5_64b_jedi.sign      <= s_S4_64b_jedi.sign;
            s_S5_64b_jedi.exp       <= '0;
            s_S5_64b_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S4_64b_potential_result[52] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[14] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S5_64b_jedi.sign      <= s_S4_64b_jedi.sign;
            s_S5_64b_jedi.exp       <= s_S4_64b_jedi.exp;
            s_S5_64b_jedi.mantissa  <= s_S4_64b_potential_result[51:0];
          end
        end // TWO_SP_MODE

        FOUR_SP_MODE: begin
          if (!(s_S4_metadata_anikin.float_type_a === ZERO || s_S4_metadata_force.float_type_a === ZERO) &&
              ((s_S4_metadata_anikin.float_type_a === NAN || s_S4_metadata_force.float_type_a === NAN) ||
              (s_S4_32a_jedi.exp === '1 && s_S4_32a_potential_result[22:0] !== '0 && s_S4_32a_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S5_32a_jedi.sign      <= s_S4_32a_jedi.sign;
            s_S5_32a_jedi.exp       <= '1;
            s_S5_32a_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S4_metadata_anikin.float_type_a === ZERO || s_S4_metadata_force.float_type_a === ZERO) begin
            // If either is a zero, output will be a zero
            s_S5_32a_jedi.sign      <= s_S4_32a_jedi.sign;
            s_S5_32a_jedi.exp       <= '0;
            s_S5_32a_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_a === POS_INF || s_S4_metadata_force.float_type_a === POS_INF) ||
                   (s_S4_32a_jedi.sign === '0 && s_S4_32a_jedi.exp === '1 && s_S4_32a_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S5_32a_jedi.sign      <= 1'b0;
            s_S5_32a_jedi.exp       <= '1;
            s_S5_32a_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_a === NEG_INF || s_S4_metadata_force.float_type_a === NEG_INF) ||
                   (s_S4_32a_jedi.sign === '1 && s_S4_32a_jedi.exp === '1 && s_S4_32a_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S5_32a_jedi.sign      <= 1'b1;
            s_S5_32a_jedi.exp       <= '1;
            s_S5_32a_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S4_metadata_anikin.float_type_a === POS_DENORMAL || s_S4_metadata_force.float_type_a === POS_DENORMAL) ||
                   (s_S4_metadata_anikin.float_type_a === NEG_DENORMAL || s_S4_metadata_force.float_type_a === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S5_32a_jedi.sign      <= s_S4_32a_jedi.sign;
            s_S5_32a_jedi.exp       <= '0;
            s_S5_32a_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S4_32a_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[15] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S5_32a_jedi.sign      <= s_S4_32a_jedi.sign;
            s_S5_32a_jedi.exp       <= s_S4_32a_jedi.exp;
            s_S5_32a_jedi.mantissa  <= s_S4_32a_potential_result[22:0];
          end


          if (!(s_S4_metadata_anikin.float_type_b === ZERO || s_S4_metadata_force.float_type_b === ZERO) &&
              ((s_S4_metadata_anikin.float_type_b === NAN || s_S4_metadata_force.float_type_b === NAN) ||
              (s_S4_32b_jedi.exp === '1 && s_S4_32b_potential_result[22:0] !== '0 && s_S4_32b_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S5_32b_jedi.sign      <= s_S4_32b_jedi.sign;
            s_S5_32b_jedi.exp       <= '1;
            s_S5_32b_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S4_metadata_anikin.float_type_b === ZERO || s_S4_metadata_force.float_type_b === ZERO) begin
            // If either is a zero, output will be a zero
            s_S5_32b_jedi.sign      <= s_S4_32b_jedi.sign;
            s_S5_32b_jedi.exp       <= '0;
            s_S5_32b_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_b === POS_INF || s_S4_metadata_force.float_type_b === POS_INF) ||
                   (s_S4_32b_jedi.sign === '0 && s_S4_32b_jedi.exp === '1 && s_S4_32b_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S5_32b_jedi.sign      <= 1'b0;
            s_S5_32b_jedi.exp       <= '1;
            s_S5_32b_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_b === NEG_INF || s_S4_metadata_force.float_type_b === NEG_INF) ||
                   (s_S4_32b_jedi.sign === '1 && s_S4_32b_jedi.exp === '1 && s_S4_32b_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S5_32b_jedi.sign      <= 1'b1;
            s_S5_32b_jedi.exp       <= '1;
            s_S5_32b_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S4_metadata_anikin.float_type_b === POS_DENORMAL || s_S4_metadata_force.float_type_b === POS_DENORMAL) ||
                   (s_S4_metadata_anikin.float_type_b === NEG_DENORMAL || s_S4_metadata_force.float_type_b === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S5_32b_jedi.sign      <= s_S4_32b_jedi.sign;
            s_S5_32b_jedi.exp       <= '0;
            s_S5_32b_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S4_32b_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[16] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S5_32b_jedi.sign      <= s_S4_32b_jedi.sign;
            s_S5_32b_jedi.exp       <= s_S4_32b_jedi.exp;
            s_S5_32b_jedi.mantissa  <= s_S4_32b_potential_result[22:0];
          end


          if (!(s_S4_metadata_anikin.float_type_c === ZERO || s_S4_metadata_force.float_type_c === ZERO) &&
              ((s_S4_metadata_anikin.float_type_c === NAN || s_S4_metadata_force.float_type_c === NAN) ||
              (s_S4_32c_jedi.exp === '1 && s_S4_32c_potential_result[22:0] !== '0 && s_S4_32c_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S5_32c_jedi.sign      <= s_S4_32c_jedi.sign;
            s_S5_32c_jedi.exp       <= '1;
            s_S5_32c_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S4_metadata_anikin.float_type_c === ZERO || s_S4_metadata_force.float_type_c === ZERO) begin
            // If either is a zero, output will be a zero
            s_S5_32c_jedi.sign      <= s_S4_32c_jedi.sign;
            s_S5_32c_jedi.exp       <= '0;
            s_S5_32c_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_c === POS_INF || s_S4_metadata_force.float_type_c === POS_INF) ||
                   (s_S4_32c_jedi.sign === '0 && s_S4_32c_jedi.exp === '1 && s_S4_32c_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S5_32c_jedi.sign      <= 1'b0;
            s_S5_32c_jedi.exp       <= '1;
            s_S5_32c_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_c === NEG_INF || s_S4_metadata_force.float_type_c === NEG_INF) ||
                   (s_S4_32c_jedi.sign === '1 && s_S4_32c_jedi.exp === '1 && s_S4_32c_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S5_32c_jedi.sign      <= 1'b1;
            s_S5_32c_jedi.exp       <= '1;
            s_S5_32c_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S4_metadata_anikin.float_type_c === POS_DENORMAL || s_S4_metadata_force.float_type_c === POS_DENORMAL) ||
                   (s_S4_metadata_anikin.float_type_c === NEG_DENORMAL || s_S4_metadata_force.float_type_c === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S5_32c_jedi.sign      <= s_S4_32c_jedi.sign;
            s_S5_32c_jedi.exp       <= '0;
            s_S5_32c_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S4_32c_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[17] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S5_32c_jedi.sign      <= s_S4_32c_jedi.sign;
            s_S5_32c_jedi.exp       <= s_S4_32c_jedi.exp;
            s_S5_32c_jedi.mantissa  <= s_S4_32c_potential_result[22:0];
          end

          
          if (!(s_S4_metadata_anikin.float_type_d === ZERO || s_S4_metadata_force.float_type_d === ZERO) &&
              ((s_S4_metadata_anikin.float_type_d === NAN || s_S4_metadata_force.float_type_d === NAN) ||
              (s_S4_32d_jedi.exp === '1 && s_S4_32d_potential_result[22:0] !== '0 && s_S4_32d_potential_result[22:0] !== '1))) begin
            // If either is NaN, output will be NaN
            s_S5_32d_jedi.sign      <= s_S4_32d_jedi.sign;
            s_S5_32d_jedi.exp       <= '1;
            s_S5_32d_jedi.mantissa  <= 23'hA; // non-0
          end
          else if (s_S4_metadata_anikin.float_type_d === ZERO || s_S4_metadata_force.float_type_d === ZERO) begin
            // If either is a zero, output will be a zero
            s_S5_32d_jedi.sign      <= s_S4_32d_jedi.sign;
            s_S5_32d_jedi.exp       <= '0;
            s_S5_32d_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_d === POS_INF || s_S4_metadata_force.float_type_d === POS_INF) ||
                   (s_S4_32d_jedi.sign === '0 && s_S4_32d_jedi.exp === '1 && s_S4_32d_potential_result[22:0] === '1)) begin
            // If either is +ve inf, output will be pos inf
            s_S5_32d_jedi.sign      <= 1'b0;
            s_S5_32d_jedi.exp       <= '1;
            s_S5_32d_jedi.mantissa  <= '0;
          end
          else if ((s_S4_metadata_anikin.float_type_d === NEG_INF || s_S4_metadata_force.float_type_d === NEG_INF) ||
                   (s_S4_32d_jedi.sign === '1 && s_S4_32d_jedi.exp === '1 && s_S4_32d_potential_result[22:0] === '1)) begin
            // If either is -ve inf, output will be neg inf
            s_S5_32d_jedi.sign      <= 1'b1;
            s_S5_32d_jedi.exp       <= '1;
            s_S5_32d_jedi.mantissa  <= '0;
          end
          // For now, we treat denormals like ZERO, todo (lowkey low priority) actually implement denormal
          else if ((s_S4_metadata_anikin.float_type_d === POS_DENORMAL || s_S4_metadata_force.float_type_d === POS_DENORMAL) ||
                   (s_S4_metadata_anikin.float_type_d === NEG_DENORMAL || s_S4_metadata_force.float_type_d === NEG_DENORMAL)) begin
            // If either is a zero, output will be a zero
            s_S5_32d_jedi.sign      <= s_S4_32d_jedi.sign;
            s_S5_32d_jedi.exp       <= '0;
            s_S5_32d_jedi.mantissa  <= '0;
          end
          else begin
            // NORMAL Types
            assert (s_S4_32d_potential_result[23] === 1'b1) else begin
              // Make sure implicit 1 is there, this HAS to be true
              s_o_error[18] <= 1'b1;
              // $fatal(1, "Implicit 1 missing, this is bad");
            end
            
            s_S5_32d_jedi.sign      <= s_S4_32d_jedi.sign;
            s_S5_32d_jedi.exp       <= s_S4_32d_jedi.exp;
            s_S5_32d_jedi.mantissa  <= s_S4_32d_potential_result[22:0];
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
 * 5b: Signal passthrough
 */
logic             s_S5_valid128_jedi;
logic             s_S5_valid64a_jedi, s_S5_valid64b_jedi;
logic             s_S5_valid32a_jedi, s_S5_valid32b_jedi, s_S5_valid32c_jedi, s_S5_valid32d_jedi;
float_metadata_t  s_S5_metadata_anikin, s_S5_metadata_force;
always_ff @( posedge i_clk ) begin : stage5b_signal_passthrough
  if (!i_rst_n) begin
    s_S5_valid128_jedi    <= '0;
    s_S5_valid64a_jedi    <= '0;
    s_S5_valid64b_jedi    <= '0;
    s_S5_valid32a_jedi    <= '0;
    s_S5_valid32b_jedi    <= '0;
    s_S5_valid32c_jedi    <= '0;
    s_S5_valid32d_jedi    <= '0;

    s_S5_metadata_anikin  <= '0;
    s_S5_metadata_force   <= '0;
  end
  else begin
    if (s_S5_en) begin
      // valid bit pass through
      s_S5_valid128_jedi    <= s_S4_valid128_jedi;
      s_S5_valid64a_jedi    <= s_S4_valid64a_jedi;
      s_S5_valid64b_jedi    <= s_S4_valid64b_jedi;
      s_S5_valid32a_jedi    <= s_S4_valid32a_jedi;
      s_S5_valid32b_jedi    <= s_S4_valid32b_jedi;
      s_S5_valid32c_jedi    <= s_S4_valid32c_jedi;
      s_S5_valid32d_jedi    <= s_S4_valid32d_jedi;

      // metadata
      s_S5_metadata_anikin  <= s_S4_metadata_anikin;  // Notes to myself: We shall pass this through and use it at the end
      s_S5_metadata_force   <= s_S4_metadata_force;   // Notes to myself: We shall pass this through and use it at the end
    end // if (s_S5_en) begin
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata           = s_S5_metadata_anikin/*should be the same as s_S5_metadata_force*/;
assign o_out_jedi           = (s_S5_metadata_anikin.sp_mode === SINGLE_MODE)  ? s_S5_128_jedi                                                 :
                              (s_S5_metadata_anikin.sp_mode === TWO_SP_MODE)  ? {s_S5_64a_jedi, s_S5_64b_jedi}                                :
                              (s_S5_metadata_anikin.sp_mode === FOUR_SP_MODE) ? {s_S5_32a_jedi, s_S5_32b_jedi, s_S5_32c_jedi, s_S5_32d_jedi}  :
                              128'hB1B1; // https://youtu.be/smdmEhkIRVc?si=WFrAqEqgQmf-JaDX
assign o_valid128_jedi      = s_S5_valid128_jedi;
assign o_valid64a_jedi      = s_S5_valid64a_jedi;
assign o_valid64b_jedi      = s_S5_valid64b_jedi;
assign o_valid32a_jedi      = s_S5_valid32a_jedi;
assign o_valid32b_jedi      = s_S5_valid32b_jedi;
assign o_valid32c_jedi      = s_S5_valid32c_jedi;
assign o_valid32d_jedi      = s_S5_valid32d_jedi;
assign o_sanity_identifier  = MODULE_IDENTIFIER;
assign o_error              = s_o_error;
assign o_debug              = s_o_debug;


endmodule // module sp_fpmultiplier #()
