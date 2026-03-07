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

`ifndef USE_DSP
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
  logic [RADIX2_DADDA_Z_NBITS-1 : 0]  z0;
  logic [RADIX2_DADDA_Z_NBITS-1 : 0]  z1;
  `include "helper/dadda_compressor_final_rows.svh"
  logic [RADIX2_DADDA_Z_NBITS-1 : 0]  s_S3_jedi_full;
  assign s_S3_jedi_full = z0 + z1;
`else
  // Radix 4
  logic [RADIX4_DADDA_Z_NBITS-1 : 0]  z0;
  logic [RADIX4_DADDA_Z_NBITS-1 : 0]  z1;
  `include "helper/radix4_dadda_compressor_final_rows.svh"
  logic [RADIX4_DADDA_Z_NBITS-1 : 0]  s_S3_jedi_full;
  assign s_S3_jedi_full = z0 + z1;
`endif
logic [EX_MAN_BITS_128*2-1 : 0]       s_S3_jedi;
logic                                 s_S3_valid;

always_ff @( posedge i_clk ) begin : stage3a
  if (!i_rst_n) begin
    s_S3_jedi     <= '0;
    s_S3_valid    <= '0;
  end
  else begin
    if (s_S3_en) begin
      s_S3_jedi   <= s_S3_jedi_full[EX_MAN_BITS_128*2-1:0];
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

`else
// ifdef USE_DSP:
localparam int W            = 113;
localparam int OUT_W        = 226;
localparam int A_PAYLOAD_W  = 26;
localparam int B_PAYLOAD_W  = 17;
localparam int A_DSP_W      = 27;
localparam int B_DSP_W      = 18;
localparam int PROD_W       = 45;
localparam int NA           = (W + A_PAYLOAD_W - 1) / A_PAYLOAD_W;    // 5
localparam int NB           = (W + B_PAYLOAD_W - 1) / B_PAYLOAD_W;    // 7
localparam int NPP          = NA * NB;                                // 35
localparam int A_PAD_W      = NA * A_PAYLOAD_W;                       // 130
localparam int B_PAD_W      = NB * B_PAYLOAD_W;                       // 119

localparam int DSP_MULT_STAGES = 3;
localparam int DSP_TREE_STAGES = 6;
// DSP branch latency is fixed to 9 cycles from i_valid_* to o_valid_jedi.
// In USE_DSP mode, upstream logic should treat intmult latency as DSP_TOTAL_LAT.
localparam int DSP_TOTAL_LAT   = DSP_MULT_STAGES + DSP_TREE_STAGES;

localparam int L0_N = NPP;
localparam int L1_N = (L0_N + 1) / 2;
localparam int L2_N = (L1_N + 1) / 2;
localparam int L3_N = (L2_N + 1) / 2;
localparam int L4_N = (L3_N + 1) / 2;
localparam int L5_N = (L4_N + 1) / 2;
localparam int L6_N = (L5_N + 1) / 2;

logic s_fire;
logic [DSP_TOTAL_LAT-1 : 0] s_pipe_valid;
logic [DSP_TOTAL_LAT-1 : 0] s_pipe_valid_next;

logic [A_PAD_W-1 : 0] s_a_pad;
logic [B_PAD_W-1 : 0] s_b_pad;

logic signed [A_DSP_W-1 : 0] s_a_tile_s1 [0 : NA-1];
logic signed [B_DSP_W-1 : 0] s_b_tile_s1 [0 : NB-1];
(* use_dsp = "yes" *) logic signed [PROD_W-1 : 0] s_pp_s2 [0 : NA-1][0 : NB-1];
logic signed [PROD_W-1 : 0] s_pp_s3 [0 : NA-1][0 : NB-1];

logic [OUT_W-1 : 0] s_term_l0 [0 : L0_N-1];
logic [OUT_W-1 : 0] s_term_l1 [0 : L1_N-1];
logic [OUT_W-1 : 0] s_term_l2 [0 : L2_N-1];
logic [OUT_W-1 : 0] s_term_l3 [0 : L3_N-1];
logic [OUT_W-1 : 0] s_term_l4 [0 : L4_N-1];
logic [OUT_W-1 : 0] s_term_l5 [0 : L5_N-1];
logic [OUT_W-1 : 0] s_term_l6 [0 : L6_N-1];

assign s_fire = i_valid_anikin & i_valid_force;
assign s_pipe_valid_next = {s_pipe_valid[DSP_TOTAL_LAT-2 : 0], s_fire};
assign s_a_pad = {{(A_PAD_W-W){1'b0}}, i_anikin};
assign s_b_pad = {{(B_PAD_W-W){1'b0}}, i_force};

always_ff @( posedge i_clk ) begin : sp_intmultiplier_dsp_valid_pipe
  if (!i_rst_n) begin
    s_pipe_valid <= '0;
  end
  else begin
    s_pipe_valid <= s_pipe_valid_next;
  end
end

// Stage 1: register tile inputs as non-negative signed 27x18 operands.
always_ff @( posedge i_clk ) begin : dsp_stage1_tiles
  if (!i_rst_n) begin
    s_a_tile_s1 <= '{default:'0};
    s_b_tile_s1 <= '{default:'0};
  end
  else begin
    for (int i = 0; i < NA; i++) begin
      s_a_tile_s1[i] <= $signed({1'b0, s_a_pad[i*A_PAYLOAD_W +: A_PAYLOAD_W]});
    end
    for (int j = 0; j < NB; j++) begin
      s_b_tile_s1[j] <= $signed({1'b0, s_b_pad[j*B_PAYLOAD_W +: B_PAYLOAD_W]});
    end
  end
end

// Stage 2: isolated signed partial-product multiplies to encourage DSP inference.
always_ff @( posedge i_clk ) begin : dsp_stage2_mult
  if (!i_rst_n) begin
    for (int i = 0; i < NA; i++) begin
      for (int j = 0; j < NB; j++) begin
        s_pp_s2[i][j] <= '0;
      end
    end
  end
  else begin
    for (int i = 0; i < NA; i++) begin
      for (int j = 0; j < NB; j++) begin
        s_pp_s2[i][j] <= s_a_tile_s1[i] * s_b_tile_s1[j];
      end
    end
  end
end

// Stage 3: register multiplier outputs again before wide accumulation.
always_ff @( posedge i_clk ) begin : dsp_stage3_mult_pipe
  if (!i_rst_n) begin
    for (int i = 0; i < NA; i++) begin
      for (int j = 0; j < NB; j++) begin
        s_pp_s3[i][j] <= '0;
      end
    end
  end
  else begin
    for (int i = 0; i < NA; i++) begin
      for (int j = 0; j < NB; j++) begin
        s_pp_s3[i][j] <= s_pp_s2[i][j];
      end
    end
  end
end

for (genvar i = 0; i < NA; i++) begin : dsp_term_i
  for (genvar j = 0; j < NB; j++) begin : dsp_term_j
    localparam int TERM_INDEX = (i * NB) + j;
    localparam int SHIFT      = (i * A_PAYLOAD_W) + (j * B_PAYLOAD_W);
    assign s_term_l0[TERM_INDEX] = ({{(OUT_W-PROD_W){1'b0}}, $unsigned(s_pp_s3[i][j])} << SHIFT);
  end
end

// Registered binary adder tree for 35 aligned OUT_W terms.
always_ff @( posedge i_clk ) begin : dsp_tree_l1
  if (!i_rst_n) begin
    s_term_l1 <= '{default:'0};
  end
  else begin
    for (int idx = 0; idx < L1_N; idx++) begin
      if ((2*idx + 1) < L0_N) begin
        s_term_l1[idx] <= s_term_l0[2*idx] + s_term_l0[2*idx + 1];
      end
      else begin
        s_term_l1[idx] <= s_term_l0[2*idx];
      end
    end
  end
end

always_ff @( posedge i_clk ) begin : dsp_tree_l2
  if (!i_rst_n) begin
    s_term_l2 <= '{default:'0};
  end
  else begin
    for (int idx = 0; idx < L2_N; idx++) begin
      if ((2*idx + 1) < L1_N) begin
        s_term_l2[idx] <= s_term_l1[2*idx] + s_term_l1[2*idx + 1];
      end
      else begin
        s_term_l2[idx] <= s_term_l1[2*idx];
      end
    end
  end
end

always_ff @( posedge i_clk ) begin : dsp_tree_l3
  if (!i_rst_n) begin
    s_term_l3 <= '{default:'0};
  end
  else begin
    for (int idx = 0; idx < L3_N; idx++) begin
      if ((2*idx + 1) < L2_N) begin
        s_term_l3[idx] <= s_term_l2[2*idx] + s_term_l2[2*idx + 1];
      end
      else begin
        s_term_l3[idx] <= s_term_l2[2*idx];
      end
    end
  end
end

always_ff @( posedge i_clk ) begin : dsp_tree_l4
  if (!i_rst_n) begin
    s_term_l4 <= '{default:'0};
  end
  else begin
    for (int idx = 0; idx < L4_N; idx++) begin
      if ((2*idx + 1) < L3_N) begin
        s_term_l4[idx] <= s_term_l3[2*idx] + s_term_l3[2*idx + 1];
      end
      else begin
        s_term_l4[idx] <= s_term_l3[2*idx];
      end
    end
  end
end

always_ff @( posedge i_clk ) begin : dsp_tree_l5
  if (!i_rst_n) begin
    s_term_l5 <= '{default:'0};
  end
  else begin
    for (int idx = 0; idx < L5_N; idx++) begin
      if ((2*idx + 1) < L4_N) begin
        s_term_l5[idx] <= s_term_l4[2*idx] + s_term_l4[2*idx + 1];
      end
      else begin
        s_term_l5[idx] <= s_term_l4[2*idx];
      end
    end
  end
end

always_ff @( posedge i_clk ) begin : dsp_tree_l6
  if (!i_rst_n) begin
    s_term_l6 <= '{default:'0};
  end
  else begin
    for (int idx = 0; idx < L6_N; idx++) begin
      if ((2*idx + 1) < L5_N) begin
        s_term_l6[idx] <= s_term_l5[2*idx] + s_term_l5[2*idx + 1];
      end
      else begin
        s_term_l6[idx] <= s_term_l5[2*idx];
      end
    end
  end
end

assign o_jedi = s_term_l6[0];
assign o_valid_jedi = s_pipe_valid[DSP_TOTAL_LAT-1];
assign o_sanity_identifier = MODULE_IDENTIFIER;
assign o_error = s_o_error;
assign o_debug = '0;

`endif // end of `ifndef USE_DSP

endmodule // module sp_intmultiplier #()
