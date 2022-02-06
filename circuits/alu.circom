pragma circom 2.0.2;

include "./constants.circom";

template Computator() {
    signal input instructionType_bin;
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input f3_bin[F3_SIZE()];
    signal input f7_bin[F7_SIZE()];
    signal input rs1Value_bin[R_ADDRESS_SIZE()]; // TODO; use r size, not r addr size!
    signal input rs2Value_bin[R_ADDRESS_SIZE()];
    signal input imm_dec;
}

template ALU() {
    signal input pcIn_dec;
    signal input instructionType_bin[INSTRUCTION_TYPE_SIZE()];
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input f3_bin[F3_SIZE()];
    signal input f7_bin[F7_SIZE()];
    signal input rs1Value_dec;
    signal input rs2Value_dec;
    signal input imm_dec;
    signal output out_dec;
    signal output pcOut_dec;
    out_dec <== 0;
    pcOut_dec <== pcIn_dec + 4;
}