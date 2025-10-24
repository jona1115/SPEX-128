
package binary32_pkg;

    typedef struct packed {
        logic           sign;
        logic [7:0]    exp;
        logic [22:0]   mantissa;
    } binary32_t;

endpackage : binary32_pkg
