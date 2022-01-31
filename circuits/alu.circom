pragma circom 2.0.2;

// include "./utils.circom";

template Computator() {
    signal input instructionType_bin;
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input f3_bin[F3_SIZE()];
    signal input f7_bin[F7_SIZE()];
    signal input rs1_value_bin[R_SIZE()];
    signal input rs2_value_bin[R_SIZE()];
    signal input imm_dec;

    component immDecider = ImmDecider();
    immDecider.r <== rs2_value_bin;

}

template ALU() {
    signal input pcIn_dec;
    signal input instructionType_bin[INSTR_TYPE_SIZE()];
    signal input opcode_bin_6_2[OPCODE_6_2_SIZE()];
    signal input f3_bin[F3_SIZE()];
    signal input f7_bin[F7_SIZE()];
    signal input rs1_value_dec[R_SIZE()];
    signal input rs2_value_dec[R_SIZE()];
    signal input imm_dec;
    signal output out_dec;
    signal output pcOut_dec;
}