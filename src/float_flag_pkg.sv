package float_flag_pkg;

    typedef enum logic [2:0] {
        NORMAL      = 3'b000, // denormal use this too
        ZERO        = 3'b001,
        POS_INF     = 3'b010,
        NEG_INF     = 3'b011,
        NAN         = 3'b100,
        NA          = 3'b111
    } float_flag_t;

endpackage