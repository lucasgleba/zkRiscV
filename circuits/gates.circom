pragma circom 2.0.2;

include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/mux4.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/binsum.circom";
include "../node_modules/circomlib/circuits/binsub.circom";

template MultiMux5(n) {
    signal input in[n][32];
    signal input s[5];
    signal output out[n][32];
    component mux4s[2];
    mux4s[0] = MultiMux4(n);
    mux4s[1] = MultiMux4(n);
    component mux1 = MultiMux1(n);
    for (var ii = 0; ii < 2; ii++) {
        for (var kk = 0; kk < n; kk++) {
            for (var jj = 0; jj < 16; jj++) {
                mux4s[ii].c[kk][jj] <== in[kk][ii * 16 + jj];
            }
            mux1.c[kk][ii] <== mux4s.out[kk];
        }
        for (var jj = 0; jj < 4; jj++) {
            mux4s[ii].s[jj] <== s[jj];
        }
    }
    for (var kk = 0; kk < n; kk++) {
        out[kk] <== mux1.out[kk];
    }
}

template LeftShifter(bits) {
    signal input in[bits];
    signal input k;
    signal output out[bits];
    out[0] <== k;
    for (var ii = 1; ii < bits; ii++) {
        out[ii] <== in[ii - 1];
    }
}

template RightShifter(bits) {
    signal input in[bits];
    signal input k;
    signal output out[bits];
    out[bits - 1] <== k;
    for (var ii = 0; ii < bits - 1; ii++) {
        out[ii] <== in[ii + 1];
    }
}

template Shifter32(bits, right) {
    assert(bits == 32);
    signal input in[bits];
    signal input shift[5];
    signal input k;
    signal output out[bits];
    component shifters[bits - 1];
    component mux = MultiMux5(bits);
    for (var ii = 0; ii < bits; ii++) {
        mux.c[ii][0] <== in[ii];
    }
    for (var ii = 0; ii < bits - 1; ii++) {
        if (right == 1) {
            shifters[ii] = RightShifter(bits);
            // for (var jj = 0; jj < ii + 1; jj++) {
            //     mux.c[jj][ii] <== k;
            // }
            // for (var jj = ii + 1; jj < bits; jj++) {
            //     mux.c[jj][ii] <== mux.c[jj + 1][ii - 1];
            // }
        } else {
            shifters[ii] = LeftShifter(bits);
        }
        var shifter = shifters[ii];
        shifter.k <== k;
        for (var jj = 0; jj < bits; jj++) {
            shifter.in[jj] <== mux[ii].c[jj];
            mux[ii + 1].c[jj] <== shifter.out[jj];
        }
    }
    for (var ii = 0; ii < 5; ii++) {
        mux.s[ii] <== shift[ii];
    }
    for (var ii = 0; ii < bits; ii++) {
        out[ii] <== mux.out[ii];
    }
}
