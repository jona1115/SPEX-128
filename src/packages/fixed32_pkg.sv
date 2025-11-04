
package fixed32_pkg;

    typedef struct packed {
        logic           sign_portion;
        logic [9:0]     int_portion;
        logic [20:0]   frac_portion;
    } fixed32_t;

endpackage : fixed32_pkg
