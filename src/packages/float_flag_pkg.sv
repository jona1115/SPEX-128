package float_flag_pkg;

  typedef enum logic [3:0] {
    NORMAL          = 4'b0000,
    ZERO            = 4'b0001,
    POS_INF         = 4'b0010,
    NEG_INF         = 4'b0011,
    NAN             = 4'b0100,
    POS_DENORMAL    = 4'b0101,
    NEG_DENORMAL    = 4'b0110,
    NA              = 4'b1111
  } float_flag_t;

endpackage