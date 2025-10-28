
package binary128_pkg;

    // The layout *should* be like this:
    // [ MSB ................................................... LSB ]
    // | sign | exp[14] ... exp[0] | mantissa[111] ... mantissa[0] |

    typedef struct packed {
        logic           sign;
        logic [14:0]    exp;
        logic [111:0]   mantissa;
    } binary128_t;

endpackage : binary128_pkg
