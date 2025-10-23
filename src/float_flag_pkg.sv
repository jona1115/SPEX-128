package float_flag_pkg;

    typedef enum logic [1:0] {
        NORMAL      = 2'b00, // denormal use this too
        POS_INF     = 2'b01,
        NEG_INF     = 2'b10,
        NAN         = 2'b11
    } float_flag_t;

endpackage