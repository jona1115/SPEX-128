/**
 * 
 * Specification:
 * 0. If i_ctrl[1:0] is 00:     1 x binary128 aka single_mode
 *    elif i_ctrl[1:0] is 01:   2 x binary64  aka two_sp_mode (sp == subword parallel)
 *    elif i_ctrl[1:0] is 10:   4 x binary32  aka four_sp_mode
 * 1. Do special type check and output for o_float_type_n accordingly.
 *    single_mode will only use o_float_type_a, and set NA to the b, c, d o_float_type_n
 *    two_sp_mode will only use o_float_type_a, and b, and set NA to the c, d o_float_type_n
 *    four_sp_mode will use all o_float_type_a, b, c, d
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

module float_to_fixed #() (
    input   logic               i_clk,
    input   logic [127:0]       i_float,
    input   logic [3:0]         i_ctrl,
    output  logic [127:0]       o_fixed,
    output  float_metadata_t    o_metadata
);

// Signal definitions
sp_mode_t s_current_sp;

always_comb begin : sp_mode_determiner
    case (i_ctrl[1:0])
        2'b00   : s_current_sp = SINGLE_MODE;
        2'b01   : s_current_sp = TWO_SP_MODE;
        2'b10   : s_current_sp = FOUR_SP_MODE;
        2'b11   : s_current_sp = INVALID_SP_MODE;
        default : s_current_sp = INVALID_SP_MODE;
    endcase
end


always_comb begin
    // s_current_sp = sp_mode_t'(i_ctrl[1:0]);
    // s_current_sp = sp_mode_t'(2'b10);
    o_metadata.sp_mode = s_current_sp;

    // o_metadata.float_type_a = float_flag_t'(i_ctrl[1:0]); //temp

    // Passthrough (temp)
    o_fixed = i_float;
end

endmodule