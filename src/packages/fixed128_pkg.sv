
package fixed128_pkg;

    typedef struct packed {
        logic           sign_portion;
        logic [9:0]     int_portion;
        logic [116:0]   frac_portion;
    } fixed128_t;

endpackage : fixed128_pkg
