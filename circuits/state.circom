pragma circom 2.0.2;

include "./lib/muxes.circom";
include "./lib/bitify.circom";
include "./constants.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/binsum.circom";

template Memory64_Load(fetchSize, mSlotSize, firstAddress) {
    assert(fetchSize > 0);
    var log2MSize = 6;
    var mSize = 2 ** log2MSize;

    signal input pointer_dec;
    signal input m[mSize];
    signal output out_dec;

    component addresses[fetchSize];
    for (var ii = 0; ii < fetchSize; ii++) addresses[ii] = Num2Bits(log2MSize);
    for (var ii = 0; ii < fetchSize; ii++) addresses[ii].in <== pointer_dec + ii - firstAddress;

    component mux[fetchSize];
    for (var ii = 0; ii < fetchSize; ii++) mux[ii] = Mux6();
    for (var ii = 0; ii < fetchSize; ii++) {
        for (var jj = 0; jj < log2MSize; jj++) mux[ii].s[jj] <== addresses[ii].out[jj];
        for (var jj = 0; jj < mSize; jj++) mux[ii].c[jj] <== m[jj];
    }

    signal result[fetchSize];
    result[0] <== mux[0].out;
    for (var ii = 1; ii < fetchSize; ii++) result[ii] <== result[ii - 1] + mux[ii].out * 2 ** (ii * mSlotSize);

    out_dec <== result[fetchSize - 1];
}

template Memory64_Store1(firstAddress) {
    var log2MSize = 6;
    var mSize = 2 ** log2MSize;

    signal input pointer_dec;
    signal input in_dec;
    signal input k;
    signal input mIn[mSize];
    signal output mOut[mSize];

    component s = Num2Bits(log2MSize);
    s.in <== pointer_dec - firstAddress;
    component imux = IMux6();
    for (var ii = 0; ii < log2MSize; ii++) imux.s[ii] <== s.out[ii];
    imux.in <== k;

    component mux[mSize];
    for (var ii = 0; ii < mSize; ii++) mux[ii] = Mux1();
    for (var ii = 0; ii < mSize; ii++) {
        mux[ii].s <== imux.out[ii];
        mux[ii].c[0] <== mIn[ii];
        mux[ii].c[1] <== in_dec;
        mOut[ii] <== mux[ii].out;
    }
}

template RV32I_Register_Load() {
    signal input address_bin[R_ADDRESS_SIZE()];
    signal input r[N_REGISTERS()];
    signal output out_dec;

    component mux = Mux5();
    mux.c[0] <== 0;
    for (var ii = 0; ii < N_REGISTERS(); ii++) mux.c[1 + ii] <== r[ii];
    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) mux.s[ii] <== address_bin[ii];

    out_dec <== mux.out;
}

template RV32I_Register_Store() {
    signal input address_bin[R_ADDRESS_SIZE()];
    signal input in_dec;
    signal input k;
    signal input rIn[N_REGISTERS()];
    signal output rOut[N_REGISTERS()];

    component imux = IMux5();
    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) imux.s[ii] <== address_bin[ii];
    imux.in <== k;

    component mux[N_REGISTERS()];
    for (var ii = 0; ii < N_REGISTERS(); ii++) mux[ii] = Mux1();
    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        mux[ii].s <== imux.out[ii + 1];
        mux[ii].c[0] <== rIn[ii];
        mux[ii].c[1] <== in_dec;
        rOut[ii] <== mux[ii].out;
    }
}

// component main = RV32I_Register_Store();
