const { sliceBin, signExtend, zeroExtend } = require("./utils");

// function parseImm(instruction_bin) {
//   const imm_31_20 = sliceBin(instruction_bin, 20, 32);
//   const imm_31_25__11_7 = sliceBin(instruction_bin, 25, 32).concat(
//     sliceBin(instruction_bin, 7, 12)
//   );
//   const imm_31_12 = sliceBin(instruction_bin, 12, 32);

//   const r_bin = 0;
//   const i_bin = signExtend(imm_31_20, 32);
//   const s_bin = signExtend(imm_31_25__11_7, 32);
//   const b_bin = signExtend(imm_31_25__11_7.concat("0"), 32);
//   const u_bin = imm_31_12.concat("0".repeat(12));
//   const j_bin = signExtend(imm_31_12, 32);

//   return {
//     r_bin,
//     i_bin,
//     s_bin,
//     b_bin,
//     u_bin,
//     j_bin,
//   };
// }

const Imm = {
  raw: {
    imm_31_20: (instruction_bin) => sliceBin(instruction_bin, 20, 32),
    imm_31_25__11_7: (instruction_bin) =>
      sliceBin(instruction_bin, 25, 32).concat(
        sliceBin(instruction_bin, 7, 12)
      ),
    imm_31_12: (instruction_bin) => sliceBin(instruction_bin, 12, 32),
  },
  full: {
    r_bin: (instruction_bin) => 0,
    i_bin: (instruction_bin) =>
      signExtend(Imm.raw.imm_31_20(instruction_bin), 32),
    s_bin: (instruction_bin) =>
      signExtend(Imm.raw.imm_31_25__11_7(instruction_bin), 32),
    b_bin: (instruction_bin) =>
      signExtend(Imm.raw.imm_31_25__11_7(instruction_bin).concat("0"), 32),
    u_bin: (instruction_bin) =>
      Imm.raw.imm_31_12(instruction_bin).concat("0".repeat(12)),
    j_bin: (instruction_bin) =>
      signExtend(Imm.raw.imm_31_12(instruction_bin), 32),
  },
};

const opcodeMap = {
  ".01100": [0, Imm.full.r_bin],
  ".00100": [0, Imm.full.i_bin],
  ".00000": [4, Imm.full.i_bin],
  ".01000": [4, Imm.full.s_bin],
  ".11000": [3, Imm.full.b_bin],
  ".11011": [2, Imm.full.j_bin],
  ".11001": [2, Imm.full.i_bin],
  ".01101": [1, Imm.full.u_bin],
  ".00101": [1, Imm.full.u_bin],
};

function decodeRV32I(instruction_bin) {

  if (instruction_bin.length != 32) {
    throw "instruction_bin.length != 32";
  }

  const opcode_bin_6_2 = sliceBin(instruction_bin, 2, 7);
  const f3_bin = sliceBin(instruction_bin, 12, 15);
  const f7_bin = sliceBin(instruction_bin, 25, 32);
  const rs1_bin = sliceBin(instruction_bin, 15, 20);
  const rs2_bin = sliceBin(instruction_bin, 20, 25);
  const rd_bin = sliceBin(instruction_bin, 7, 12);

  const [instructionType_dec, imm_bin_parse] =
    opcodeMap[".".concat(opcode_bin_6_2)];
  const imm_bin = imm_bin_parse(instruction_bin);

  const instructionType_bin = zeroExtend(instructionType_dec.toString(2), 3);
  const imm_dec = parseInt(imm_bin, 2);

  return {
    opcode_bin_6_2,
    f3_bin,
    f7_bin,
    rs1_bin,
    rs2_bin,
    rd_bin,
    instructionType_bin,
    imm_dec,
  };
}

module.exports = {
  decodeRV32I,
}