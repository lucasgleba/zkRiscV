pragma circom 2.0.2;

include "./lib/muxes.circom";
include "./constants.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

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