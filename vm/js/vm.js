const { fetchMemory, fetchRegister } = require("./state");
const { decodeRV32I } = require("./decoder");
const {
  zeroExtend,
  signExtend,
  twosCompToSign,
  fitTo32Bits,
} = require("./utils");

// TODO: more constants instead of hard code

function _slt(aa, bb) {
  return twosCompToSign(aa, 32) < twosCompToSign(bb, 32) ? 1 : 0;
}

function _sll(value, shift) {
  // js << is weird
  const value_bin = zeroExtend(value.toString(2), 32);
  return parseInt(value_bin.slice(shift, 32).concat("0".repeat(shift)), 2);
}

function _srl(value) {
  const value_bin = zeroExtend(value.toString(2), 32);
  return parseInt(value_bin.slice(0, 32 - shift), 2);
}

function _sra(value) {
  const value_bin = zeroExtend(value.toString(2), 32);
  return parseInt(signExtend(value_bin.slice(0, 32 - shift), 32), 2);
}

// NOT: doesn't mod 2**32
function compute(instr, aa, bb) {
  const f3_dec = parseInt(instr.f3_bin, 2);
  const f7_iszr = parseInt(instr.f7_bin, 2) == 0;
  if (f3_dec == 0) {
    if (f7_iszr) {
      return aa + bb;
    } else {
      return aa - bb;
    }
  } else if (f3_dec == 1) {
    return _sll(aa, bb);
  } else if (f3_dec == 2) {
    return _slt(aa, bb);
  } else if (f3_dec == 3) {
    return aa < bb ? 1 : 0;
  } else if (f3_dec == 4) {
    return aa ^ bb;
  } else if (f3_dec == 5) {
    if (f7_iszr) {
      return _srl(aa, bb);
    } else {
      return _sra(aa, bb);
    }
  } else if (f3_dec == 6) {
    return aa | bb;
  } else if (f3_dec == 7) {
    return aa & bb;
  }
}

function computeWrapped(instr, rs1Value_dec, rs2Value_dec, pcIn) {
  const aa = rs1Value_dec;
  const bb = instr.opcode_bin_6_2[1] == "1" ? rs2Value_dec : instr.imm_dec;
  const out = fitTo32Bits(compute(instr, aa, bb));
  return {
    out: out,
    pcOut: pcIn + 4,
  };
}

function loadImm(instr, rs1Value_dec, rs2Value_dec, pcIn) {
  let out = instr.imm;
  if (instr.opcode_bin_6_2[1] == "0") {
    out += pcIn;
  }
  return {
    out: out,
    pcOut: pcIn + 4,
  };
}

function jump(instr, rs1Value_dec, rs2Value_dec, pcIn) {
  return {
    out: pcIn + 4,
    pcOut: instr.imm + (instr.opcode_bin_6_2[3] == "0" ? rs1Value_dec : pcIn),
  };
}

function branch(instr, rs1Value_dec, rs2Value_dec, pcIn) {
  const f3_dec = parseInt(instr.f3_bin, 2);
  let branch;
  if (f3_dec == 0) {
    branch = aa == bb;
  } else if (f3_dec == 1) {
    branch = aa != bb;
  } else if (f3_dec == 4) {
    branch = _slt(aa, bb);
  } else if (f3_dec == 5) {
    branch = !_slt(aa, bb);
  } else if (f3_dec == 6) {
    branch = aa < bb;
  } else if (f3_dec == 7) {
    branch = a >= bb;
  } else {
    throw "f7 not valid";
  }
  const pcDelta = branch ? instr.imm : 4;
  return {
    out: null,
    pcOut: pcIn + pcDelta,
  };
}

function alu(instr, rs1Value_dec, rs2Value_dec, pcIn) {
  if (instr.instructionType_bin == "000") {
    return computeWrapped(...arguments);
  } else if (instr.instructionType_bin == "000") {
    return loadImm(...arguments);
  } else if (instr.instructionType_bin == "000") {
    return jump(...arguments);
  } else if (instr.instructionType_bin == "000") {
    return branch(...arguments);
  } else {
    return { pcOut: pcIn + 4, out: null };
  }
}

function step(state) {
  // fetch instruction
  const rawInstr_bin = zeroExtend(
    fetchMemory(state.m, 4, state.pc).toString(2),
    32
  );
  console.log(state.pc + "\t", rawInstr_bin);
  // decode instruction
  const instr = decodeRV32I(rawInstr_bin);
  // load rs and pointer
  const rd_dec = parseInt(instr.rd_bin, 2);
  const rs1_dec = parseInt(instr.rs1_bin, 2);
  const rs2_dec = parseInt(instr.rs2_bin, 2);
  const rs1Value_dec = fetchRegister(state.r, rs1_dec);
  const rs2Value_dec = fetchRegister(state.r, rs2_dec);
  const mPointer = rs1Value_dec + instr.imm_dec;

  const opcodeSlice = instr.opcode_bin_6_2;
  if (opcodeSlice == "01000") {
    // store
    state.m[mPointer] = rs2Value_dec % 256;
    state.pc += 4;
    return;
  } else if (opcodeSlice == "00000") {
    // load
    out = fetchMemory(state.m, 1, mPointer);
    state.pc += 4;
  } else {
    // not load/store
    const [out, pcOut] = alu(instr, rs1Value_dec, rs2Value_dec, state.pc);
    state.pc = pcOut;
  }

  if (opcodeSlice != "11000" && rd_dec > 0) {
    // set rd
    state.r[rd_dec - 1] = out;
  }
}

function multiStep(state, steps) {
  for (let ii = 0; ii < steps; ii++) {
    step(state);
  }
}

module.exports = {
  step,
  alu,
  multiStep,
};
