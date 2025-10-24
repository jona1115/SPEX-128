
package binary128_pkg;

    typedef struct packed {
        logic           sign;
        logic [14:0]    exp;
        logic [112:0]   mantissa;
    } binary128_t;

endpackage : binary128_pkg
