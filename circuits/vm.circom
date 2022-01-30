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

// TODO: generalize this to memory fetcher
template Instruction_Fetcher() {
    // TODO: check alignement [?]
    signal input pc_dec;
    signal input m[MEMORY_SIZE()];
    signal output instruction_dec;

    component pcP0Bin = Num2Bits(LOG2_PROGRAM_SIZE());
    component pcP1Bin= Num2Bits(LOG2_PROGRAM_SIZE());
    component pcP2Bin = Num2Bits(LOG2_PROGRAM_SIZE());
    component pcP3Bin = Num2Bits(LOG2_PROGRAM_SIZE());
    pcP0Bin.in <== pc_dec + 0;
    pcP1Bin.in <== pc_dec + 1;
    pcP2Bin.in <== pc_dec + 2;
    pcP3Bin.in <== pc_dec + 3;

    signal instr0_dec;
    signal instr1_dec;
    signal instr2_dec;
    signal instr3_dec;
    component instr0Mux = Mux6();
    component instr1Mux = Mux6();
    component instr2Mux = Mux6();
    component instr3Mux = Mux6();

    for (var ii = 0; ii < LOG2_PROGRAM_SIZE(); ii++) {
        instr0Mux.s[ii] <== pcP0Bin.out[ii];
        instr1Mux.s[ii] <== pcP1Bin.out[ii];
        instr2Mux.s[ii] <== pcP2Bin.out[ii];
        instr3Mux.s[ii] <== pcP3Bin.out[ii];
    }

    for (var ii = 0; ii < PROGRAM_SIZE(); ii++) {
        instr0Mux.c[ii] <== m[PROGRAM_START() + ii];
        instr1Mux.c[ii] <== m[PROGRAM_START() + ii];
        instr2Mux.c[ii] <== m[PROGRAM_START() + ii];
        instr3Mux.c[ii] <== m[PROGRAM_START() + ii];
    }

    instruction_dec <== instr0Mux.out * 2 ** 0 + instr0Mux.out * 2 ** 1 + instr0Mux.out * 2 ** 2 + instr0Mux.out * 2 ** 3;

}

template VM() {
    signal input r0[N_REGISTERS()];
    signal input m0[MEMORY_SIZE()];
    // signal input rRoots;
    // signal input mRoots;

    component instruction = Instruction_Fetcher();
    instruction.pc_dec <== r0[0];
    for (var ii = 0; ii < MEMORY_SIZE(); ii++) instruction.m0[ii] <== m0[ii];

    signal instruction_dec;
    instruction_dec <== instruction.instruction_dec;

}

// component main = Instruction_Fetcher();
