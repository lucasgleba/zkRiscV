pragma circom 2.0.2;

include "./decoder.circom";
include "./state.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

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

template VM() {
    assert(PROGRAM_SIZE() == 64);

    signal input pc0;
    signal input r0[N_REGISTERS()];
    signal input m0[MEMORY_SIZE()];
    // signal input rRoots;
    // signal input mRoots;
    signal output pc1;
    signal output r1[N_REGISTERS()];
    signal output m1[MEMORY_SIZE()];

    component instructionFetch = Memory64_Load(INSTRUCTION_SIZE_BYTES(), M_SLOT_SIZE());
    instructionFetch.pointer_dec <== pc0;
    for (var ii = 0; ii < PROGRAM_SIZE(); ii++) instructionFetch.m[ii] <== m0[PROGRAM_START() + ii];
    signal instruction_dec;
    instruction_dec <== instructionFetch.out_dec;

    component instruction_bin = Num2Bits(INSTRUCTION_SIZE_BITS());
    instruction_bin.in <== instruction_dec;

    component decoder = RV32I_Decoder();
    for (var ii = 0; ii < INSTRUCTION_SIZE_BITS(); ii++) decoder.instruction_bin[ii] <== instruction_bin.out[ii];

    component rs1Fetcher = RV32I_Register_Load();
    component rs2Fetcher = RV32I_Register_Load();

    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) {
        rs1Fetcher.address_bin[ii] <== decoder.rs1_bin[ii];
        rs2Fetcher.address_bin[ii] <== decoder.rs2_bin[ii];
    }

    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        rs1Fetcher.r[ii] <== r0[ii];
        rs2Fetcher.r[ii] <== r0[ii];
    }

    signal rs1_value_dec;
    signal rs2_value_dec;

    rs1_value_dec <== rs1Fetcher.out;
    rs2_value_dec <== rs2Fetcher.out;

    component alu = ALU();
    for (var ii = 0; ii < INSTR_TYPE_SIZE(); ii++) alu.instructionType_bin[ii] <== decoder.instructionType_bin[ii];
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) alu.opcode_bin_6_2[ii] <== decoder.opcode_bin_6_2[ii];
    for (var ii = 0; ii < F3_SIZE(); ii++) alu.f3_bin[ii] <== decoder.f3_bin[ii];
    for (var ii = 0; ii < F7_SIZE(); ii++) alu.f7_bin[ii] <== decoder.f7_bin[ii];
    alu.pcIn_dec <== pc0;
    alu.rs1_value_dec <== rs1_value_dec;
    alu.rs2_value_dec <== rs2_value_dec;
    alu.imm_dec <== decoder.imm_dec;

    signal aluOut_dec;
    aluOut_dec <== alu.out_dec;
    pc1 <== alu.pcOut_dec;

}
