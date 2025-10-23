
package float_metadata_pkg;

    import float_flag_pkg::*;
    import sp_mode_pkg::*;

    typedef struct packed {
        sp_mode_t       sp_mode;
        float_flag_t    float_type_a,
                        float_type_b,
                        float_type_c,
                        float_type_d;
    } float_metadata_t;

endpackage : float_metadata_pkg
