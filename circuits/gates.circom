pragma circom 2.0.2;

include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/mux2.circom";
include "../node_modules/circomlib/circuits/mux4.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/binsum.circom";
include "../node_modules/circomlib/circuits/binsub.circom";
include "../node_modules/circomlib/circuits/gates.circom";

template MultiMux5(n) {
    var size = 5;
    var nInputs = 2 ** size;
    var halfNInputs = nInputs / 2;
    signal input c[n][nInputs];
    signal input s[size];
    signal output out[n];
    component mux4a = MultiMux4(n);
    component mux4b = MultiMux4(n);
    for (var ii = 0; ii < halfNInputs; ii++) {
        for (var jj = 0; jj < n; jj++) {
            mux4a.c[jj][ii] <== c[jj][ii];
            mux4b.c[jj][ii] <== c[jj][halfNInputs + ii];
        }
    }
    for (var ii = 0; ii < size - 1; ii++) {
        mux4a.s[ii] <== s[ii];
        mux4b.s[ii] <== s[ii];
    }
    component mux1 = MultiMux1(n);
    for (var ii = 0; ii < n; ii++) {
        mux1.c[ii][0] <== mux4a.out[ii];
        mux1.c[ii][1] <== mux4b.out[ii];
    }
    mux1.s <== s[size - 1];
    for (var ii = 0; ii < n; ii++) {
        out[ii] <== mux1.out[ii];
    }
}

template Mux5() {
    var size = 5;
    var nInputs = 2 ** size;
    signal input c[nInputs];
    signal input s[size];
    signal output out;
    component mux = MultiMux5(1);
    for (var ii = 0; ii < nInputs; ii++) mux.c[0][ii] <== c[ii];
    for (var ii = 0; ii < size; ii++) mux.s[ii] <== s[ii];
    out <== mux.out[0];
}

template MultiMux6(n) {
    var size = 6;
    var nInputs = 2 ** size;
    var halfNInputs = nInputs / 2;
    signal input c[n][nInputs];
    signal input s[size];
    signal output out[n];
    component mux5a = MultiMux5(n);
    component mux5b = MultiMux5(n);
    for (var ii = 0; ii < halfNInputs; ii++) {
        for (var jj = 0; jj < n; jj++) {
            mux5a.c[jj][ii] <== c[jj][ii];
            mux5b.c[jj][ii] <== c[jj][halfNInputs + ii];
        }
    }
    for (var ii = 0; ii < size - 1; ii++) {
        mux5a.s[ii] <== s[ii];
        mux5b.s[ii] <== s[ii];
    }
    component mux1 = MultiMux1(n);
    for (var ii = 0; ii < n; ii++) {
        mux1.c[ii][0] <== mux5a.out[ii];
        mux1.c[ii][1] <== mux5b.out[ii];
    }
    mux1.s <== s[size - 1];
    for (var ii = 0; ii < n; ii++) {
        out[ii] <== mux1.out[ii];
    }
}

template Mux6() {
    var size = 6;
    var nInputs = 2 ** size;
    signal input c[nInputs];
    signal input s[size];
    signal output out;
    component mux = MultiMux6(1);
    for (var ii = 0; ii < nInputs; ii++) mux.c[0][ii] <== c[ii];
    for (var ii = 0; ii < size; ii++) mux.s[ii] <== s[ii];
    out <== mux.out[0];
}

// template LeftShift(n) {
//     signal input in[n];
//     signal input k;
//     signal output out[n];
//     out[0] <== k;
//     for (var ii = 1; ii < n; ii++) {
//         out[ii] <== in[ii - 1];
//     }
// }

// template RightShift(n) {
//     signal input in[n];
//     signal input k;
//     signal output out[n];
//     out[n - 1] <== k;
//     for (var ii = 0; ii < n - 1; ii++) {
//         out[ii] <== in[ii + 1];
//     }
// }

// // TODO: better shifter by muxing Shift(n) [?]
// template RightShift32() {
//     var n = 32;
//     signal input in[2][n];
//     signal input k;
//     signal output out[n];
//     component mux = MultiMux5(n);
//     for (var ii = 0; ii < n; ii++) {
//         mux.c[ii][0] <== in[0][ii];
//     }
//     component shifters[n - 1];
//     for (var ii = 0; ii < n - 1; ii++) {
//         shifters[ii] = RightShift(n);
//     }
//     for (var ii = 0; ii < n - 1; ii++) {
//         shifters[ii].k <== k;
//         for (var jj = 0; jj < n; jj++) {
//             shifters[ii].in[jj] <== mux.c[jj][ii];
//         }
//         for (var jj = 0; jj < n; jj++) {
//             mux.c[jj][ii + 1] <== shifters[ii].out[jj];
//         }
//     }
//     for (var ii = 0; ii < 5; ii++) {
//         mux.s[ii] <== in[1][ii];
//     }
//     for (var ii = 0; ii < n; ii++) {
//         out[ii] <== mux.out[ii];
//     }
// }

// template LeftShift32() {
//     var n == 32;
//     signal input in[2][n];
//     signal input k;
//     signal output out[n];
//     component mux = MultiMux5(n);
//     for (var ii = 0; ii < n; ii++) {
//         mux.c[ii][0] <== in[0][ii];
//     }
//     component shifters[n - 1];
//     for (var ii = 0; ii < n - 1; ii++) {
//         shifters[ii] = LeftShift(n);
//     }
//     for (var ii = 0; ii < n - 1; ii++) {
//         shifters[ii].k <== k;
//         for (var jj = 0; jj < n; jj++) {
//             shifters[ii].in[jj] <== mux.c[jj][ii];
//         }
//         for (var jj = 0; jj < n; jj++) {
//             mux.c[jj][ii + 1] <== shifters[ii].out[jj];
//         }
//     }
//     for (var ii = 0; ii < 5; ii++) {
//         mux.s[ii] <== in[1][ii];
//     }
//     for (var ii = 0; ii < n; ii++) {
//         out[ii] <== mux.out[ii];
//     }
// }

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