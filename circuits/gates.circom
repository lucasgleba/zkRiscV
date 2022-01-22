pragma circom 2.0.2;

include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/mux4.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/binsum.circom";
include "../node_modules/circomlib/circuits/binsub.circom";
include "../node_modules/circomlib/circuits/gates.circom";

template MultiMux5(n) {
    signal input c[n][32];
    signal input s[5];
    signal output out[n];
    component mux4a = MultiMux4(n);
    component mux4b = MultiMux4(n);
    for (var ii = 0; ii < 16; ii++) {
        for (var jj = 0; jj < n; jj++) {
            mux4a.c[jj][ii] <== c[jj][ii];
            mux4b.c[jj][ii] <== c[jj][16 + ii];
        }
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

template RightShifter32(bits) {
    assert(bits == 32);
    signal input in[2][bits];
    signal input k;
    signal output out[bits];
    component mux = MultiMux5(bits);
    for (var ii = 0; ii < bits; ii++) {
        mux.c[ii][0] <== in[0][ii];
    }
    component shifters[bits - 1];
    for (var ii = 0; ii < bits - 1; ii++) {
        shifters[ii] = RightShifter(bits);
    }
    for (var ii = 0; ii < bits - 1; ii++) {
        shifters[ii].k <== k;
        for (var jj = 0; jj < bits; jj++) {
            shifters[ii].in[jj] <== mux.c[jj][ii];
        }
        for (var jj = 0; jj < bits; jj++) {
            mux.c[jj][ii + 1] <== shifters[ii].out[jj];
        }
    }
    for (var ii = 0; ii < 5; ii++) {
        mux.s[ii] <== in[1][ii];
    }
    for (var ii = 0; ii < bits; ii++) {
        out[ii] <== mux.out[ii];
    }
}

template LeftShifter32(bits) {
    assert(bits == 32);
    signal input in[2][bits];
    signal input k;
    signal output out[bits];
    component mux = MultiMux5(bits);
    for (var ii = 0; ii < bits; ii++) {
        mux.c[ii][0] <== in[0][ii];
    }
    component shifters[bits - 1];
    for (var ii = 0; ii < bits - 1; ii++) {
        shifters[ii] = LeftShifter(bits);
    }
    for (var ii = 0; ii < bits - 1; ii++) {
        shifters[ii].k <== k;
        for (var jj = 0; jj < bits; jj++) {
            shifters[ii].in[jj] <== mux.c[jj][ii];
        }
        for (var jj = 0; jj < bits; jj++) {
            mux.c[jj][ii + 1] <== shifters[ii].out[jj];
        }
    }
    for (var ii = 0; ii < 5; ii++) {
        mux.s[ii] <== in[1][ii];
    }
    for (var ii = 0; ii < bits; ii++) {
        out[ii] <== mux.out[ii];
    }
}

template BitwiseXOR(bits) {
    signal input in[2][bits];
    signal output out[bits];
    component xors[bits];
    for (var ii = 0; ii < bits; ii++) {
        xors[ii] = XOR();
        xors[ii].a <== in[0][ii];
        xors[ii].b <== in[1][ii];
        out[ii] <== xors[ii].out;
    }
}

template BitwiseOR(bits) {
    signal input in[2][bits];
    signal output out[bits];
    component ors[bits];
    for (var ii = 0; ii < bits; ii++) {
        ors[ii] = OR();
        ors[ii].a <== in[0][ii];
        ors[ii].b <== in[1][ii];
        out[ii] <== ors[ii].out;
    }
}

template BitwiseAND(bits) {
    signal input in[2][bits];
    signal output out[bits];
    component ands[bits];
    for (var ii = 0; ii < bits; ii++) {
        ands[ii] = AND();
        ands[ii].a <== in[0][ii];
        ands[ii].b <== in[1][ii];
        out[ii] <== ands[ii].out;
    }
}
