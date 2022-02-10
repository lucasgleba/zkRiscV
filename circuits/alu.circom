pragma circom 2.0.2;

include "./constants.circom";
include "./lib/gates.circom";
include "./lib/shifter.circom";
include "../node_modules/circomlib/circuits/mux2.circom";
include "../node_modules/circomlib/circuits/mux3.circom";

// TODO: look at actual cpu designs for optimization inspo

/*
binary-binary
xor
or
and

decimal-decimal
add
sub?
shift left
shift right logical
shift right arithmetic
set less than
set less than u

100
110
111

 */

template Computator() {
    signal input a_bin[R_SIZE()];
    signal input b_bin[R_SIZE()];
    signal input a_dec;
    signal input b_dec;
    signal input f3_bin[F3_SIZE()];
    signal input f7_bin[F7_SIZE()];
    signal output out_dec;
    // signal output pcOut_dec;
    signal output sub;
    signal output slt;
    signal output sltu;

    // add, sub
    component add_subMux = Mux1();
    add_subMux.c[0] <== a_dec + b_dec;
    add_subMux.c[1] <== 2 ** R_SIZE() + a_dec - b_dec;
    add_subMux.s <== f7_bin[5];

    // TODO: do isz directly, instead [?]
    sub <== a_dec - b_dec;

    // xor, or, and
    component or = BitwiseOR(R_SIZE());
    component xor = BitwiseXOR(R_SIZE());
    component and = BitwiseAND(R_SIZE());
    for (var ii = 0; ii < R_SIZE(); ii++) {
        or.in[0][ii] <== a_bin[ii];
        or.in[1][ii] <== b_bin[ii];
        xor.in[0][ii] <== a_bin[ii];
        xor.in[1][ii] <== b_bin[ii];
        and.in[0][ii] <== a_bin[ii];
        and.in[1][ii] <== b_bin[ii];
    }
    component xor_orMux = MultiMux1(R_SIZE());
    component xoror_andMux = MultiMux1(R_SIZE());
    xor_orMux.s <== f3_bin[1];
    xoror_andMux.s <== f3_bin[0];
    for (var ii = 0; ii < R_SIZE(); ii++) {
        xor_orMux.c[ii][0] <== xor.out[ii];
        xor_orMux.c[ii][1] <== or.out[ii];
    }
    for (var ii = 0; ii < R_SIZE(); ii++) {
        xoror_andMux.c[ii][0] <== xor_orMux.out[ii];
        xoror_andMux.c[ii][1] <== and.out[ii];
    }
    component bitOp = Bits2Num(R_SIZE());
    for (var ii = 0; ii < R_SIZE(); ii++) bitOp.in[ii] <== xoror_andMux.out[ii];

    // sll, sra, slt
    component shiftLeft = VariableShift32(R_SIZE(), 0);
    component shiftRight = VariableShift32(R_SIZE(), 1);
    shiftLeft.k <== 0;
    shiftRight.k <== f7_bin[5] * a_bin[R_SIZE() - 1];
    shiftLeft.in <== a_dec;
    shiftRight.in <== a_dec;
    for (var ii = 0; ii < R_ADDRESS_SIZE(); ii++) {
        shiftLeft.shift[ii] <== b_bin[ii];
        shiftRight.shift[ii] <== b_bin[ii];
    }

    // slt, sltu
    component lt = LessThan(R_SIZE());
    lt.in[0] <== a_dec;
    lt.in[1] <== b_dec;
    component signXor = XOR();
    signXor.a <== a_bin[R_SIZE() - 1];
    signXor.b <== b_bin[R_SIZE() - 1];
    component ltMux = Mux1();
    ltMux.c[0] <== lt.out;
    ltMux.c[1] <== a_bin[R_SIZE() - 1];
    ltMux.s <== signXor.out;

    slt <== ltMux.out;
    sltu <== lt.out;

    // mux
    component mainMux = Mux3();
    mainMux.c[0] <== add_subMux.out;
    mainMux.c[1] <== shiftLeft.out;
    mainMux.c[2] <== ltMux.out;
    mainMux.c[3] <== lt.out;
    mainMux.c[4] <== bitOp.out;
    mainMux.c[5] <== shiftRight.out;
    mainMux.c[6] <== bitOp.out;
    mainMux.c[7] <== bitOp.out;
    for (var ii = 0; ii < F3_SIZE(); ii++) mainMux.s[ii] <== f3_bin[ii];

}

template ComputatorWrapped() {
    signal input instructionType_bin[INSTRUCTION_TYPE_SIZE()];
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input f3_bin[F3_SIZE()];
    signal input f7_bin[F7_SIZE()];
    signal input rs1Value_bin[R_SIZE()];
    signal input rs2Value_bin[R_SIZE()];
    signal input rs1Value_dec;
    signal input rs2Value_dec;
    signal input imm_dec;
    signal input pcIn_dec;
    signal output out_dec;
    signal output pcOut_dec;
    signal output sub;
    signal output slt;
    signal output sltu;

    pcOut_dec <== pcIn_dec + 4;

    component imm_bin = Num2Bits(R_SIZE());
    imm_bin.in <== imm_dec;

    // TODO: always use rs2 if branching
    component bMux = MultiMux1(R_SIZE() + 1);
    bMux.c[0][0] <== imm_dec;
    bMux.c[0][1] <== rs2Value_dec;
    for (var ii = 0; ii < R_SIZE(); ii++) {
        bMux.c[ii + 1][0] <== imm_bin.out[ii];
        bMux.c[ii + 1][1] <== rs2Value_bin[ii];
    }
    component bOR = OR();
    bOR.a <== instructionType_bin[0];
    bOR.b <== instructionType_bin[2];
    bMux.s <== bOR.out;

    component computator = Computator();

    for (var ii = 0; ii < R_SIZE(); ii++) {
        computator.a_bin[ii] <== rs1Value_bin[ii];
        computator.b_bin[ii] <== bMux.out[ii + 1];
    }

    computator.a_dec <== rs1Value_dec;
    computator.b_dec <== bMux.out[0];

    for (var ii = 0; ii < F3_SIZE(); ii++) computator.f3_bin[ii] <== f3_bin[ii];
    for (var ii = 0; ii < F7_SIZE(); ii++) computator.f7_bin[ii] <== f7_bin[ii];

    out_dec <== computator.out_dec;

}

template LoadImm() {
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input imm_dec;
    signal input pcIn_dec;
    signal output out_dec;
    signal output pcOut_dec;

    pcOut_dec <== pcIn_dec + 4;
    out_dec <== imm_dec + pcIn_dec * (1 - opcode_bin_6_2[3]);
}

template Jump() {
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input rs1Value_dec;
    signal input imm_dec;
    signal input pcIn_dec;
    signal output out_dec;
    signal output pcOut_dec;

    out_dec <== pcIn_dec + 4;

    component mux = Mux1();
    mux.c[0] <== rs1Value_dec;
    mux.c[1] <== pcIn_dec;
    mux.s <== opcode_bin_6_2[1];

    pcOut_dec <== imm_dec + mux.out;
}

/*
000
001
100
101
110
111
*/

template Branch() {
    // signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input f3_bin[F3_SIZE()];
    // signal input f7_bin[F7_SIZE()];
    // signal input rs1Value_bin[R_SIZE()];
    // signal input rs2Value_bin[R_SIZE()];
    // signal input rs1Value_dec;
    // signal input rs2Value_dec;
    signal input imm_dec;
    signal input pcIn_dec;
    signal input sub;
    signal input slt;
    signal input sltu;
    // signal output out_dec;
    signal output pcOut_dec;

    component isz = IsZero();
    isz.in <== sub;

    component slt_sltuMux = Mux1();
    slt_sltuMux.c[0] <== slt;
    slt_sltuMux.c[1] <== sltu;
    slt_sltuMux.s <== f3_bin[1];
    component isz_sltsltuMux = Mux1();
    isz_sltsltuMux.c[0] <== isz.out;
    isz_sltsltuMux.c[1] <== slt_sltuMux.out;
    isz_sltsltuMux.s <== f3_bin[2];

    component xor = XOR();
    xor.a <== isz_sltsltuMux.out;
    xor.b <== f3_bin[0];

    component mux = Mux1();
    mux.c[0] <== 4;
    mux.c[1] <== imm_dec;
    mux.s <== xor.out;

    pcOut_dec <== pcIn_dec + mux.out;

}

template ALU() {
    signal input pcIn_dec;
    signal input instructionType_bin[INSTRUCTION_TYPE_SIZE()];
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input f3_bin[F3_SIZE()];
    signal input f7_bin[F7_SIZE()];
    signal input rs1Value_bin[R_SIZE()];
    signal input rs2Value_bin[R_SIZE()];
    signal input rs1Value_dec;
    signal input rs2Value_dec;
    signal input imm_dec;
    signal output out_dec;
    signal output pcOut_dec;

    component computator = ComputatorWrapped();
    component loadImm = LoadImm();
    component jump = Jump();
    component branch = Branch();

    for (var ii = 0; ii < INSTRUCTION_TYPE_SIZE(); ii++) {
        computator.instructionType_bin[ii] <== instructionType_bin[ii];
    }
    
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) {
        computator.opcode_bin_6_2[ii] <== opcode_bin_6_2[ii];
        loadImm.opcode_bin_6_2[ii] <== opcode_bin_6_2[ii];
        jump.opcode_bin_6_2[ii] <== opcode_bin_6_2[ii];
    }

    for (var ii = 0; ii < F3_SIZE(); ii++) {
        computator.f3_bin[ii] <== f3_bin[ii];
        branch.f3_bin[ii] <== f3_bin[ii];
    }
    
    for (var ii = 0; ii < F7_SIZE(); ii++) {
        computator.f7_bin[ii] <== f7_bin[ii];
    }

    for (var ii = 0; ii < R_SIZE(); ii++) {
        computator.rs1Value_bin[ii] <== rs1Value_bin[ii];
        computator.rs2Value_bin[ii] <== rs2Value_bin[ii];
    }

    computator.rs1Value_dec <== rs1Value_dec;
    computator.rs2Value_dec <== rs2Value_dec;
    jump.rs1Value_dec <== rs1Value_dec;

    computator.imm_dec <== imm_dec;
    loadImm.imm_dec <== imm_dec;
    jump.imm_dec <== imm_dec;
    branch.imm_dec <== imm_dec;
    
    computator.pcIn_dec <== pcIn_dec;
    loadImm.pcIn_dec <== pcIn_dec;
    jump.pcIn_dec <== pcIn_dec;
    branch.pcIn_dec <== pcIn_dec;

    branch.sub <== computator.sub;
    branch.slt <== computator.slt;
    branch.sltu <== computator.sltu;

    component mainMux = MultiMux2(2);
    // comp
    mainMux.c[0][0] <== computator.out_dec;
    mainMux.c[1][0] <== computator.pcOut_dec;
    // loadi
    mainMux.c[0][1] <== loadImm.out_dec;
    mainMux.c[1][1] <== loadImm.pcOut_dec;
    // jump
    mainMux.c[0][2] <== jump.out_dec;
    mainMux.c[1][2] <== jump.pcOut_dec;
    // comp
    mainMux.c[0][3] <== 0;
    mainMux.c[1][3] <== branch.pcOut_dec;

    for (var ii = 0; ii < 2; ii++) mainMux.s[ii] <== instructionType_bin[ii];

    pcOut_dec <== mainMux.out[1];

    // TODO: replace shift by bitfit template [?]
    component bitfit = RightShift(R_SIZE(), R_SIZE());
    bitfit.in <== mainMux.out[0];
    bitfit.k <== 0;
    out_dec <== bitfit.rem;
}

// component main = ALU();