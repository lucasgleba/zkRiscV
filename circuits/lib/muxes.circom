pragma circom 2.0.2;

include "../../node_modules/circomlib/circuits/mux1.circom";
include "../../node_modules/circomlib/circuits/mux4.circom";

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
