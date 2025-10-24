
package binary64_pkg;

    typedef struct packed {
        logic           sign;
        logic [10:0]    exp;
        logic [51:0]   mantissa;
    } binary64_t;

endpackage : binary64_pkg
