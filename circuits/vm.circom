pragma circom 2.0.2;

include "./lib/packHash.circom";
include "./lib/bitify.circom";
include "./decoder.circom";
include "./state.circom";
include "./alu.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/gates.circom";

// TODO: make names more consistent
// TODO: load vs fetch
// TODO: check r and m values are never going to be out of bounds [!]
//          How to handle input state having values out of bounds [?]
// TODO: add merklelized state [!]

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


template MPointer() {
    signal input imm_dec;
    signal input rs1Value_dec;
    signal output out_dec;
    out_dec <== rs1Value_dec + imm_dec;
}

template K_Parser() {
    signal input instructionType_bin[INSTRUCTION_TYPE_SIZE()];
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal output kM;
    signal output kR;

    component mAnd = AND();
    mAnd.a <== instructionType_bin[2];
    mAnd.b <== opcode_bin_6_2[3];
    kM <== mAnd.out;

    component rNand = NAND();
    rNand.a <== instructionType_bin[0];
    rNand.b <== instructionType_bin[1];
    component rNot = NOT();
    rNot.in <== opcode_bin_6_2[3];
    component rMux = Mux1();
    rMux.c[0] <== rNand.out;
    rMux.c[1] <== rNot.out;
    rMux.s <== instructionType_bin[2];
    kR <== rMux.out;
}

template NewRDValueDecider() {
    signal input aluOut_dec;
    signal input mOut_dec;
    signal input instructionType_bin[INSTRUCTION_TYPE_SIZE()];
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal output out_dec;

    component not = NOT();
    not.in <== opcode_bin_6_2[3];
    component and = AND();
    and.a <== not.out;
    and.b <== instructionType_bin[2];

    component mux = Mux1();
    mux.c[0] <== aluOut_dec;
    mux.c[1] <== mOut_dec;
    mux.s <== and.out;

    out_dec <== mux.out;
}

template VMStep_Flat() {
    assert(PROGRAM_SIZE() == 64);

    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input mIn[MEMORY_SIZE()];
    // signal input rRoots;
    // signal input mRoots;
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mOut[MEMORY_SIZE()];

    // set mOut for program slice
    for (var ii = PROGRAM_START(); ii < PROGRAM_END(); ii++) {
        mOut[ii] <== mIn[ii];
    }

    // fetch instruction
    component instructionFetch = Memory64_Load(INSTRUCTION_SIZE_BYTES(), M_SLOT_SIZE(), PROGRAM_START());
    instructionFetch.pointer_dec <== pcIn;
    for (var ii = 0; ii < PROGRAM_SIZE(); ii++) instructionFetch.m[ii] <== mIn[PROGRAM_START() + ii];

    // decode instruction
    component instruction_bin = Num2Bits(INSTRUCTION_SIZE_BITS());
    instruction_bin.in <== instructionFetch.out_dec;

    component decoder = RV32I_Decoder();
    for (var ii = 0; ii < INSTRUCTION_SIZE_BITS(); ii++) decoder.instruction_bin[ii] <== instruction_bin.out[ii];

    // load register data
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

    signal rs1Value_dec;
    signal rs1Value_bin[R_SIZE()];
    signal rs2Value_dec;
    signal rs2Value_bin[R_SIZE()];

    rs1Value_dec <== rs1Loader.out_dec;
    rs2Value_dec <== rs2Loader.out_dec;

    component RValueBin[2];
    for (var ii = 0; ii < 2; ii++) RValueBin[ii] = Num2Bits(R_SIZE());
    RValueBin[0].in <== rs1Value_dec;
    RValueBin[1].in <== rs2Value_dec;

    for (var ii = 0; ii < R_SIZE(); ii++) {
        rs1Value_bin[ii] <== RValueBin[0].out[ii];
        rs2Value_bin[ii] <== RValueBin[1].out[ii];
    }

    // compute
    component alu = ALU();
    for (var ii = 0; ii < INSTRUCTION_TYPE_SIZE(); ii++) alu.instructionType_bin[ii] <== decoder.instructionType_bin[ii];
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) alu.opcode_bin_6_2[ii] <== decoder.opcode_bin_6_2[ii];
    for (var ii = 0; ii < F3_SIZE(); ii++) alu.f3_bin[ii] <== decoder.f3_bin[ii];
    for (var ii = 0; ii < F7_SIZE(); ii++) alu.f7_bin[ii] <== decoder.f7_bin[ii];
    for (var ii = 0; ii < R_SIZE(); ii++) {
        alu.rs1Value_bin[ii] <== rs1Value_bin[ii];
        alu.rs2Value_bin[ii] <== rs2Value_bin[ii];
    }
    alu.pcIn_dec <== pcIn;
    alu.rs1Value_dec <== rs1Value_dec;
    alu.rs2Value_dec <== rs2Value_dec;
    alu.imm_dec <== decoder.imm_dec;
    pcOut <== alu.pcOut_dec;

    // fetch memory
    component mPointer = MPointer();
    mPointer.rs1Value_dec <== rs1Value_dec;
    mPointer.imm_dec <== decoder.imm_dec;

    component mLoad = Memory64_Load(1, M_SLOT_SIZE(), DATA_START());
    mLoad.pointer_dec <== mPointer.out_dec;
    for (var ii = 0; ii < DATA_SIZE(); ii++) mLoad.m[ii] <== mIn[DATA_START() + ii];

    // parse ks
    component ks = K_Parser();
    for (var ii = 0; ii < INSTRUCTION_TYPE_SIZE(); ii++) ks.instructionType_bin[ii] <== decoder.instructionType_bin[ii];
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) ks.opcode_bin_6_2[ii] <== decoder.opcode_bin_6_2[ii];

    // store into memory
    component rs2Value_7_0_dec = Bits2Num(M_SLOT_SIZE());
    for (var ii = 0; ii < M_SLOT_SIZE(); ii++) rs2Value_7_0_dec.in[ii] <== rs2Value_bin[ii];
    component mStore = Memory64_Store1(DATA_START());
    mStore.in_dec <== rs2Value_7_0_dec.out;
    mStore.pointer_dec <== mPointer.out_dec;
    mStore.k <== ks.kM;
    for (var ii = 0; ii < DATA_SIZE(); ii++) mStore.mIn[ii] <== mIn[DATA_START() + ii];
    for (var ii = 0; ii < DATA_SIZE(); ii++) mOut[DATA_START() + ii] <== mStore.mOut[ii];

    // memory vs alu output
    component newRDValueDecider = NewRDValueDecider();
    newRDValueDecider.aluOut_dec <== alu.out_dec;
    newRDValueDecider.mOut_dec <== mLoad.out_dec;
    for (var ii = 0; ii < INSTRUCTION_TYPE_SIZE(); ii++) newRDValueDecider.instructionType_bin[ii] <== decoder.instructionType_bin[ii];
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) newRDValueDecider.opcode_bin_6_2[ii] <== decoder.opcode_bin_6_2[ii];

    // store into register
    component rStore = RV32I_Register_Store();
    rStore.in_dec <== newRDValueDecider.out_dec;
    rStore.k <== ks.kR;
    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) rStore.address_bin[ii] <== decoder.rd_bin[ii];
    for (var ii = 0; ii < N_REGISTERS(); ii++) rStore.rIn[ii] <== rIn[ii];
    for (var ii = 0; ii < N_REGISTERS(); ii++) rOut[ii] <== rStore.rOut[ii];
}

template VMMultiStep_Flat(n) {
    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input mIn[MEMORY_SIZE()];
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mOut[MEMORY_SIZE()];

    component steps[n];
    for (var ii = 0; ii < n; ii++) steps[ii] = VMStep_Flat();
    
    steps[0].pcIn <== pcIn;
    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        steps[0].rIn[ii] <== rIn[ii];
    }
    for (var ii = 0; ii < MEMORY_SIZE(); ii++) {
        steps[0].mIn[ii] <== mIn[ii];
    }

    for (var ii = 1; ii < n; ii++) {
        steps[ii].pcIn <== steps[ii - 1].pcOut;
        for (var jj = 0; jj < N_REGISTERS(); jj++) {
            steps[ii].rIn[jj] <== steps[ii - 1].rOut[jj];
        }
        for (var jj = 0; jj < MEMORY_SIZE(); jj++) {
            steps[ii].mIn[jj] <== steps[ii - 1].mOut[jj];
        }
    }

    pcOut <== steps[n - 1].pcOut;
    for (var jj = 0; jj < N_REGISTERS(); jj++) {
        rOut[jj] <== steps[n - 1].rOut[jj];
    }
    for (var jj = 0; jj < MEMORY_SIZE(); jj++) {
        mOut[jj] <== steps[n - 1].mOut[jj];
    }

}

template StateHash_Flat() {
    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input mIn[MEMORY_SIZE()];
    signal output out;

    var stateSize = 1 + N_REGISTERS() + MEMORY_SIZE();

    component hash = PackHash(stateSize, 8);
    // TODO: is this packing 32-bit register as 8-bit [???]
    // TODO: separate packing from hashing, pack rs as 32 bit and ms as 8 bit [!]
    hash.in[0] <== pcIn;
    for (var ii = 0; ii < N_REGISTERS(); ii++) hash.in[1 + ii] <== rIn[ii];
    for (var ii = 0; ii < MEMORY_SIZE(); ii++) hash.in[1 + N_REGISTERS() + ii] <== mIn[ii];

    out <== hash.out;
}

template ValidVMMultiStep_Flat(n, rangeCheck) {
    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input mIn[MEMORY_SIZE()];
    signal input root0;
    signal input root1;
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mOut[MEMORY_SIZE()];

    // component pcRangeCheck;
    component rRangeCheck;
    component mRangeCheck;

    if (rangeCheck == 1) {
        // pcRangeCheck = AssertInBitRange(R_SIZE());
        // pcRangeCheck.in <== pcIn;
        rRangeCheck = MultiAssertInBitRange(N_REGISTERS(), R_SIZE());
        for (var ii = 0; ii < N_REGISTERS(); ii++) rRangeCheck.in[ii] <== rIn[ii];
        mRangeCheck = MultiAssertInBitRange(MEMORY_SIZE(), R_SIZE());
        for (var ii = 0; ii < MEMORY_SIZE(); ii++) mRangeCheck.in[ii] <== mIn[ii];
    }

    component stateHash0 = StateHash_Flat();
    component vm = VMMultiStep_Flat(n);
    stateHash0.pcIn <== pcIn;
    vm.pcIn <== pcIn;
    
    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        stateHash0.rIn[ii] <== rIn[ii];
        vm.rIn[ii] <== rIn[ii];
    }
    
    for (var ii = 0; ii < MEMORY_SIZE(); ii++) {
        stateHash0.mIn[ii] <== mIn[ii];
        vm.mIn[ii] <== mIn[ii];
    }

    root0 === stateHash0.out;

    component stateHash1 = StateHash_Flat();
    stateHash1.pcIn <== vm.pcOut;
    for (var ii = 0; ii < N_REGISTERS(); ii++) stateHash1.rIn[ii] <== vm.rOut[ii];
    for (var ii = 0; ii < MEMORY_SIZE(); ii++) stateHash1.mIn[ii] <== vm.mOut[ii];

    root1 === stateHash1.out;

}

// component main {public [root0, root1]} = ValidVMMultiStep_Flat(1, 0);

/**

******** CONSTRAINS ********

ALU         2444
    CompW   2397
    LoadI   1
    Jump    3
    Branch  6

Decoder 13

State
    Memory64_Load1  339  // [!] Most from Num2Bits_soft32
    Memory64_Load4  1356  // [!]
    Memory64_Store1 387 // [!]
    RV32I_Register_Load     39
    RV32I_Register_Store    62

VMStep_Flat     4780
StateHash_Flat  3960 // Shouldn't this be 660 * 8 instead of 6 [???]

BitwiseXOR32    32
BitwiseOR32     32
BitwiseAND32    32

Num2Bits_soft32     286 // [!]
AssertInBitRange32  32

LeftShift1      0
RightShift32_1  32
VariableShift32_right       1063 // [!]
VariableShift32_left        1063 // [!]
VariableBinShift32_right    760 // [!]
VariableBinShift32_left     760 // [!]

 */
