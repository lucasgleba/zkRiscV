pragma circom 2.0.2;

function INSTRUCTION_SIZE_BYTES() {
    return 4;
}

function INSTRUCTION_SIZE_BITS() {
    return INSTRUCTION_SIZE_BYTES() * 8;
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

function INSTR_TYPE_SIZE() {
    return 3;
}

// =====

function M_SLOT_SIZE() {
    return 8;
}

function N_REGISTERS() {
    // General purpose register that store data (i.e., excluding r0)
    return 31;
}

function R_ADDRESS_SIZE() {
    return 5;
}
