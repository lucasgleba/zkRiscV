pragma circom 2.0.2;

include "./lib/bitify.circom";
include "./lib/pack.circom";
include "./lib/merkleTree.circom";
include "./decoder.circom";
include "./state.circom";
include "./alu.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/gates.circom";
include "../node_modules/circomlib/circuits/mimcsponge.circom";

// TODO: make names more consistent
// TODO: load vs fetch
// TODO: check r and m values are never going to be out of bounds [!]
//          How to handle input state having values out of bounds [?]
// TODO: add merklelized state [!]
// TODO: make things cleaner than calling constant functions all the time
// TODO: spec cool memory optimizations
// TODO: handle invalid instruction [?]

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

// Flat memory, harvard model constants
function MEMORY_SIZE_FLAT() {
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
    return MEMORY_SIZE_FLAT();
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
    signal input mIn[MEMORY_SIZE_FLAT()];
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mOut[MEMORY_SIZE_FLAT()];

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
    signal input mIn[MEMORY_SIZE_FLAT()];
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mOut[MEMORY_SIZE_FLAT()];

    component steps[n];
    for (var ii = 0; ii < n; ii++) steps[ii] = VMStep_Flat();
    
    steps[0].pcIn <== pcIn;
    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        steps[0].rIn[ii] <== rIn[ii];
    }
    for (var ii = 0; ii < MEMORY_SIZE_FLAT(); ii++) {
        steps[0].mIn[ii] <== mIn[ii];
    }

    for (var ii = 1; ii < n; ii++) {
        steps[ii].pcIn <== steps[ii - 1].pcOut;
        for (var jj = 0; jj < N_REGISTERS(); jj++) {
            steps[ii].rIn[jj] <== steps[ii - 1].rOut[jj];
        }
        for (var jj = 0; jj < MEMORY_SIZE_FLAT(); jj++) {
            steps[ii].mIn[jj] <== steps[ii - 1].mOut[jj];
        }
    }

    pcOut <== steps[n - 1].pcOut;
    for (var jj = 0; jj < N_REGISTERS(); jj++) {
        rOut[jj] <== steps[n - 1].rOut[jj];
    }
    for (var jj = 0; jj < MEMORY_SIZE_FLAT(); jj++) {
        mOut[jj] <== steps[n - 1].mOut[jj];
    }

}

template StateHash_Flat() {
    signal input pc;
    signal input r[N_REGISTERS()];
    signal input m[MEMORY_SIZE_FLAT()];
    signal output out;

    // pack first 4 memory slots into 32-bits to use one less pack (saves 660 constraints)
    var packHackSize = 4;
    component pack4 = Pack(packHackSize, M_SLOT_SIZE());
    for (var ii = 0; ii < packHackSize; ii++) pack4.in[ii] <== m[ii];

    // vars
    var n32BitVars = 2 + N_REGISTERS(); // 2: packHack and pc
    var n8BitVars = MEMORY_SIZE_FLAT() - packHackSize;
    var packingVars32[3] = getPackingVars(n32BitVars, R_SIZE());
    var packingVars8[3] = getPackingVars(n8BitVars, M_SLOT_SIZE());
    var nPacks32 = packingVars32[1];
    var nPacks8 = packingVars8[1];
    var nPacks = nPacks32 + nPacks8;

    component packs32bits = Pack(n32BitVars, R_SIZE());
    packs32bits.in[0] <== pc;
    for (var ii = 0; ii < N_REGISTERS(); ii++) packs32bits.in[1 + ii] <== r[ii];
    packs32bits.in[n32BitVars - 1] <== pack4.out[0];
    
    component packs8bits = Pack(n8BitVars, M_SLOT_SIZE());
    for (var ii = 0; ii < n8BitVars; ii++) packs8bits.in[ii] <== m[packHackSize + ii];
    
    component mimc = MiMCSponge(nPacks, 220, 1);
    for (var ii = 0; ii < nPacks32; ii++) mimc.ins[ii] <== packs32bits.out[ii];
    for (var ii = 0; ii < nPacks8; ii++) mimc.ins[nPacks32 + ii] <== packs8bits.out[ii];
    mimc.k <== 0;
    out <== mimc.outs[0];

}

template ValidVMMultiStep_Flat(n, rangeCheck) {
    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input mIn[MEMORY_SIZE_FLAT()];
    signal input root0;
    signal input root1;
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mOut[MEMORY_SIZE_FLAT()];

    // component pcRangeCheck;
    component rRangeCheck;
    component mRangeCheck;

    if (rangeCheck == 1) {
        // pcRangeCheck = AssertInBitRange(R_SIZE());
        // pcRangeCheck.in <== pcIn;
        rRangeCheck = MultiAssertInBitRange(N_REGISTERS(), R_SIZE());
        for (var ii = 0; ii < N_REGISTERS(); ii++) rRangeCheck.in[ii] <== rIn[ii];
        mRangeCheck = MultiAssertInBitRange(MEMORY_SIZE_FLAT(), M_SLOT_SIZE());
        for (var ii = 0; ii < MEMORY_SIZE_FLAT(); ii++) mRangeCheck.in[ii] <== mIn[ii];
    }

    component stateHash0 = StateHash_Flat();
    component vm = VMMultiStep_Flat(n);
    stateHash0.pc <== pcIn;
    vm.pcIn <== pcIn;
    
    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        stateHash0.r[ii] <== rIn[ii];
        vm.rIn[ii] <== rIn[ii];
    }
    
    for (var ii = 0; ii < MEMORY_SIZE_FLAT(); ii++) {
        stateHash0.m[ii] <== mIn[ii];
        vm.mIn[ii] <== mIn[ii];
    }

    root0 === stateHash0.out;

    component stateHash1 = StateHash_Flat();
    stateHash1.pc <== vm.pcOut;
    for (var ii = 0; ii < N_REGISTERS(); ii++) stateHash1.r[ii] <== vm.rOut[ii];
    for (var ii = 0; ii < MEMORY_SIZE_FLAT(); ii++) stateHash1.m[ii] <== vm.mOut[ii];

    root1 === stateHash1.out;

}

/*
// Packed tree memory instruction fetch (not tested)
template VMStep_Tree(memoryDepth) {

    var instrutionPackingRatio = 7; // floor(253 / 32)
    var bytesPerInstructionPack = INSTRUCTION_SIZE_BYTES() * instrutionPackingRatio;
    var mPackingRatio = 31; // floor(253 / 8)

    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input instructionPackData[instrutionPackingRatio]; 
    signal input instructionProof[memoryDepth];
    signal input mPack[mPackingRatio];
    signal input mProof[memoryDepth];
    signal input mRoot0;
    signal input mRoot1;
    signal output pcOut;
    signal output rOut[N_REGISTERS()];

    // fetch instruction
    // decompose pc into pack index and index in pack
    // size of instructionPackIndex is checked when num2bits
    signal instructionPackIndex;
    signal instructionIndexInPack;
    instructionPackIndex <-- pcIn \ bytesPerInstructionPack;
    instructionIndexInPack <-- (pcIn % bytesPerInstructionPack) \ INSTRUCTION_SIZE_BYTES();
    component insIndexInPackLt = LessThan(3); // ceil(log2(instrutionPackingRatio))
    insIndexInPackLt.in[0] <== instructionIndexInPack;
    insIndexInPackLt.in[1] <== instrutionPackingRatio;
    insIndexInPackLt.out === 1;
    instructionPackIndex * bytesPerInstructionPack + instructionIndexInPack * INSTRUCTION_SIZE_BYTES() === pcIn;

    // merkle check pack
    component instructionPackIndex_bin = Num2Bits(memoryDepth);
    instructionPackIndex_bin.in <== instructionPackIndex;

    component instructionPacker = Pack(instrutionPackingRatio, INSTRUCTION_SIZE_BITS());
    for (var ii = 0; ii < instrutionPackingRatio; ii++) instructionPacker.in[ii] <== instructionPackData[ii];
    component instructionMerkleChecker = MerkleTreeChecker(memoryDepth);
    instructionMerkleChecker.leaf <== instructionPacker.out[0];
    instructionMerkleChecker.root <== mRoot0;
    for (var ii = 0; ii < memoryDepth; ii++) {
        instructionMerkleChecker.pathElements[ii] <== instructionProof[ii];
        instructionMerkleChecker.pathIndices[ii] <== instructionPackIndex_bin.out[ii];
    }

    // fetch instruction from pack
    component instructionIndexInPack_bin = Num2Bits(3);
    instructionIndexInPack_bin.in <== instructionIndexInPack;

    component instructionFetch = Mux3();
    for (var ii = 0; ii < instrutionPackingRatio; ii++) instructionFetch.c[ii] <== instructionPackData[ii];
    instructionFetch.c[instrutionPackingRatio] <== 0;
    for (var ii = 0; ii < 3; ii++) instructionFetch.s[ii] <== instructionIndexInPack_bin.out[ii];

    // decode instruction
    component instruction_bin = Num2Bits(INSTRUCTION_SIZE_BITS());
    instruction_bin.in <== instructionFetch.out;

    component decoder = RV32I_Decoder();
    for (var ii = 0; ii < INSTRUCTION_SIZE_BITS(); ii++) decoder.instruction_bin[ii] <== instruction_bin.out[ii];

    // ...

}
 */

// programSize: number of instructions in program
template VMStep_Tree(memoryDepth, programSize) {

    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input instruction;
    signal input instructionProof[memoryDepth];
    signal input m;
    signal input mProof[memoryDepth];
    signal input mRoot0;
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mRoot1;

    // check instruction merkle proof
    component pcIn_bin = Num2Bits(memoryDepth + 2);
    pcIn_bin.in <== pcIn;
    component instructionMerkleChecker = MerkleTreeChecker(memoryDepth);
    instructionMerkleChecker.leaf <== instruction;
    instructionMerkleChecker.root <== mRoot0;
    
    for (var ii = 0; ii < memoryDepth; ii++) {
        instructionMerkleChecker.pathElements[ii] <== instructionProof[ii];
        instructionMerkleChecker.pathIndices[ii] <== pcIn_bin.out[2 + ii];
    }

    // decode instruction
    component instruction_bin = Num2Bits(INSTRUCTION_SIZE_BITS());
    instruction_bin.in <== instruction;

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

    // parse ks
    component ks = K_Parser();
    for (var ii = 0; ii < INSTRUCTION_TYPE_SIZE(); ii++) ks.instructionType_bin[ii] <== decoder.instructionType_bin[ii];
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) ks.opcode_bin_6_2[ii] <== decoder.opcode_bin_6_2[ii];

    // memory vs alu output
    component newRDValueDecider = NewRDValueDecider();
    newRDValueDecider.aluOut_dec <== alu.out_dec;
    newRDValueDecider.mOut_dec <== m;
    for (var ii = 0; ii < INSTRUCTION_TYPE_SIZE(); ii++) newRDValueDecider.instructionType_bin[ii] <== decoder.instructionType_bin[ii];
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) newRDValueDecider.opcode_bin_6_2[ii] <== decoder.opcode_bin_6_2[ii];

    // store into register
    component rStore = RV32I_Register_Store();
    rStore.in_dec <== newRDValueDecider.out_dec;
    rStore.k <== ks.kR;
    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) rStore.address_bin[ii] <== decoder.rd_bin[ii];
    for (var ii = 0; ii < N_REGISTERS(); ii++) rStore.rIn[ii] <== rIn[ii];
    for (var ii = 0; ii < N_REGISTERS(); ii++) rOut[ii] <== rStore.rOut[ii];

    // compute new mRoot
    component mPointer = MPointer();
    mPointer.rs1Value_dec <== rs1Value_dec;
    mPointer.imm_dec <== decoder.imm_dec;

    /*
    (pathIndices, leaf)
    if loadind, (mPointer, m)
    else if storing, (mPointer, rs2 % 256)
    else (pcIn, instruction)
     */

    component rs2Value_7_0_dec = Bits2Num(M_SLOT_SIZE());
    for (var ii = 0; ii < M_SLOT_SIZE(); ii++) rs2Value_7_0_dec.in[ii] <== rs2Value_bin[ii];
    
    // TODO: abstract cleanly
    component m_rs2Mux = Mux1();
    m_rs2Mux.c[0] <== m;
    m_rs2Mux.c[1] <== rs2Value_7_0_dec.out;
    m_rs2Mux.s <== decoder.opcode_bin_6_2[3];

    component mPathIndices = Num2Bits(memoryDepth);
    mPathIndices.in <== mPointer.out_dec - 3 * programSize * decoder.instructionType_bin[2];

    component mMerkleTree = MerkleTree(memoryDepth);
    mMerkleTree.leaf <== m_rs2Mux.out;

     for (var ii = 0; ii < memoryDepth; ii++) {
        mMerkleTree.pathElements[ii] <== mProof[ii];
        mMerkleTree.pathIndices[ii] <== mPathIndices.out[ii];
    }

    component mRootMux = Mux1();
    mRootMux.c[0] <== mRoot0;
    mRootMux.c[1] <== mMerkleTree.root;
    mRootMux.s <== decoder.instructionType_bin[2];

    mRoot1 <== mRootMux.out;

}

template VMMultiStep_Tree(n, memoryDepth, programSize) {
    
    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input instructions[n];
    signal input instructionProofs[n][memoryDepth];
    signal input ms[n];
    signal input mProofs[n][memoryDepth];
    signal input mRoot0;
    signal output pcOut;
    signal output rOut[N_REGISTERS()];
    signal output mRoot1;

    component steps[n];
    for (var ii = 0; ii < n; ii++) steps[ii] = VMStep_Tree(memoryDepth, programSize);
    
    steps[0].pcIn <== pcIn;
    for (var ii = 0; ii < N_REGISTERS(); ii++) {
        steps[0].rIn[ii] <== rIn[ii];
    }
    steps[0].instruction <== instructions[0];
    steps[0].m <== ms[0];
    for (var ii = 0; ii < memoryDepth; ii++) {
        steps[0].instructionProof[ii] <== instructionProofs[0][ii];
        steps[0].mProof[ii] <== mProofs[0][ii];
    }
    steps[0].mRoot0 <== mRoot0;

    for (var ii = 1; ii < n; ii++) {
        steps[ii].pcIn <== steps[ii - 1].pcOut;
        for (var jj = 0; jj < N_REGISTERS(); jj++) {
            steps[ii].rIn[jj] <== steps[ii - 1].rOut[jj];
        }
        steps[ii].instruction <== instructions[ii];
        steps[ii].m <== ms[ii];
        for (var jj = 0; jj < memoryDepth; jj++) {
            steps[ii].instructionProof[jj] <== instructionProofs[ii][jj];
            steps[ii].mProof[jj] <== mProofs[ii][jj];
        }
        steps[ii].mRoot0 <== steps[ii - 1].mRoot1;
    }

    pcOut <== steps[n - 1].pcOut;
    for (var jj = 0; jj < N_REGISTERS(); jj++) {
        rOut[jj] <== steps[n - 1].rOut[jj];
    }
    mRoot1 <== steps[n - 1].mRoot1;

}

template StateHash_Tree() {
    signal input pc;
    signal input r[N_REGISTERS()];
    signal input mRoot;
    signal output out;

    var n32BitVars = 1 + N_REGISTERS();
    var packingVars32[3] = getPackingVars(n32BitVars, R_SIZE());
    var nPacks32 = packingVars32[1];

    component packs32bits = Pack(n32BitVars, R_SIZE());
    packs32bits.in[0] <== pc;
    for (var ii = 0; ii < N_REGISTERS(); ii++) packs32bits.in[1 + ii] <== r[ii];
    
    component mimc = MiMCSponge(1 + nPacks32, 220, 1);
    for (var ii = 0; ii < nPacks32; ii++) mimc.ins[ii] <== packs32bits.out[ii];
    mimc.ins[nPacks32] <== mRoot;
    mimc.k <== 0;
    out <== mimc.outs[0];

}

template ValidVMMultiStep_Tree(n, memoryDepth, programSize, rangeCheck) {
    signal input pcIn;
    signal input rIn[N_REGISTERS()];
    signal input instructions[n];
    signal input instructionProofs[n][memoryDepth];
    signal input ms[n];
    signal input mProofs[n][memoryDepth];
    signal input mRoot0;
    signal input root0;
    signal input root1;

    // component pcRangeCheck;
    component rRangeCheck;
    component instructionRangeCheck;
    component mRangeCheck;

    if (rangeCheck == 1) {
        // pcRangeCheck = AssertInBitRange(R_SIZE());
        // pcRangeCheck.in <== pcIn;
        rRangeCheck = MultiAssertInBitRange(N_REGISTERS(), R_SIZE());
        for (var ii = 0; ii < N_REGISTERS(); ii++) rRangeCheck.in[ii] <== rIn[ii];
        instructionRangeCheck = MultiAssertInBitRange(n, R_SIZE());
        for (var ii = 0; ii < n; ii++) instructionRangeCheck.in[ii] <== instructions[ii];
        mRangeCheck = MultiAssertInBitRange(n, M_SLOT_SIZE());
        for (var ii = 0; ii < n; ii++) mRangeCheck.in[ii] <== ms[ii];
    }

    component stateHash0 = StateHash_Tree();
    stateHash0.pc <== pcIn;
    for (var ii = 0; ii < N_REGISTERS(); ii++) stateHash0.r[ii] <== rIn[ii];
    stateHash0.mRoot <== mRoot0;

    root0 === stateHash0.out;

    component vm = VMMultiStep_Tree(n, memoryDepth, programSize);
    vm.pcIn <== pcIn;
    for (var ii = 0; ii < N_REGISTERS(); ii++) vm.rIn[ii] <== rIn[ii];
    vm.mRoot0 <== mRoot0;
    for (var ii = 0; ii < n; ii++) {
        vm.instructions[ii] <== instructions[ii];
        vm.ms[ii] <== ms[ii];
        for (var jj = 0; jj < n; jj++) {
            vm.instructionProofs[ii][jj] <== instructionProofs[ii][jj];
            vm.mProofs[ii][jj] <== mProofs[ii][jj];
        }
    }

    component stateHash1 = StateHash_Tree();
    stateHash1.pc <== vm.pcOut;
    for (var ii = 0; ii < N_REGISTERS(); ii++) stateHash1.r[ii] <== vm.rOut[ii];
    stateHash1.mRoot <== vm.mRoot1;

    root1 === stateHash1.out;

}

// component main {public [root0, root1]} = ValidVMMultiStep_Flat(1, 0);
// component main = ValidVMMultiStep_Tree(5, 5, 8, 1);

/**

******** CONSTRAINS ********

ALU         2444
    CompW   2397
    LoadI   1
    Jump    3
    Branch  6

Decoder 13

State   2183
    Memory64_Load1  339  // [!] Most from Num2Bits_soft32
    Memory64_Load4  1356  // [!]
    Memory64_Store1 387 // [!]
    RV32I_Register_Load     39
    RV32I_Register_Store    62

VMStep_Flat     4780
StateHash_Flat  5940

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
