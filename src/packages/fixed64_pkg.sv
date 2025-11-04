
package fixed64_pkg;

    typedef struct packed {
        logic           sign_portion;
        logic [10:0]     int_portion;
        logic [51:0]   frac_portion;
    } fixed64_t;

endpackage : fixed64_pkg
