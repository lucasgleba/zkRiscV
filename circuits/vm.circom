pragma circom 2.0.2;

include "./decoder.circom";
include "./state.circom";
include "./alu.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/gates.circom";

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

template RStore() {
    signal input in;
    signal input rd_bin[R_ADDRESS_SIZE()];
    signal input instructionType_bin[INSTR_TYPE_SIZE()];
    signal input rIn[N_REGISTERS()];
    signal output rOut[N_REGISTERS()];
    component k = NOT();
    k.in <== instruction_bin[1];
    component registerStore = RV32I_Register_Store();
    registerStore.k <== k.out;
    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) registerStore.address_bin[ii] <== rd_bin[ii];
    registerStore.in <== in;
    for (var ii = 0; ii < N_REGISTERS(); ii++) registerStore.rIn[ii] <== rIn[ii];
    for (var ii = 0; ii < N_REGISTERS(); ii++) rOut[ii] <== registerStore.rOut[ii];
}

template MStore() {
    signal input imm_dec;
    signal input rs1_value_dec;
    signal input rs2_value_dec;
    signal input instructionType_bin[INSTR_TYPE_SIZE()];
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input mIn[DATA_SIZE()];
    signal input mOut[DATA_SIZE()];

    component k = AND();
    k.a <== instructionType_bin[2];
    k.b <== opcode_bin_6_2[3];
    component memoryStore = Memory64_Store1(DATA_START());
    memoryStore.k <== k.out;
    memoryStore.pointer_dec <== rs1_value_dec + imm;
    memoryStore.in <== rs2_value_dec;
    for (var ii = 0; ii < DATA_SIZE(); ii++) memoryStore.mIn[ii] <== mIn[ii];
    for (var ii = 0; ii < DATA_SIZE(); ii++) mOut[ii] <== memoryStore.mOut[ii];
}

template VM() {
    assert(PROGRAM_SIZE() == 64);

    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input mIn[MEMORY_SIZE()];
    // signal input rRoots;
    // signal input mRoots;
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mOut[MEMORY_SIZE()];

    component instructionFetch = Memory64_Load(INSTRUCTION_SIZE_BYTES(), M_SLOT_SIZE(), PROGRAM_START());
    instructionFetch.pointer_dec <== pcIn;
    for (var ii = 0; ii < PROGRAM_SIZE(); ii++) instructionFetch.m[ii] <== mIn[PROGRAM_START() + ii];
    signal instruction_dec;
    instruction_dec <== instructionFetch.out_dec;

    component instruction_bin = Num2Bits(INSTRUCTION_SIZE_BITS());
    instruction_bin.in <== instruction_dec;

    component decoder = RV32I_Decoder();
    for (var ii = 0; ii < INSTRUCTION_SIZE_BITS(); ii++) decoder.instruction_bin[ii] <== instruction_bin.out[ii];

    component rs1Loader = RV32I_Register_Load();
    component rs2Loader = RV32I_Register_Load();

    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) {
        rs1Loader.address_bin[ii] <== decoder.rs1_bin[ii];
        rs2Loader.address_bin[ii] <== decoder.rs2_bin[ii];
    }

    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        rs1Loader.r[ii] <== rIn[ii];
        rs2Loader.r[ii] <== rIn[ii];
    }

    signal rs1_value_dec;
    signal rs2_value_dec;

    rs1_value_dec <== rs1Loader.out;
    rs2_value_dec <== rs2Loader.out;

    component alu = ALU();
    for (var ii = 0; ii < INSTR_TYPE_SIZE(); ii++) alu.instructionType_bin[ii] <== decoder.instructionType_bin[ii];
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) alu.opcode_bin_6_2[ii] <== decoder.opcode_bin_6_2[ii];
    for (var ii = 0; ii < F3_SIZE(); ii++) alu.f3_bin[ii] <== decoder.f3_bin[ii];
    for (var ii = 0; ii < F7_SIZE(); ii++) alu.f7_bin[ii] <== decoder.f7_bin[ii];
    alu.pcIn_dec <== pcIn;
    alu.rs1_value_dec <== rs1_value_dec;
    alu.rs2_value_dec <== rs2_value_dec;
    alu.imm_dec <== decoder.imm_dec;

    signal aluOut_dec;
    aluOut_dec <== alu.out_dec;
    pcOut <== alu.pcOut_dec;



}
