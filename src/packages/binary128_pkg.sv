
package binary128_pkg;

    typedef struct packed {
        logic           sign;
        logic [14:0]    exp;
        logic [111:0]   mantissa;
    } binary128_t;

endpackage : binary128_pkg
