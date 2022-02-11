pragma circom 2.0.2;

include "./shifter.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";

template Num2Bits_soft(n) {
    signal input in;
    signal output out[n];
    component shift = RightShift(n, n);
    shift.in <== in;
    shift.k <== 0;
    component n2b = Num2Bits(n);
    n2b.in <== shift.rem;
    for (var ii = 0; ii < n; ii++) out[ii] <== n2b.out[ii];
}
