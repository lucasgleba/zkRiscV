pragma circom 2.0.2;

include "../../node_modules/circomlib/circuits/mux1.circom";
include "../../node_modules/circomlib/circuits/mux4.circom";
include "../../node_modules/circomlib/circuits/switcher.circom";

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

template IMux1() {
    signal input in;
    signal input s;
    signal output out[2];
    component switcher = Switcher();
    switcher.sel <== s;
    switcher.L <== in;
    switcher.R <== 0;
    out[0] <== switcher.outL;
    out[1] <== switcher.outR;
}

template IMux2() {
    signal input in;
    signal input s[2];
    signal output out[4];
    component imux0 = IMux1();
    imux0.in <== in;
    imux0.s <== s[1];
    component imux1[2];
    for (var ii = 0; ii < 2; ii++) {
        imux1[ii] = IMux1();
        imux1[ii].s <== s[0];
        imux1[ii].in <== imux0.out[ii];
    }
    for (var ii = 0; ii < 2; ii++) {
        for (var jj = 0; jj < 2; jj++) {
            out[ii * 2 + jj] <== imux1[ii].out[jj];
        }
    }
}

template IMux3() {
    var sSize = 3;
    var outSize = 2 ** sSize;
    var halfOutSize = outSize / 2;
    signal input in;
    signal input s[sSize];
    signal output out[outSize];
    component imux0 = IMux1();
    imux0.in <== in;
    imux0.s <== s[sSize - 1];
    component imux2[2];
    for (var ii = 0; ii < 2; ii++) {
        imux2[ii] = IMux2();
        imux2[ii].in <== imux0.out[ii];
        for (var jj = 0; jj < sSize - 1; jj++) imux2[ii].s[jj] <== s[jj];
    }
    for (var ii = 0; ii < 2; ii++) {
        for (var jj = 0; jj < halfOutSize; jj++) {
            out[ii * halfOutSize + jj] <== imux2[ii].out[jj];
        }
    }
}

template IMux4() {
    var sSize = 4;
    var outSize = 2 ** sSize;
    var halfOutSize = outSize / 2;
    signal input in;
    signal input s[sSize];
    signal output out[outSize];
    component imux0 = IMux1();
    imux0.in <== in;
    imux0.s <== s[sSize - 1];
    component imux3[2];
    for (var ii = 0; ii < 2; ii++) {
        imux3[ii] = IMux3();
        imux3[ii].in <== imux0.out[ii];
        for (var jj = 0; jj < sSize - 1; jj++) imux3[ii].s[jj] <== s[jj];
    }
    for (var ii = 0; ii < 2; ii++) {
        for (var jj = 0; jj < halfOutSize; jj++) {
            out[ii * halfOutSize + jj] <== imux3[ii].out[jj];
        }
    }
}

template IMux5() {
    var sSize = 5;
    var outSize = 2 ** sSize;
    var halfOutSize = outSize / 2;
    signal input in;
    signal input s[sSize];
    signal output out[outSize];
    component imux0 = IMux1();
    imux0.in <== in;
    imux0.s <== s[sSize - 1];
    component imux4[2];
    for (var ii = 0; ii < 2; ii++) {
        imux4[ii] = IMux4();
        imux4[ii].in <== imux0.out[ii];
        for (var jj = 0; jj < sSize - 1; jj++) imux4[ii].s[jj] <== s[jj];
    }
    for (var ii = 0; ii < 2; ii++) {
        for (var jj = 0; jj < halfOutSize; jj++) {
            out[ii * halfOutSize + jj] <== imux4[ii].out[jj];
        }
    }
}

template IMux6() {
    var sSize = 6;
    var outSize = 2 ** sSize;
    var halfOutSize = outSize / 2;
    signal input in;
    signal input s[sSize];
    signal output out[outSize];
    component imux0 = IMux1();
    imux0.in <== in;
    imux0.s <== s[sSize - 1];
    component imux5[2];
    for (var ii = 0; ii < 2; ii++) {
        imux5[ii] = IMux5();
        imux5[ii].in <== imux0.out[ii];
        for (var jj = 0; jj < sSize - 1; jj++) imux5[ii].s[jj] <== s[jj];
    }
    for (var ii = 0; ii < 2; ii++) {
        for (var jj = 0; jj < halfOutSize; jj++) {
            out[ii * halfOutSize + jj] <== imux5[ii].out[jj];
        }
    }
}