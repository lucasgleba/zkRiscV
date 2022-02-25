pragma circom 2.0.2;

include "./shifter.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";

// not used
template Num2Bits_soft(n) {
    signal input in;
    signal output out[n];
    // TODO: how to make this more efficient [?]
    component shift = RightShift(254, n);
    shift.in <== in;
    shift.k <== 0;
    component n2b = Num2Bits(n);
    n2b.in <== shift.rem;
    for (var ii = 0; ii < n; ii++) out[ii] <== n2b.out[ii];
}

template AssertInBitRange(n) {
    signal input in;
    component n2b = Num2Bits(n);
    n2b.in <== in;
}

template MultiAssertInBitRange(n, bits) {
    signal input in[n];
    component assertInBitRange[n];
    for (var ii = 0; ii < n; ii++) assertInBitRange[ii] = AssertInBitRange(bits);
    for (var ii = 0; ii < n; ii++) assertInBitRange[ii].in <== in[ii];
}
