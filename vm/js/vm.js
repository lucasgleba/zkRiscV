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
  shift = shift % 32;
  // js << is weird
  const value_bin = zeroExtend(value.toString(2), 32);
  return parseInt(value_bin.slice(shift, 32).concat("0".repeat(shift)), 2);
}

function _srl(value, shift) {
  shift = shift % 32;
  const value_bin = zeroExtend(value.toString(2), 32);
  return parseInt(value_bin.slice(0, 32 - shift), 2);
}

function _sra(value, shift) {
  shift = shift % 32;
  const value_bin = zeroExtend(value.toString(2), 32);
  return parseInt(signExtend(value_bin.slice(0, 32 - shift), 32), 2);
}

// NOT: doesn't mod 2**32
function compute(instr, aa, bb) {
  const f3_dec = parseInt(instr.f3_bin, 2);
  const f7_iszr = parseInt(instr.f7_bin, 2) == 0;
  const usingImm = instr.opcode_bin_6_2[1] == "0";
  if (f3_dec == 0) {
    if (f7_iszr || usingImm) {
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
  let out = instr.imm_dec;
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
    pcOut:
      instr.imm_dec + (instr.opcode_bin_6_2[3] == "0" ? rs1Value_dec : pcIn),
  };
}

function branch(instr, rs1Value_dec, rs2Value_dec, pcIn) {
  const f3_dec = parseInt(instr.f3_bin, 2);
  let branch;
  if (f3_dec == 0) {
    branch = rs1Value_dec == rs2Value_dec;
  } else if (f3_dec == 1) {
    branch = rs1Value_dec != rs2Value_dec;
  } else if (f3_dec == 4) {
    branch = _slt(rs1Value_dec, rs2Value_dec);
  } else if (f3_dec == 5) {
    branch = !_slt(rs1Value_dec, rs2Value_dec);
  } else if (f3_dec == 6) {
    branch = rs1Value_dec < rs2Value_dec;
  } else if (f3_dec == 7) {
    branch = rs1Value_dec >= rs2Value_dec;
  } else {
    throw "f7 not valid";
  }
  const pcDelta = branch ? instr.imm_dec : 4;
  return {
    out: 0,
    pcOut: pcIn + pcDelta,
  };
}

function alu(instr, rs1Value_dec, rs2Value_dec, pcIn) {
  if (instr.instructionType_bin == "000") {
    return computeWrapped(...arguments);
  } else if (instr.instructionType_bin == "001") {
    return loadImm(...arguments);
  } else if (instr.instructionType_bin == "010") {
    return jump(...arguments);
  } else if (instr.instructionType_bin == "011") {
    return branch(...arguments);
  } else {
    return { pcOut: pcIn + 4, out: 0 };
  }
}

function step_flat(state) {
  // fetch instruction
  const rawInstr_bin = zeroExtend(
    fetchMemory(state.m, 4, state.pc).toString(2),
    32
  );
  // console.log(state.pc + "\t" + rawInstr_bin);
  // decode instruction
  const instr = decodeRV32I(rawInstr_bin);
  // load rs and pointer
  const rd_dec = parseInt(instr.rd_bin, 2);
  const rs1_dec = parseInt(instr.rs1_bin, 2);
  const rs2_dec = parseInt(instr.rs2_bin, 2);
  const rs1Value_dec = fetchRegister(state.r, rs1_dec);
  const rs2Value_dec = fetchRegister(state.r, rs2_dec);
  const mPointer = rs1Value_dec + instr.imm_dec;

  // console.log("instr", instr);
  // console.log("rs1Value_dec", rs1Value_dec);
  // console.log("rs2Value_dec", rs2Value_dec);
  // console.log("mPointer", mPointer);
  // console.log(state.r);

  let out;

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
    const aluOut = alu(instr, rs1Value_dec, rs2Value_dec, state.pc);
    out = aluOut.out;
    state.pc = aluOut.pcOut;
  }

  if (opcodeSlice != "11000" && rd_dec > 0) {
    // set rd
    state.r[rd_dec - 1] = out;
  }
}

function multiStep_flat(state, steps) {
  for (let ii = 0; ii < steps; ii++) {
    step_flat(state);
  }
}

function step_tree(state, meta) {
  // fetch instruction
  const instrPointerAdj = state.pc / 4;
  const rawInstr_dec = state.mTree._layers[0][instrPointerAdj];
  const instrProof = state.mTree.path(instrPointerAdj).pathElements;
  const rawInstr_bin = zeroExtend(rawInstr_dec.toString(2), 32);
  // decode instruction
  const instr = decodeRV32I(rawInstr_bin);
  // load rs and pointer
  const rd_dec = parseInt(instr.rd_bin, 2);
  const rs1_dec = parseInt(instr.rs1_bin, 2);
  const rs2_dec = parseInt(instr.rs2_bin, 2);
  const rs1Value_dec = fetchRegister(state.r, rs1_dec);
  const rs2Value_dec = fetchRegister(state.r, rs2_dec);
  const mPointerAdj = rs1Value_dec + instr.imm_dec - 3 * meta.programSize;

  let out, m, mProof;
  const getMProof = () => state.mTree.path(mPointerAdj).pathElements;

  const opcodeSlice = instr.opcode_bin_6_2;
  if (opcodeSlice == "01000") {
    // store
    m = rs2Value_dec % 256;
    mProof = getMProof();
    state.mTree.update(mPointerAdj, m);
    state.pc += 4;
  } else if (opcodeSlice == "00000") {
    // load
    out = state.mTree._layers[0][mPointerAdj];
    m = out;
    mProof = getMProof();
    state.pc += 4;
  } else {
    // not load/store
    m = rawInstr_dec;
    mProof = instrProof;
    const aluOut = alu(instr, rs1Value_dec, rs2Value_dec, state.pc);
    out = aluOut.out;
    state.pc = aluOut.pcOut;
  }

  if (opcodeSlice != "11000" && opcodeSlice != "01000" && rd_dec > 0) {
    // set rd
    state.r[rd_dec - 1] = out;
  }

  return {
    m, mProof, instruction: rawInstr_dec, instructionProof: instrProof,
  }
}

function multiStep_tree(state, meta, steps) {
  const helpers = {
    ms: [],
    mProofs: [],
    instructions: [],
    instructionProofs: [],
  }
  for (let ii = 0; ii < steps; ii++) {
    const helperData = step_tree(state, meta);
    helpers.ms.push(helperData.m);
    helpers.mProofs.push(helperData.mProof);
    helpers.instructions.push(helperData.instruction);
    helpers.instructionProofs.push(helperData.instructionProof);
  }
  return helpers;
}

module.exports = {
  step_flat,
  multiStep_flat,
  step_tree,
  multiStep_tree,
  alu,
  computeWrapped,
  jump,
  loadImm,
  branch,
};
