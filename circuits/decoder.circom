pragma circom 2.0.2;

include "./utils.circom";

include "../node_modules/circomlib/circuits/mux1.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

function INSTRUCTION_SIZE() {
    return 32;
}

function INSTR_TYPE_SIZE() {
    return 3;
}

function OPCODE_6_2_SIZE() {
    return 5;
}

function F3_SIZE() {
    return 3;
}

function F7_SIZE() {
    return 7;
}

function R_SIZE() {
    return 5;
}

template Opcode_Parser() {
    signal input instruction_bin[INSTRUCTION_SIZE()];
    signal output opcode_bin_6_2[OPCODE_6_2_SIZE()];

    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) {
        opcode_bin_6_2[ii] <== instruction_bin[ii + 2];
    }
}

template F_Parser() {
    signal input instruction_bin[INSTRUCTION_SIZE()];
    signal output f3_bin[F3_SIZE()];
    signal output f7_bin[F7_SIZE()];

    for (var ii = 0; ii < F3_SIZE(); ii++) {
        f3_bin[ii] <== instruction_bin[ii + 12];
    }
    
    for (var ii = 0; ii < F7_SIZE(); ii++) {
        f7_bin[ii] <== instruction_bin[ii + 25];
    }
}

template R_Parser() {
    signal input instruction_bin[INSTRUCTION_SIZE()];
    signal output rs1_bin[R_SIZE()];
    signal output rs2_bin[R_SIZE()];
    signal output rd_bin[R_SIZE()];

    for (var ii = 0; ii < R_SIZE(); ii++) {
        rs1_bin[ii] <== instruction_bin[ii + 15];
        rs2_bin[ii] <== instruction_bin[ii + 20];
        rd_bin[ii] <== instruction_bin[ii + 7];
    }
}

/**
FMTs = {
    0: R,
    1: I,
    2: S,
    3: B,
    4: U,
    5: J,
}
 */

/**
01100 compute      r
00100 compute      i
00000 store/load   i
01000 store/load   s
11000 branch       b
11011 jump         j
11001 jump         i
01101 loadi        u
00101 loadi        u

01100 compute      r
00100 compute      i

00000 store/load   i
01000 store/load   s

01101 loadi        u
00101 loadi        u

11000 branch       b
11001 jump         i

11011 jump         j
*/

template Imm_Parser() {
    signal input instruction_bin[INSTRUCTION_SIZE()];
    signal output r_dec;
    signal output i_dec;
    signal output s_dec;
    signal output b_dec;
    signal output u_dec;
    signal output j_dec;

    // TODO: optimize [?]
    r_dec <== 0;
    component imm_31_20 = Bits2Num(12);
    component imm_31_25__11_7 = Bits2Num(12);
    component imm_31_12 = Bits2Num(20);

    for (var ii = 0; ii < 12; ii++) imm_31_20.in[ii] <== instruction_bin[ii + 20];
    for (var ii = 0; ii < 5; ii++) imm_31_25__11_7.in[ii] <== instruction_bin[ii + 7];
    for (var ii = 0; ii < 7; ii++) imm_31_25__11_7.in[ii + 5] <== instruction_bin[ii + 25];
    for (var ii = 0; ii < 20; ii++) imm_31_12.in[ii] <== instruction_bin[ii + 12];

    i_dec <== imm_31_20.out + signExtension(12, 32) * instruction_bin[0];
    s_dec <== imm_31_25__11_7.out + signExtension(12, 32) * instruction_bin[0];
    b_dec <== imm_31_25__11_7.out * 2 + signExtension(13, 32) * instruction_bin[0];
    u_dec <== imm_31_12.out * 2 ** 12;
    j_dec <== imm_31_12.out + signExtension(20, 32) * instruction_bin[0];

}

template Type_and_Imm_Parser() {
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input instruction_bin[INSTRUCTION_SIZE()];
    signal output instructionType_bin[INSTR_TYPE_SIZE()];
    signal output imm_dec;

    component imm = Imm_Parser();
    for (var ii = 0; ii < INSTRUCTION_SIZE(); ii++) imm.instruction_bin[ii] <== instruction_bin[ii];

    var muxSize = 2;

    component i_bMux = MultiMux1(muxSize);
    component r_iMux = MultiMux1(muxSize);
    component s_iMux = MultiMux1(muxSize);
    component ri_siMux = MultiMux1(muxSize);
    component u_risiMux = MultiMux1(muxSize);
    component ib_urisiMux = MultiMux1(muxSize);
    component j_iburisiMux = MultiMux1(muxSize);

    i_bMux.s <== opcode_bin_6_2[0];
    u_risiMux.s <== opcode_bin_6_2[0];
    j_iburisiMux.s <== opcode_bin_6_2[1];
    ri_siMux.s <== opcode_bin_6_2[2];
    r_iMux.s <== opcode_bin_6_2[3];
    s_iMux.s <== opcode_bin_6_2[3];
    ib_urisiMux.s <== opcode_bin_6_2[4];

    i_bMux.c[0][0] <== 3;
    i_bMux.c[1][0] <== imm.b_dec;
    i_bMux.c[0][1] <== 2;
    i_bMux.c[1][1] <== imm.i_dec;

    r_iMux.c[0][0] <== 0;
    r_iMux.c[1][0] <== imm.i_dec;
    r_iMux.c[0][1] <== 0;
    r_iMux.c[1][1] <== imm.r_dec;

    s_iMux.c[0][0] <== 4;
    s_iMux.c[1][0] <== imm.i_dec;
    s_iMux.c[0][1] <== 4;
    s_iMux.c[1][1] <== imm.s_dec;

    ri_siMux.c[0][0] <== r_iMux.out[0];
    ri_siMux.c[1][0] <== r_iMux.out[1];
    ri_siMux.c[0][1] <== s_iMux.out[0];
    ri_siMux.c[1][1] <== s_iMux.out[1];

    u_risiMux.c[0][0] <== ri_siMux.out[0];
    u_risiMux.c[1][0] <== ri_siMux.out[1];
    u_risiMux.c[0][1] <== 1;    
    u_risiMux.c[1][1] <== imm.u_dec;

    ib_urisiMux.c[0][0] <== i_bMux.out[0];
    ib_urisiMux.c[1][0] <== i_bMux.out[1];
    ib_urisiMux.c[0][1] <== u_risiMux.out[0];
    ib_urisiMux.c[1][1] <== u_risiMux.out[1];

    j_iburisiMux.c[0][0] <== ib_urisiMux.out[0];
    j_iburisiMux.c[1][0] <== ib_urisiMux.out[1];
    j_iburisiMux.c[0][1] <== 2;
    j_iburisiMux.c[1][1] <== imm.j_dec;
    
    component instructionType = Num2Bits(INSTR_TYPE_SIZE());
    instructionType.in <== j_iburisiMux.out[0];
    for (var ii = 0; ii < INSTR_TYPE_SIZE(); ii++) instructionType_bin[ii] <== instructionType.out[ii];

    imm_dec <== j_iburisiMux.out[1];

}

template RV32I_Decoder() {
    signal input instruction_bin[INSTRUCTION_SIZE()];
    signal output instructionType_bin[INSTR_TYPE_SIZE()];
    signal output opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal output f3_bin[F3_SIZE()];
    signal output f7_bin[F7_SIZE()];
    signal output rs1_bin[R_SIZE()];
    signal output rs2_bin[R_SIZE()];
    signal output rd_bin[R_SIZE()];
    signal output imm_dec;

    // get opcode 6:2, Fs, Rs
    component opcode_6_2 = Opcode_Parser();
    component F = F_Parser();
    component R = R_Parser();
    for (var ii = 0; ii < INSTRUCTION_SIZE(); ii++) {
        opcode_6_2.instruction_bin[ii] <== instruction_bin[ii];
        F.instruction_bin[ii] <== instruction_bin[ii];
        R.instruction_bin[ii] <== instruction_bin[ii];
    }

    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) opcode_bin_6_2[ii] <== opcode_6_2.opcode_bin_6_2[ii];
    for (var ii = 0; ii < F3_SIZE(); ii++) f3_bin[ii] <== F.f3_bin[ii];
    for (var ii = 0; ii < F7_SIZE(); ii++) f7_bin[ii] <== F.f7_bin[ii];

    for (var ii = 0; ii < R_SIZE(); ii++) rs1_bin[ii] <== R.rs1_bin[ii];
    for (var ii = 0; ii < R_SIZE(); ii++) rs2_bin[ii] <== R.rs2_bin[ii];
    for (var ii = 0; ii < R_SIZE(); ii++) rd_bin[ii] <== R.rd_bin[ii];

    // get instruction type and imm
    component type_and_imm = Type_and_Imm_Parser();
    for (var ii = 0; ii < OPCODE_6_2_SIZE(); ii++) type_and_imm.opcode_bin_6_2[ii] <== opcode_bin_6_2[ii];
    for (var ii = 0; ii < INSTRUCTION_SIZE(); ii++) type_and_imm.instruction_bin[ii] <== instruction_bin[ii];
    for (var ii = 0; ii < INSTR_TYPE_SIZE(); ii++) instructionType_bin[ii] <== type_and_imm.instructionType_bin[ii];
    imm_dec <== type_and_imm.imm_dec;

}

component main = RV32I_Decoder();