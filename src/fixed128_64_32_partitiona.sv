/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 1/8/2026
 * 
 ********************************************************************
 * 
 * Description:
 * This a module to deal with the a partition of fixed128, fixed64,
 * and fixed32 look-up-table (LUT).
 * 
 * What is the partitions? See the graph in:
 * https://github.com/jona1115/SPEX-128/issues/14
 * 
 * In milestone 1, we process the LUT for fixed128, fixed64, and 
 * fixed32 separately in my_fixed128_64_partitiona and 
 * my_fixed32_partitiona_a,b,c,d. The idea for this module now is to
 * combine them all into one module for all partitiona's computation.
 * 
 * The implementation is to optimize for the dual port property of 
 * BRAMs on FPGAs and SRAMs on ASICs.
 * 
 ********************************************************************
 * 
 * Modification history:
 *       Ver   |  Who       |  Date	       |  Changes
 *     ------- + ---------- + ------------ + -----------------------
 *       1.00  |  Jonathan  |  1/8/2026    |  Birth of this file
 * 
 *******************************************************************/

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;
import binary128_convert_pkg::*;
import fixed128_pkg::*;
import fixed64_pkg::*;
import fixed32_pkg::*;

module fixed128_64_32_partitiona #(
  parameter string INIT_128a_POS_FILE = "fixed128_0a_partition.hex",
  parameter string INIT_128a_NEG_FILE = "fixed128_1a_partition.hex",
  
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
  input   logic [10:0]                            i_lane_a,   // bit10 is the sign bit, bit[9:0] are the actual partition a
  input   logic [10:0]                            i_lane_b,   // this is for the second 64b subword (aka 64b, it is called the b subword in float_to_fixed module)
  input   logic [10:0]                            i_lane_c,   // this is for the second 64b subword (aka 64b, it is called the b subword in float_to_fixed module)
  input   logic [10:0]                            i_lane_d,   // this is for the second 64b subword (aka 64b, it is called the b subword in float_to_fixed module)
  output  binary128_t                             o_exp_a128,
  output  binary64_t                              o_exp_a64a,
  output  binary64_t                              o_exp_a64b,
  output  binary32_t                              o_exp_a32a,
  output  binary32_t                              o_exp_a32b,
  output  binary32_t                              o_exp_a32c,
  output  binary32_t                              o_exp_a32d,

  // Upstream Handshake
  input   logic                                   i_valid128,
  input   logic                                   i_valid64a,
  input   logic                                   i_valid64b,
  input   logic                                   i_valid32a,
  input   logic                                   i_valid32b,
  input   logic                                   i_valid32c,
  input   logic                                   i_valid32d,

  // Downstream Handshake
  output  logic                                   o_valid128,
  output  logic                                   o_valid64a,
  output  logic                                   o_valid64b,
  output  logic                                   o_valid32a,
  output  logic                                   o_valid32b,
  output  logic                                   o_valid32c,
  output  logic                                   o_valid32d,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Module body
//=====================================================================================

// Default stuff out
logic [DEBUG_SIGNAL_NUM_BITS-1:0]   s_o_debug;
logic [ERROR_SIGNAL_NUM_BITS-1:0]   s_o_error;
always_ff @( posedge i_clk ) begin : defaulter
  if (!i_rst_n) begin
    s_o_error <= '0;
    s_o_debug <= '0;
  end
end

/**
 * FSM
 */
typedef enum logic [1:0] { 
  S0_IDLE     = 2'b00,
  S1          = 2'b01,
  S2          = 2'b10,
  S3          = 2'b11
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
logic s_S0_en, s_S1_en, s_S2_en, s_S3_en;
always_comb begin : stage_en_control
  // Defaults
  s_next_state = s_curr_state;
  s_S0_en = '0;
  s_S1_en = '0;
  s_S2_en = '0;
  s_S3_en = '0;

  unique case (s_curr_state)
    S0_IDLE: begin
      if ( i_valid128 |
          (i_valid64a & i_valid64b) |                           // "all-or-nothing" rule
          (i_valid32a & i_valid32b & i_valid32c & i_valid32d)   // "all-or-nothing" rule
         ) begin
        s_next_state = S1;
      end
    end
    S1: begin
      s_S1_en = 1'b1;
      // if (i_metadata.sp_mode === FOUR_SP_MODE) begin
        s_next_state = S2;
      // end // if (i_metadata.sp_mode === FOUR_SP_MODE)
      // else begin
      //   s_next_state = S0_IDLE;
      // end // else
    end
    S2: begin
      s_S2_en = 1'b1;
      s_next_state = S0_IDLE;
    end
    // S3: begin
    //   s_S3_en = 1'b1;
    //   s_next_state = S0_IDLE;
    // end
    default: begin
      s_next_state = S0_IDLE;
    end
  endcase
end

//=====================================================================================
// Stage 1: Process 128, 64a, b, or 32a, b
//=====================================================================================
/**
 * Stage 1a block: Process 128, 64a, b, or 32a, b
 */
(* rom_style = "block" *) binary128_t mempos128  [0:1023]; // Infer a BRAM
(* rom_style = "block" *) binary128_t memneg128  [0:1023]; // Infer a BRAM
initial $readmemh(INIT_128a_POS_FILE, mempos128);
initial $readmemh(INIT_128a_NEG_FILE, memneg128);
logic[127:0] s_stage1a_exp_a128;
logic[127:0] s_stage1a_exp_a64a;
logic[127:0] s_stage1a_exp_a64b;
logic[127:0] s_stage1a_exp_a32a;
logic[127:0] s_stage1a_exp_a32b;
always_ff @( posedge i_clk ) begin : stage1a
  if (!i_rst_n) begin
    s_stage1a_exp_a128 <= '0;
    s_stage1a_exp_a64a <= '0;
    s_stage1a_exp_a64b <= '0;
    s_stage1a_exp_a32a <= '0;
    s_stage1a_exp_a32b <= '0;
  end
  else begin
    if (s_S1_en) begin
      case (i_metadata.sp_mode)
        SINGLE_MODE: begin
          if (i_valid128 === 1'b1) begin
            if (i_lane_a[10] === 1'b0) begin
              // Positive input a
              s_stage1a_exp_a128 <= mempos128[i_lane_a[9:0]];
            end
            else begin
              // Negative input a
              s_stage1a_exp_a128 <= memneg128[i_lane_a[9:0]];
            end
          end // if (i_valid128 === 1'b1)
        end // SINGLE_MODE

        TWO_SP_MODE: begin
          if (i_valid64a === 1'b1 && i_valid64b === 1'b1) begin // To keep output in sync, both has to be valid 
            if (i_lane_a[10] === 1'b0) begin                    // to proceed; also, we have the "all or nothing"
              // Positive input a(a)                            // rule
              s_stage1a_exp_a64a <= mempos128[i_lane_a[9:0]];
            end
            else begin
              // Negative input a(a)
              s_stage1a_exp_a64a <= memneg128[i_lane_a[9:0]];
            end

            if (i_lane_b[10] === 1'b0) begin
              // Positive input a(b)
              s_stage1a_exp_a64b <= mempos128[i_lane_b[9:0]];
            end
            else begin
              // Negative input a(b)
              s_stage1a_exp_a64b <= memneg128[i_lane_b[9:0]];
            end
          end // if (i_valid64a === 1'b1 && i_valid64b === 1'b1)
        end // TWO_SP_MODE

        FOUR_SP_MODE: begin
          // "all or nothing" rule check
          if (i_valid32a === 1'b1 && i_valid32b === 1'b1 && i_valid32c === 1'b1 && i_valid32d === 1'b1) begin
            if (i_lane_a[10] === 1'b0) begin
              // Positive input a(a)
              s_stage1a_exp_a32a <= mempos128[i_lane_a[9:0]];
            end
            else begin
              // Negative input a(a)
              s_stage1a_exp_a32a <= memneg128[i_lane_a[9:0]];
            end

            if (i_lane_b[10] === 1'b0) begin
              // Positive input a(b)
              s_stage1a_exp_a32b <= mempos128[i_lane_b[9:0]];
            end
            else begin
              // Negative input a(b)
              s_stage1a_exp_a32b <= memneg128[i_lane_b[9:0]];
            end
          end // if (i_valid64a === 1'b1 && i_valid64b === 1'b1)
        end // FOUR_SP_MODE

        default: begin
          assert (0) else begin
              s_o_error[0] <= 1'b1;
            end
        end // default
      endcase
    end // if (s_S1_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

/**
 * Stage 1b block: Propogate valid bit and metadata bits
 * 
 */
logic             s_stage1b_valid128;
logic             s_stage1b_valid64a;
logic             s_stage1b_valid64b;
logic             s_stage1b_valid32a;
logic             s_stage1b_valid32b;
logic             s_stage1b_valid32c;
logic             s_stage1b_valid32d;
float_metadata_t  s_stage1b_metadata;
always_ff @( posedge i_clk ) begin : stage1b
  if (!i_rst_n) begin
    s_stage1b_valid128 <= '0;
    s_stage1b_valid64a <= '0;
    s_stage1b_valid64b <= '0;
    s_stage1b_valid32a <= '0;
    s_stage1b_valid32b <= '0;
    s_stage1b_valid32c <= '0;
    s_stage1b_valid32d <= '0;
    s_stage1b_metadata <= '0;
  end
  else begin
    // if (s_S1_en) begin
      s_stage1b_valid128 <= s_S1_en & i_valid128; // & with s_S1_en meaning if system is valid, output will be propogated, else after anding will be 0
      s_stage1b_valid64a <= s_S1_en & i_valid64a;
      s_stage1b_valid64b <= s_S1_en & i_valid64b;
      s_stage1b_valid32a <= s_S1_en & i_valid32a;
      s_stage1b_valid32b <= s_S1_en & i_valid32b;
      s_stage1b_valid32c <= s_S1_en & i_valid32c;
      s_stage1b_valid32d <= s_S1_en & i_valid32d;
      s_stage1b_metadata <= i_metadata;
    // end // if (s_S1_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 2
//=====================================================================================
logic[127:0]  s_stage2a_exp_a32c;
logic[127:0]  s_stage2a_exp_a32d;
binary128_t   s_stage2a_exp_a128;
binary64_t    s_stage2a_exp_a64a;
binary64_t    s_stage2a_exp_a64b;
binary32_t    s_stage2a_exp_a32a;
binary32_t    s_stage2a_exp_a32b;
always_ff @( posedge i_clk ) begin : stage2a
  if (!i_rst_n) begin
    s_stage2a_exp_a128  <= '0;
    s_stage2a_exp_a64a  <= '0;
    s_stage2a_exp_a64b  <= '0;
    s_stage2a_exp_a32c  <= '0;
    s_stage2a_exp_a32d  <= '0;
    s_stage2a_exp_a32a  <= '0;
    s_stage2a_exp_a32b  <= '0;
  end
  else begin
    if (s_S2_en) begin
      case (s_stage1b_metadata.sp_mode)
        SINGLE_MODE: begin
          // passthrough
          s_stage2a_exp_a128 <= binary128_t'(s_stage1a_exp_a128);
        end // SINGLE_MODE

        TWO_SP_MODE: begin
          s_stage2a_exp_a64a <= binary128_to_binary64_rne(s_stage1a_exp_a64a);
          s_stage2a_exp_a64b <= binary128_to_binary64_rne(s_stage1a_exp_a64b);
        end // TWO_SP_MODE

        FOUR_SP_MODE: begin
          // "all or nothing" rule check
          if (i_valid32a === 1'b1 && i_valid32b === 1'b1 && i_valid32c === 1'b1 && i_valid32d === 1'b1) begin
            if (i_lane_c[10] === 1'b0) begin
              // Positive input a(a)
              s_stage2a_exp_a32c <= mempos128[i_lane_c[9:0]];
            end
            else begin
              // Negative input a(a)
              s_stage2a_exp_a32c <= memneg128[i_lane_c[9:0]];
            end

            if (i_lane_d[10] === 1'b0) begin
              // Positive input a(b)
              s_stage2a_exp_a32d <= mempos128[i_lane_d[9:0]];
            end
            else begin
              // Negative input a(b)
              s_stage2a_exp_a32d <= memneg128[i_lane_d[9:0]];
            end
          end // if (i_valid64a === 1'b1 && i_valid64b === 1'b1)

          // Also convert lane a and b's data
          s_stage2a_exp_a32a <= binary128_to_binary32_rne(s_stage1a_exp_a32a);
          s_stage2a_exp_a32b <= binary128_to_binary32_rne(s_stage1a_exp_a32b);
        end // FOUR_SP_MODE

        default: begin
          assert (0) else begin
              s_o_error[1] <= 1'b1;
            end
        end // default
      endcase
    end // if (s_S1_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

/**
 * Stage 2b block: Propogate valid bit and metadata bits
 * 
 */
logic             s_stage2b_valid128;
logic             s_stage2b_valid64a;
logic             s_stage2b_valid64b;
logic             s_stage2b_valid32a;
logic             s_stage2b_valid32b;
logic             s_stage2b_valid32c;
logic             s_stage2b_valid32d;
float_metadata_t  s_stage2b_metadata;
always_ff @( posedge i_clk ) begin : stage2b
  if (!i_rst_n) begin
    s_stage2b_valid128 <= '0;
    s_stage2b_valid64a <= '0;
    s_stage2b_valid64b <= '0;
    s_stage2b_valid32a <= '0;
    s_stage2b_valid32b <= '0;
    s_stage2b_valid32c <= '0;
    s_stage2b_valid32d <= '0;
    s_stage2b_metadata <= '0;
  end
  else begin
    // if (s_S2_en) begin
      s_stage2b_valid128 <= s_stage1b_valid128;
      s_stage2b_valid64a <= s_stage1b_valid64a;
      s_stage2b_valid64b <= s_stage1b_valid64b;
      s_stage2b_valid32a <= s_stage1b_valid32a;
      s_stage2b_valid32b <= s_stage1b_valid32b;
      s_stage2b_valid32c <= s_stage1b_valid32c;
      s_stage2b_valid32d <= s_stage1b_valid32d;
      s_stage2b_metadata <= s_stage1b_metadata;
    // end // if (s_S2_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

//=====================================================================================
// Final assignment
//=====================================================================================
assign o_metadata = s_stage2b_metadata;
assign o_exp_a128 = s_stage2a_exp_a128;
assign o_exp_a64a = s_stage2a_exp_a64a;
assign o_exp_a64b = s_stage2a_exp_a64b;
assign o_exp_a32a = s_stage2a_exp_a32a;
assign o_exp_a32b = s_stage2a_exp_a32b;
assign o_exp_a32c = binary128_to_binary32_rne(s_stage2a_exp_a32c);
assign o_exp_a32d = binary128_to_binary32_rne(s_stage2a_exp_a32d);
assign o_valid128 = s_stage2b_valid128;
assign o_valid64a = s_stage2b_valid64a;
assign o_valid64b = s_stage2b_valid64b;
assign o_valid32a = s_stage2b_valid32a;
assign o_valid32b = s_stage2b_valid32b;
assign o_valid32c = s_stage2b_valid32c;
assign o_valid32d = s_stage2b_valid32d;
assign o_sanity_identifier = MODULE_IDENTIFIER;
assign o_error = s_o_error;
assign o_debug = s_o_debug;


endmodule // module fixed128_64_32_partitiona #()
