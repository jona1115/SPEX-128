// Some unbiasing helper functions and typedefs

package unbiasing_pkg;

  typedef logic signed [15:0] sh_t; // we use 16 bits so we can properly represent -ve shift amount 
                                    // for single_mode

  function automatic sh_t unbias_q128 (input logic [14:0] exp);
    return (exp == 15'd0) ? sh_t'(-16'sd16382) // IEEE-754: for subnormal (exp==0), unbiased exponent is 1 - bias
                          : sh_t'($signed({1'b0, exp}) - 16'sd16383);
  endfunction

  function automatic sh_t unbias_q64  (input logic [10:0] exp);
    return (exp == 11'd0) ? sh_t'(-16'sd1022)
                          : sh_t'($signed({5'b0, exp}) - 16'sd1023);
  endfunction

  function automatic sh_t unbias_q32  (input logic  [7:0] exp);
    return (exp ==  8'd0) ? sh_t'( -16'sd126)
                          : sh_t'($signed({8'b0, exp}) - 16'sd127);
  endfunction

endpackage
