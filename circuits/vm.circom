pragma circom 2.0.2;

include "./gates.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/binsum.circom";

function N_REGISTERS() {
    return 32;
}

function LOG2_PROGRAM_SIZE() {
    return 6;
}

function LOG2_DATA_SIZE() {
    return 6;
}

function PROGRAM_SIZE() {
    return 2 ** LOG2_PROGRAM_SIZE();
}

function DATA_SIZE() {
    return 2 ** LOG2_DATA_SIZE();
}

function MEMORY_SIZE() {
    return PROGRAM_SIZE() + DATA_SIZE();
}

function PROGRAM_START() {
    return 0;
}

function PROGRAM_END() {
    return PROGRAM_SIZE();
}

function DATA_START() {
    return PROGRAM_END();
}

function DATA_END() {
    return MEMORY_SIZE();
}

function INSTRUCTION_SIZE_BYTES() {
    return 4;
}

function M_SLOT_SIZE() {
    return 8;
}

template Memory64_Fetcher(fetchSize, mSlotSize) {
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

// TODO: generalize this to memory fetcher
// template Instruction_Fetcher() {
//     // TODO: check alignement [?]
//     signal input pc_dec;
//     signal input m[MEMORY_SIZE()];
//     signal output instruction_dec;

//     component pcP0Bin = Num2Bits(LOG2_PROGRAM_SIZE());
//     component pcP1Bin= Num2Bits(LOG2_PROGRAM_SIZE());
//     component pcP2Bin = Num2Bits(LOG2_PROGRAM_SIZE());
//     component pcP3Bin = Num2Bits(LOG2_PROGRAM_SIZE());
//     pcP0Bin.in <== pc_dec + 0;
//     pcP1Bin.in <== pc_dec + 1;
//     pcP2Bin.in <== pc_dec + 2;
//     pcP3Bin.in <== pc_dec + 3;

//     signal instr0_dec;
//     signal instr1_dec;
//     signal instr2_dec;
//     signal instr3_dec;
//     component instr0Mux = Mux6();
//     component instr1Mux = Mux6();
//     component instr2Mux = Mux6();
//     component instr3Mux = Mux6();

//     for (var ii = 0; ii < LOG2_PROGRAM_SIZE(); ii++) {
//         instr0Mux.s[ii] <== pcP0Bin.out[ii];
//         instr1Mux.s[ii] <== pcP1Bin.out[ii];
//         instr2Mux.s[ii] <== pcP2Bin.out[ii];
//         instr3Mux.s[ii] <== pcP3Bin.out[ii];
//     }

//     for (var ii = 0; ii < PROGRAM_SIZE(); ii++) {
//         instr0Mux.c[ii] <== m[PROGRAM_START() + ii];
//         instr1Mux.c[ii] <== m[PROGRAM_START() + ii];
//         instr2Mux.c[ii] <== m[PROGRAM_START() + ii];
//         instr3Mux.c[ii] <== m[PROGRAM_START() + ii];
//     }

//     instruction_dec <== instr0Mux.out * 2 ** 0 + instr0Mux.out * 2 ** 1 + instr0Mux.out * 2 ** 2 + instr0Mux.out * 2 ** 3;

// }

template VM() {
    signal input r0[N_REGISTERS()];
    signal input m0[MEMORY_SIZE()];
    // signal input rRoots;
    // signal input mRoots;
    assert(PROGRAM_SIZE() == 64);
    component instructionFetch = Memory64_Fetcher(INSTRUCTION_SIZE_BYTES(), M_SLOT_SIZE());
    instructionFetch.pointer_dec <== r0[0];
    for (var ii = 0; ii < PROGRAM_SIZE(); ii++) instructionFetch.m[ii] <== m0[PROGRAM_START() + ii];
    signal instruction_dec;
    instruction_dec <== instructionFetch.out_dec;

}
