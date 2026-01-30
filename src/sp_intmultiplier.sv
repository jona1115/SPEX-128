/********************************************************************
 * 
 * Originator   : Jonathan Tan
 * Date         : 1/27/2026
 * 
 ********************************************************************
 * 
 * Description:
 * This is a subword parallel int multiplier, intended to compute
 * the mantissa of sp_fpmultiplier. Performs the operation:
 *            int(anikin)*int(force)=int(jedi)
 * 
 ********************************************************************
 * 
 * Modification history:
 *    Ver   |  Who       |  Date	      |  Changes
 *  ------- + ---------- + ------------ + --------------------------
 *    1.00  |  Jonathan  |  1/27/2026   |  Birth of this file
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

module sp_intmultiplier #(
  parameter int NUM_BITS_128      = 128,
  parameter int NUM_BITS_64       = 64,
  parameter int NUM_BITS_32       = 32,

  parameter int EX_MAN_BITS_128   = 113,    // EXtended MANtissa number of BITS for fp128
  parameter int EX_MAN_BITS_64    = 53,     // EXtended MANtissa number of BITS for fp128
  parameter int EX_MAN_BITS_32    = 23,     // EXtended MANtissa number of BITS for fp128

  // Multiplier pipeline latency (cycles from valid in to valid out)
  parameter int MUL_LATENCY       = 1,

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

  // Data
  input   logic [EX_MAN_BITS_128-1:0]             i_anikin,
  input   logic [EX_MAN_BITS_128-1:0]             i_force,
  output  logic [EX_MAN_BITS_128*2-1:0]           o_jedi,

  // Upstream Handshake
  input   logic                                   i_valid_anikin,
  input   logic                                   i_valid_force,

  // Downstream Handshake
  output  logic                                   o_valid_jedi,

  // Module identifier
  output  logic [3:0]                             o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1:0]       o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1:0]       o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic [ERROR_SIGNAL_NUM_BITS-1:0]       s_o_error;

//=====================================================================================
// Module body
//=====================================================================================

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
      if (i_valid_anikin === 1'b1 && i_valid_force=== 1'b1) begin // "All or nothing"
        s_S1_en = 1'b1;
        s_next_state = S2;
      end
    end
    S2: begin
      s_S2_en = 1'b1;
      s_next_state = S3;
    end
    S3: begin
      s_S3_en = 1'b1;
      s_next_state = S4;
    end
    S4: begin
      s_S4_en = 1'b1;
      s_next_state = S0_IDLE;
    end
    S5: begin
      s_S5_en = 1'b1;
      s_next_state = S0_IDLE;
    end
    S6: begin
      s_S6_en = 1'b1;
      s_next_state = S0_IDLE;
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
logic [EX_MAN_BITS_128-1:0] pp [0:EX_MAN_BITS_128-1]; // A 2D array of partial products
genvar col, row;
generate
  for (row = 0; row < EX_MAN_BITS_128; row = row + 1) begin : pp_row_generator
    for (col = 0; col < EX_MAN_BITS_128; col = col + 1) begin : pp_col_generator
      assign pp[row][col] = i_anikin[col] & i_force[row];
    end // pp_col_generator
  end // pp_row_generator
endgenerate

logic s_S1_valid;
logic [EX_MAN_BITS_128-1:0] s_S1_pp [0:EX_MAN_BITS_128-1];
always_ff @( posedge i_clk ) begin : stage1a
  if (!i_rst_n) begin
    s_S1_valid  <= '0;
    s_S1_pp     <= '{default:'0};
  end
  else begin
    if (s_S1_en) begin
      s_S1_valid <= '1;

      s_S1_pp <= pp;
    end // if (s_S1_en)
    else begin
      s_S1_valid <= '0;
    end // else begin
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 2
//=====================================================================================
always_ff @( posedge i_clk ) begin : stage2a
  if (!i_rst_n) begin
  end
  else begin
    if (s_S2_en) begin
    end // if (s_S2_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 3
//=====================================================================================
always_ff @( posedge i_clk ) begin : stage3a
  if (!i_rst_n) begin
  end
  else begin
    if (s_S3_en) begin
    end // if (s_S3_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 4
//=====================================================================================
always_ff @( posedge i_clk ) begin : stage4a
  if (!i_rst_n) begin
  end
  else begin
    if (s_S4_en) begin
    end // if (s_S4_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_jedi = '0; // todo
assign o_valid_jedi = '0; // todo
assign o_sanity_identifier = MODULE_IDENTIFIER;
assign o_error = s_o_error;
assign o_debug = '0;

endmodule // module sp_fpmultiplier #()
