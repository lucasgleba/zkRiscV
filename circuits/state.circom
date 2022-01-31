pragma circom 2.0.2;

include "./lib/muxes.circom";
include "./constants.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/binsum.circom";

template Memory64_Load(fetchSize, mSlotSize) {
    assert(fetchSize > 0);
    var log2MSize = 6;
    var mSize = 2 ** log2MSize;

    signal input pointer_dec;
    signal input m[mSize];
    signal output out_dec;

    component address[fetchSize];
    for (var ii = 0; ii < fetchSize; ii++) address[ii] = Num2Bits(log2MSize + 1);
    for (var ii = 0; ii < fetchSize; ii++) address[ii].in <== pointer_dec + ii;

    component mux[fetchSize];
    for (var ii = 0; ii < fetchSize; ii++) mux[ii] = Mux6();
    for (var ii = 0; ii < fetchSize; ii++) {
        for (var jj = 0; jj < log2MSize; jj++) mux[ii].s[jj] <== address[ii].out[jj];
        for (var jj = 0; jj < mSize; jj++) mux[ii].c[jj] <== m[jj];
    }

    signal result[fetchSize];
    result[0] <== mux[0].out;
    for (var ii = 1; ii < fetchSize; ii++) result[ii] <== result[ii - 1] + mux[ii].out * 2 ** (ii * mSlotSize);

    out_dec <== result[fetchSize - 1];
}

// TODO: might be more efficient to just chain store1 [?]
template Memory64_Store(storeSize, mSlotSize) {
    // TODO: split input into bytes [?]
    assert(storeSize > 0);
    var log2MSize = 6;
    var mSize = 2 ** log2MSize;

    signal input pointer_dec;
    signal input in[storeSize];
    signal input mIn[mSize];
    signal output mOut[mSize];

    component s[storeSize];
    for (var ii = 0; ii < storeSize; ii++) s[ii] = Num2Bits(log2MSize);
    for (var ii = 0; ii < storeSize; ii++) {
        s[ii].in <== pointer_dec + ii;
    }

    component imux[storeSize][2];
    for (var ii = 0; ii < storeSize; ii++) {
        for (var jj = 0; jj < 2; jj++) {
            imux[ii][jj] = IMux6();
        }
    }
    component sum[2];
    for (var ii = 0; ii < 2; ii++) sum[ii] = BinSum(mSize, storeSize);

    for (var ii = 0; ii < 2; ii++) {
        for (var jj = 0; jj < storeSize; jj++) {
            if (ii == 0) {
                imux[jj][ii].in <== 1;
            } else {
                imux[jj][ii].in <== in[jj];
            }
            for (var kk = 0; kk < log2MSize; kk++) imux[jj][ii].s[kk] <== s[jj].out[kk];
        }
        for (var jj = 0; jj < storeSize; jj++) {
            for (var kk = 0; kk < mSize; kk++) sum[ii].in[jj][kk] <== imux[jj][ii].out[kk];
        }
    }

    component mux1[mSize];
    for (var ii = 0; ii < mSize; ii++) mux1[ii] = Mux1();
    for (var ii = 0; ii < mSize; ii++) {
        mux1[ii].s <== sum[0].out[ii];
        mux1[ii].c[0] <== mIn[ii];
        mux1[ii].c[1] <== sum[1].out[ii];
        mOut[ii] <== mux1[ii].out;
    }

}

template Memory64_Store1() {
    var log2MSize = 6;
    var mSize = 2 ** log2MSize;

    signal input pointer_dec;
    signal input in;
    signal input mIn[mSize];
    signal output mOut[mSize];

    component s = Num2Bits(log2MSize);
    s.in <== pointer_dec;
    component imux = IMux6();
    for (var ii = 0; ii < log2MSize; ii++) imux.s[ii] <== s.out[ii];
    imux.in <== 1;

    component mux[mSize];
    for (var ii = 0; ii < mSize; ii++) mux[ii] = Mux1();
    for (var ii = 0; ii < mSize; ii++) {
        mux[ii].s <== imux.out[ii];
        mux[ii].c[0] <== mIn[ii];
        mux[ii].c[1] <== in;
        mOut[ii] <== mux[ii].out;
    }
}

template RV32I_Register_Load() {
    signal input address_bin[R_ADDRESS_SIZE()];
    signal input r[N_REGISTERS()];
    signal output out_dec;

    component mux = Mux5();
    mux.c[0] <== 0;
    for (var ii = 0; ii < N_REGISTERS() - 1; ii++) mux.c[1 + ii] <== r[ii];
    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) mux.s <== address_bin[ii];

    out_dec <== mux.out;
}

// component main = Memory64_Store1();
