pragma circom 2.0.2;

include "./gates.circom";
include "./utils.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template LeftBinShift(n, shift) {
    assert(shift <= n);
    signal input in[n];
    signal input k;
    signal output out[n];
    for (var ii = 0; ii < shift; ii++) {
        out[ii] <== k;
    }
    for (var ii = shift; ii < n; ii++) {
        out[ii] <== in[ii - shift];
    }
}

template RightBinShift(n, shift) {
    assert(shift <= n);
    signal input in[n];
    signal input k;
    signal output out[n];
    for (var ii = 0; ii < shift; ii++) {
        out[n - ii - 1] <== k;
    }
    for (var ii = shift; ii < n; ii++) {
        var pos = n - ii - 1;
        out[pos] <== in[pos + shift];
    }
}

template BinShift(n, shift, right) {
    signal input in[n];
    signal input k;
    signal output out[n];
    component rightShift = RightBinShift(n, shift);
    component leftShift = LeftBinShift(n, shift);
    if (right == 1) {
        for (var ii = 0; ii < n; ii++) rightShift.in[ii] <== in[ii];
        rightShift.k <== k;
        for (var ii = 0; ii < n; ii++) out[ii] <== rightShift.out[ii];
    } else {
        for (var ii = 0; ii < n; ii++) leftShift.in[ii] <== in[ii];
        leftShift.k <== k;
        for (var ii = 0; ii < n; ii++) out[ii] <== leftShift.out[ii];
    }
}

template VariableBinShift32(n, right) {
    signal input in[n];
    signal input shift[5];
    signal input k;
    signal output out[n];
    component mux = MultiMux5(n);
    component shifters[32];
    for (var ii = 0; ii < 32; ii++) shifters[ii] = BinShift(n, ii, right);
    for (var ii = 0; ii < 32; ii++) {
        for (var jj = 0; jj < n; jj++) shifters[ii].in[jj] <== in[jj];
        shifters[ii].k <== k;
        for (var jj = 0; jj < n; jj++) mux.c[jj][ii] <== shifters[ii].out[jj];
    }
    for (var ii = 0; ii < 5; ii++) mux.s[ii] <== shift[ii];
    for (var ii = 0; ii < n; ii++) out[ii] <== mux.out[ii];
}

template LeftShift(shift) {
    signal input in;
    signal output out;
    out <== in * 2 ** shift;
}

template RightShift(n, shift) {
    signal input in;
    signal input k;
    signal output out;
    signal srl;
    signal rem;
    srl <-- in >> shift;
    rem <-- in - (srl << shift);
    component lt = LessThan(shift);
    lt.in[0] <== rem;
    lt.in[1] <== 2 ** shift;
    lt.out === 1;
    srl * 2 ** shift + rem === in;
    out <== srl + k * signExtension(n - shift, n);
}

template Shift(n, shift, right) {
    signal input in;
    signal input k;
    signal output out;
    component rightShifter = RightShift(n, shift);
    component leftShifter = LeftShift(shift);
    if (right == 1) {
        rightShifter.in <== in;
        rightShifter.k <== k;
        out <== rightShifter.out;
    } else {
        leftShifter.in <== in;
        out <== leftShifter.out;
    }
}

template VariableShift32(n, right) {
    signal input in;
    signal input shift[5];
    signal input k;
    signal output out;
    component mux = Mux5();
    component shifters[32];
    for (var ii = 0; ii < 32; ii++) shifters[ii] = Shift(n, ii, right);
    for (var ii = 0; ii < 32; ii++) {
        shifters[ii].in <== in;
        shifters[ii].k <== k;
        mux.c[ii] <== shifters[ii].out;
    }
    for (var ii = 0; ii < 5; ii++) mux.s[ii] <== shift[ii];
    out <== mux.out;
}
