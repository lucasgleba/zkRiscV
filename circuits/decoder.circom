var INSTRUCTION_SIZE = 32;

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

template FMT_Parser() {
    signal input opcode_bin_6_2[5];
    signal output fmt;
}

template F_Parser() {
    signal input instruction_bin[INSTRUCTION_SIZE];
    // signal output f3_bin[3];
    signal output f3_dec;
    signal output f7_bin[7];
    // signal output f7_dec;
}

template Opcode_Parser() {
    signal input instruction_bin[INSTRUCTION_SIZE];
    signal output opcode_bin_6_2[5];
}

template RV32I_Decoder() {
    signal input instruction_dec;
    signal output instructionType_dec;
    // signal output f3_bin[3];
    signal output f3_dec;
    signal output f7_bin[7];
    // signal output f7_dec;
    signal output epsilon_dec;

    // instruciton to binary
    component instruction_bin = Num2Bits(32);
    instruction_bin.in <== instruction_dec;

    // get opcode 6:2 and Fs
    component opcode_bin_6_2 = Opcode_Parser();
    component F = F_Parser();
    for (var ii = 0; ii < INSTRUCTION_SIZE; ii++) {
        opcode_bin_6_2.instruction_bin[ii] <== instruction_bin[ii];
        F.instruction_bin[ii] <== instruction_bin[ii];
    }

    f3_dec <== F.f3_dec;
    for (var ii = 0; ii < 3; ii++) f7_bin[ii] <== F.f7_bin[ii];

    // get instruction format and type
    component FMT = FMT_Parser();
    for (var ii = 0; ii < 5; ii++) {
        FMT.instruction_bin[ii] <== opcode_bin_6_2[ii];
    }

}