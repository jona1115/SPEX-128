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

  // Radix-4 recoding uses ceil(N/2) partial-product rows.
  parameter int RADIX4_ROWS           = (EX_MAN_BITS_128 + 1) / 2,

  // Multiplier pipeline latency (cycles from valid in to valid out)
  parameter int MODULE_LATENCY        = 4,

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
  output  logic [DEBUG_SIGNAL_NUM_BITS-1 : 0]     o_debug,

  output  logic [EX_MAN_BITS_128-1 : 0]           ds_S1_pp [0 : RADIX4_ROWS-1],
  output  logic [6104 : 0]                        ds_S2_S,
  output  logic [6104 : 0]                        ds_S2_C,
  output  logic [225 : 0]                         ds_S3_z0,
  output  logic [225 : 0]                         ds_S3_z1,
  output  logic [EX_MAN_BITS_128*2-1:0]           ds_S4_jedi,
  output  logic                                   ds_S4_valid
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

localparam int S1_OFFSET = 0;
localparam int S2_OFFSET = S1_OFFSET + 1;
localparam int S3_OFFSET = S2_OFFSET + 1;
localparam int S4_OFFSET = S3_OFFSET + 1;

// Decode the input valid signals
logic s_fire;
assign s_fire = i_valid_anikin & i_valid_force;

assign s_pipe_valid_next = {s_pipe_valid[PIPE_DEPTH-2 : 0], s_fire};

logic s_S1_en, s_S2_en, s_S3_en, s_S4_en;
assign s_S1_en = s_fire;
assign s_S2_en = s_pipe_valid[S1_OFFSET]; // todo this naming scheme still doesnt make sense to me
assign s_S3_en = s_pipe_valid[S2_OFFSET];
assign s_S4_en = s_pipe_valid[S3_OFFSET];

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
  logic [EX_MAN_BITS_128-1 : 0]     s_pp    [0 : RADIX4_ROWS-1];  // Compressor expects EX_MAN_BITS_128 columns (0..EX_MAN_BITS_128-1)
  logic [1:0]                       s_pp_carry_out;               // Carry bits beyond EX_MAN_BITS_128-1 after folding (bit[0] -> o_jedi[EX_MAN_BITS_128*2-1])
  `include "helper/radix4_pp_generator.svh"
  logic [EX_MAN_BITS_128-1 : 0]     s_S1_pp [0 : RADIX4_ROWS-1];
  logic [1:0]                       s_S1_pp_carry_out;
`endif

logic s_S1_valid;
int debug_col, debug_row, debug_num_rows;
always_ff @( posedge i_clk ) begin : stage1a
  if (!i_rst_n) begin
    s_S1_valid  <= '0;
    s_S1_pp     <= '{default:'0};
`ifdef USE_RADIX4_RECODING
    s_S1_pp_carry_out <= '0;
`endif
  end
  else begin
    if (s_S1_en) begin
      s_S1_valid <= '1;
      s_S1_pp <= s_pp;
`ifdef USE_RADIX4_RECODING
      s_S1_pp_carry_out <= s_pp_carry_out;
`endif

`ifdef EN_DEBUG_PRINT
  `ifndef USE_RADIX4_RECODING
      debug_num_rows = EX_MAN_BITS_128;
  `else
      debug_num_rows = RADIX4_ROWS;
  `endif
      for (debug_row = 0; debug_row < debug_num_rows; debug_row = debug_row + 1) begin : pp_row_debug_loop
        for (debug_col = EX_MAN_BITS_128-1; debug_col >= 0; debug_col = debug_col - 1) begin : pp_col_debug_loop
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
  logic [6104 : 0] S;
  logic [6104 : 0] C;
  `include "helper/radix4_dadda_compressor_reduce_tree.svh"
  logic [6104 : 0] s_S2_S;
  logic [6104 : 0] s_S2_C;
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
  logic [EX_MAN_BITS_128-1 : 0] s_S2_pp [0 : RADIX4_ROWS-1];
  logic [1:0]                   s_S2_pp_carry_out;
`endif
always_ff @( posedge i_clk ) begin : stage2b_signal_passthrough
  if (!i_rst_n) begin
    s_S2_pp <= '{default:'0};
`ifdef USE_RADIX4_RECODING
    s_S2_pp_carry_out <= '0;
`endif
  end
  else begin
    if (s_S2_en) begin
      s_S2_pp <= s_S1_pp;
`ifdef USE_RADIX4_RECODING
      s_S2_pp_carry_out <= s_S1_pp_carry_out;
`endif
    end // if (s_S2_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )

//=====================================================================================
// Stage 3
//=====================================================================================
logic [225 : 0] z0;
logic [225 : 0] z1;
`ifndef USE_RADIX4_RECODING
  // Vanila
  `include "helper/dadda_compressor_final_rows.svh"
`else
  // Radix 4
  `include "helper/radix4_dadda_compressor_final_rows.svh"
`endif
logic [225 : 0] s_S3_z0;
logic [225 : 0] s_S3_z1;
logic [1:0]                 s_S3_pp_carry_out;
always_ff @( posedge i_clk ) begin : stage3a
  if (!i_rst_n) begin
    s_S3_z0 <= '0;
    s_S3_z1 <= '0;
    s_S3_pp_carry_out <= '0;
  end
  else begin
    if (s_S3_en) begin
      s_S3_z0 <= z0;
      s_S3_z1 <= z1;
`ifdef USE_RADIX4_RECODING
      s_S3_pp_carry_out <= s_S2_pp_carry_out;
`endif
    end // if (s_S3_en)
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Stage 4
//=====================================================================================
logic [EX_MAN_BITS_128*2-1:0] s_S4_jedi;
logic                         s_S4_valid;
always_ff @( posedge i_clk ) begin : stage4a
  if (!i_rst_n) begin
    s_S4_jedi   <= '0;
    s_S4_valid  <= '0;
  end
  else begin
    if (s_S4_en) begin
`ifndef USE_RADIX4_RECODING
      s_S4_jedi   <= s_S3_z0 + s_S3_z1;
`else
      // radix4_dadda_compressor_{reduce_tree,final_rows} compresses only bits [EX_MAN_BITS_128-1:0] per partial-product row.
      // `radix4_pp_generator.svh` folds any overflow into higher rows and returns the final carry bit for o_jedi[EX_MAN_BITS_128*2-1].
      s_S4_jedi   <= s_S3_z0 + s_S3_z1 + {s_S3_pp_carry_out[0], {(EX_MAN_BITS_128*2-1){1'b0}}};
`endif
      s_S4_valid  <= '1;
    end // if (s_S4_en)
    else begin
      s_S4_valid  <= '0;
    end
  end // !i_rst_n else begin
end // always_ff @( posedge i_clk )


//=====================================================================================
// Final assignment
//=====================================================================================
assign o_jedi = s_S4_jedi;
assign o_valid_jedi = s_S4_valid;
assign o_sanity_identifier = MODULE_IDENTIFIER;
assign o_error = s_o_error;
assign o_debug = '0;

// Debug signals
`ifdef USE_RADIX4_RECODING
assign ds_S1_pp = s_S1_pp;
assign ds_S2_S = s_S2_S;
assign ds_S2_C = s_S2_C;
assign ds_S3_z0 = s_S3_z0;
assign ds_S3_z1 = s_S3_z1;
assign ds_S4_jedi = s_S4_jedi;
assign ds_S4_valid = s_S4_valid;
`endif

endmodule // module sp_fpmultiplier #()
