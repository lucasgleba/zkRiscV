const { fetchMemory, fetchRegister } = require("./state");
const { decodeRV32I } = require("./decoder");
const { zeroExtend } = require("./utils");

const PROGRAM_START = 0;
const PROGRAM_END = 64;
const DATA_START = PROGRAM_END;
const DATA_END = 128;

// TODO: more constants instead of hard code

function compute(pc) {
  return {
    pc: pc + 4,
    out: 0,
  };
}

function step(state) {
  // fetch instruction
  const rawInstr_bin = zeroExtend(
    fetchMemory(state.m, 4, state.pc).toString(2),
    32
  );
  console.log(rawInstr_bin);
  // decode instruction
  const instr = decodeRV32I(rawInstr_bin);
  // load rs
  const rd_dec = parseInt(instr.rd_bin, 2);
  const rs1_dec = parseInt(instr.rs1_bin, 2);
  const rs2_dec = parseInt(instr.rs2_bin, 2);
  const rs1Value_dec = fetchRegister(state.r, rs1_dec);
  const rs2Value_dec = fetchRegister(state.r, rs2_dec);
  // compute
  let { out, pc } = compute(state.pc);
  state.pc = pc;
  // load m
  const mPointer = rs1Value_dec + instr.imm_dec;
  const mLoaded_dec = fetchMemory(state.m, mPointer);
  // set m/r
  const opcodeSlice = instr.opcode_bin_6_2;
  if (opcodeSlice == "01000") {
    state.m[mPointer] = rs2Value_dec % 256;
    return;
  } else if (opcodeSlice == "00000") {
    out = mLoaded_dec;
  } else if (opcodeSlice == "11000") {
    return;
  }

  state.r[rd_dec] = out;
}

module.exports = {
  step,
  compute,
};
