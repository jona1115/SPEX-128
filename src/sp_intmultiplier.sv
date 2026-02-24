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

module ha (
  input  logic i_a,
  input  logic i_b,
  output logic o_sum,
  output logic o_carry
);
  assign o_sum   = i_a ^ i_b;
  assign o_carry = i_a & i_b;
endmodule

module fa (
  input  logic i_a,
  input  logic i_b,
  input  logic i_cin,
  output logic o_sum,
  output logic o_carry
);
  assign o_sum   = i_a ^ i_b ^ i_cin;
  assign o_carry = (i_a & i_b) | (i_a & i_cin) | (i_b & i_cin);
endmodule

module sp_intmultiplier #(
  parameter int NUM_BITS_128          = 128,
  parameter int NUM_BITS_64           = 64,
  parameter int NUM_BITS_32           = 32,

  parameter int EX_MAN_BITS_128       = 113,    // EXtended MANtissa number of BITS for fp128
  parameter int EX_MAN_BITS_64        = 53,     // EXtended MANtissa number of BITS for fp64
  parameter int EX_MAN_BITS_32        = 23,     // EXtended MANtissa number of BITS for fp32

  // Radix-4 PP matrix is widened by 2 columns so each row can encode 3X in parallel.
  parameter int RADIX4_PP_NBITS       = EX_MAN_BITS_128 + 2,
  parameter int RADIX4_ROWS           = (RADIX4_PP_NBITS + 1) / 2,
  parameter int RADIX4_DADDA_SC_NBITS = 6328,
  parameter int RADIX4_DADDA_Z_NBITS  = 230,
  parameter int RADIX2_DADDA_Z_NBITS  = 226,

  // Multiplier pipeline latency (cycles from valid in to valid out)
  parameter int MODULE_LATENCY        = 3, // This has to match sp_fpmultiplier's INTMUL_LATENCY

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
  input   logic [EX_MAN_BITS_128-1 : 0]           i_anikin,
  input   logic [EX_MAN_BITS_128-1 : 0]           i_force,
  output  logic [EX_MAN_BITS_128*2-1 : 0]         o_jedi,

  // Upstream Handshake
  input   logic                                   i_valid_anikin,
  input   logic                                   i_valid_force,

  // Downstream Handshake
  output  logic                                   o_valid_jedi,

  // Module identifier
  output  logic [3 : 0]                           o_sanity_identifier,

  // Error and debug signals
  output  logic [ERROR_SIGNAL_NUM_BITS-1 : 0]     o_error,
  output  logic [DEBUG_SIGNAL_NUM_BITS-1 : 0]     o_debug
);

//=====================================================================================
// Signal definitions
//=====================================================================================
logic [ERROR_SIGNAL_NUM_BITS-1:0]       s_o_error;

//=====================================================================================
// Module body
//=====================================================================================

/**
 * 
 * State transition control
 * 
 */
localparam int PIPE_DEPTH = MODULE_LATENCY;
logic [PIPE_DEPTH-1 : 0]  s_pipe_valid;
logic [PIPE_DEPTH-1 : 0]  s_pipe_valid_next;

localparam int S2_OFFSET = 0;
localparam int S3_OFFSET = S2_OFFSET + 1;
// localparam int S4_OFFSET = S3_OFFSET + 1;

// Decode the input valid signals
logic s_fire;
assign s_fire = i_valid_anikin & i_valid_force;

assign s_pipe_valid_next = {s_pipe_valid[PIPE_DEPTH-2 : 0], s_fire};

logic s_S1_en, s_S2_en, s_S3_en, s_S4_en;
assign s_S1_en = s_fire;
assign s_S2_en = s_pipe_valid[S2_OFFSET];
assign s_S3_en = s_pipe_valid[S3_OFFSET];
// assign s_S4_en = s_pipe_valid[S4_OFFSET];

/**
 * FSM
 */
always_ff @( posedge i_clk ) begin : sp_intmultiplier_FSM
  if (!i_rst_n) begin
    s_pipe_valid <= '0;
  end
  else begin
    s_pipe_valid <= s_pipe_valid_next;
  end
end


//=====================================================================================
// Stage 1
//=====================================================================================
`ifndef USE_RADIX4_RECODING
  // Vanila
  logic [EX_MAN_BITS_128-1 : 0]     s_pp    [0 : EX_MAN_BITS_128-1]; // A 2D array of partial products
  `include "helper/pen_and_paper_pp_generator.svh"
  logic [EX_MAN_BITS_128-1 : 0]     s_S1_pp [0 : EX_MAN_BITS_128-1];
`else
  // Radix 4
  logic [RADIX4_PP_NBITS-1 : 0]     s_pp    [0 : RADIX4_ROWS-1];
  `include "helper/radix4_pp_generator.svh"
  logic [RADIX4_PP_NBITS-1 : 0]     s_S1_pp [0 : RADIX4_ROWS-1];
`endif

logic s_S1_valid;
int debug_col, debug_row, debug_num_rows, debug_num_cols;
always_ff @( posedge i_clk ) begin : stage1a
  if (!i_rst_n) begin
    s_S1_valid  <= '0;
    s_S1_pp     <= '{default:'0};
  end
  else begin
    if (s_S1_en) begin
      s_S1_valid <= '1;
      s_S1_pp <= s_pp;

`ifdef EN_DEBUG_PRINT
  `ifndef USE_RADIX4_RECODING
      debug_num_rows = EX_MAN_BITS_128;
      debug_num_cols = EX_MAN_BITS_128;
  `else
      debug_num_rows = RADIX4_ROWS;
      debug_num_cols = RADIX4_PP_NBITS;
  `endif
      for (debug_row = 0; debug_row < debug_num_rows; debug_row = debug_row + 1) begin : pp_row_debug_loop
        for (debug_col = debug_num_cols-1; debug_col >= 0; debug_col = debug_col - 1) begin : pp_col_debug_loop
          $write("%x", s_pp[debug_row][debug_col]);
        end // pp_col_debug_loop
        $display("");
      end // pp_row_debug_loop
`endif
    end // if (s_S1_en)
    else begin
      s_S1_valid <= '0;
    end // else begin
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

//=====================================================================================
// Stage 2
//=====================================================================================
`ifndef USE_RADIX4_RECODING
  // Vanila
  logic [12431 : 0] S;
  logic [12431 : 0] C;
  `include "helper/dadda_compressor_reduce_tree.svh"
  logic [12431 : 0] s_S2_S;
  logic [12431 : 0] s_S2_C;
`else
  // Radix 4
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] S;
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] C;
  `include "helper/radix4_dadda_compressor_reduce_tree.svh"
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] s_S2_S;
  logic [RADIX4_DADDA_SC_NBITS-1 : 0] s_S2_C;
`endif
always_ff @( posedge i_clk ) begin : stage2a
  if (!i_rst_n) begin
    s_S2_S <= '0;
    s_S2_C <= '0;
  end
  else begin
    if (s_S2_en) begin
      s_S2_S <= S;
      s_S2_C <= C;
    end // if (s_S2_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

`ifndef USE_RADIX4_RECODING
  logic [EX_MAN_BITS_128-1:0]   s_S2_pp [0:EX_MAN_BITS_128-1];
`else
  logic [RADIX4_PP_NBITS-1 : 0] s_S2_pp [0 : RADIX4_ROWS-1];
`endif
always_ff @( posedge i_clk ) begin : stage2b_signal_passthrough
  if (!i_rst_n) begin
    s_S2_pp <= '{default:'0};
  end
  else begin
    if (s_S2_en) begin
      s_S2_pp <= s_S1_pp;
    end // if (s_S2_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

//=====================================================================================
// Stage 3
//=====================================================================================
`ifndef USE_RADIX4_RECODING
  // Vanila
  logic [RADIX2_DADDA_Z_NBITS-1 : 0] z0;
  logic [RADIX2_DADDA_Z_NBITS-1 : 0] z1;
  `include "helper/dadda_compressor_final_rows.svh"
  logic [RADIX2_DADDA_Z_NBITS-1 : 0] s_S3_jedi_full;
  assign s_S3_jedi_full = z0 + z1;
`else
  // Radix 4
  logic [RADIX4_DADDA_Z_NBITS-1 : 0] z0;
  logic [RADIX4_DADDA_Z_NBITS-1 : 0] z1;
  `include "helper/radix4_dadda_compressor_final_rows.svh"
  logic [RADIX4_DADDA_Z_NBITS-1 : 0] s_S3_jedi_full;
  assign s_S3_jedi_full = z0 + z1;
`endif
logic [EX_MAN_BITS_128*2-1:0] s_S3_jedi;
logic                         s_S3_valid;

always_ff @( posedge i_clk ) begin : stage3a
  if (!i_rst_n) begin
    s_S3_jedi     <= '0;
    s_S3_valid    <= '0;
  end
  else begin
    if (s_S3_en) begin
  `ifndef USE_DSP
      s_S3_jedi   <= s_S3_jedi_full[EX_MAN_BITS_128*2-1:0];
  `else
      s_S3_jedi   <= i_anikin * i_force; // Infer DSP use, as mentioned in config.svh, this should NOT be used in production code, will cause wrong result
  `endif
      s_S3_valid  <= 1'b1;
    end // if (s_S3_en)
    else begin
      s_S3_valid  <= '0;
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_jedi = s_S3_jedi;
assign o_valid_jedi = s_S3_valid;
assign o_sanity_identifier = MODULE_IDENTIFIER;
assign o_error = s_o_error;
assign o_debug = '0;

endmodule // module sp_fpmultiplier #()
