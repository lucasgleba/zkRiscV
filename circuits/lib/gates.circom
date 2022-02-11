pragma circom 2.0.2;

include "../../node_modules/circomlib/circuits/gates.circom";

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

// component main = Mux6();