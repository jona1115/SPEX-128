/**
 * 
 * Specification:
 * 0. If i_ctrl[1:0] is 00:     1 x binary128 aka single_mode
 *    elif i_ctrl[1:0] is 01:   2 x binary64  aka two_sp_mode (sp == subword parallel)
 *    elif i_ctrl[1:0] is 10:   4 x binary32  aka four_sp_mode
 * 1. Do special type check and output for o_float_type_n accordingly.
 *    single_mode will only use o_metadata.float_type_a, and set NA to the b, c, d o_metadata.float_type_n
 *    two_sp_mode will only use o_metadata.float_type_a, and b, and set NA to the c, d o_metadata.float_type_n
 *    four_sp_mode will use all o_metadata.float_type_a, b, c, d
 * 2. We first calculate the "offset" of the exponent component
 *    if single_mode:
 *        shift_amount_a = i_float[126:112] - 16383
 *    elif two_sp_mode:
 *        shift_amount_a = i_float[126:116] - 1023
 *        shift_amount_b = i_float[62:52] - 1023
 *    elif four_sp_mode:
 *        shift_amount_a = i_float[126:119] - 127
 *        shift_amount_b = i_float[94:87] - 127
 *        shift_amount_c = i_float[62:55] - 127
 *        shift_amount_d = i_float[30:23] - 127
 * 
 */

// `include "float_metadata_pkg.svh"

import float_flag_pkg::*;
import sp_mode_pkg::*;
import float_metadata_pkg::*;
import binary128_pkg::*;
import binary64_pkg::*;
import binary32_pkg::*;

module float_to_fixed #() (
    input   logic               i_clk,
    input   logic [127:0]       i_float,
    input   logic [3:0]         i_ctrl,
    output  logic [127:0]       o_fixed,
    output  float_metadata_t    o_metadata
);

// Signal definitions
sp_mode_t s_current_sp;
binary128_t s_binary128;

// Determine what sp (subword parallel) mode we are in based on input control
// signals.
// Using assign will make it "continuous assignment", so it is eval-ed before 
// always_comb blocks, usually we use assign for decoders. - ChatGPT
assign s_current_sp =
    (i_ctrl[1:0] == 2'b00) ? SINGLE_MODE  :
    (i_ctrl[1:0] == 2'b01) ? TWO_SP_MODE  :
    (i_ctrl[1:0] == 2'b10) ? FOUR_SP_MODE : INVALID_SP_MODE;

assign s_binary128.sign = i_float[127];
assign s_binary128.exp = i_float[126:112];
assign s_binary128.mantissa = i_float[111:0];


// Determine what the output float types are based on s_current_sp
always_comb begin : float_type_determiner
    case (s_current_sp)
        SINGLE_MODE: begin
            o_metadata.float_type_a = NORMAL;
            o_metadata.float_type_b = NA;
            o_metadata.float_type_c = NA;
            o_metadata.float_type_d = NA;
        end

        TWO_SP_MODE: begin
            o_metadata.float_type_a = NA; // TODO
            o_metadata.float_type_b = NA;
            o_metadata.float_type_c = NA;
            o_metadata.float_type_d = NA;
        end

        FOUR_SP_MODE: begin
            o_metadata.float_type_a = NA; // TODO
            o_metadata.float_type_b = NA;
            o_metadata.float_type_c = NA;
            o_metadata.float_type_d = NA;
        end

        INVALID_SP_MODE: begin
            o_metadata.float_type_a = NA; // TODO
            o_metadata.float_type_b = NA;
            o_metadata.float_type_c = NA;
            o_metadata.float_type_d = NA;
        end

        default: begin
            o_metadata.float_type_a = NA;
            o_metadata.float_type_b = NA;
            o_metadata.float_type_c = NA;
            o_metadata.float_type_d = NA;
        end
    endcase
end

always_comb begin
    o_metadata.sp_mode = s_current_sp;

    // Passthrough (temp)
    o_fixed = i_float;
end

endmodule