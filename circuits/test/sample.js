const { zeroExtend } = require("../../vm/js/utils");

const opcodes_6_2 = [
  "01100",
  "00100",
  "00000",
  "01000",
  "11000",
  "11011",
  "11001",
  "01101",
  "00101",
];

const rRange = ["00000", "00001", "10000", "10001"];
const fRangeMap = {
  ".01100": [
    [0, 0],
    [0, 32],
    [1, 0],
    [2, 0],
    [3, 0],
    [4, 0],
    [5, 0],
    [5, 32],
    [6, 0],
    [7, 0],
  ],
  ".00100": [
    [0, 0],
    [1, 0],
    [2, 0],
    [3, 0],
    [4, 0],
    [5, 0],
    [5, 32],
    [6, 0],
    [7, 0],
  ],
  ".00000": [
    [0, 0],
    [1, 0],
    [2, 0],
    [4, 0],
    [5, 0],
  ],
  ".01000": [
    [0, 0],
    [1, 0],
    [2, 0],
  ],
  ".11000": [
    [0, 0],
    [1, 0],
    [4, 0],
    [5, 0],
    [6, 0],
    [7, 0],
  ],
  ".11011": [
    [0, 0],
    [0, 127],
    [7, 0],
    [7, 127],
  ],
  ".11001": [
    [0, 0],
    [0, 127],
  ],
  ".01101": [
    [0, 0],
    [0, 127],
    [7, 0],
    [7, 127],
  ],
  ".00101": [
    [0, 0],
    [0, 127],
    [7, 0],
    [7, 127],
  ],
};

function* sampleOpcode(opcode_6_2) {
  let fRange = fRangeMap[".".concat(opcode_6_2)];

  if (fRange == undefined) {
    throw "opcode not valid" + opcode_6_2;
  }

  for (let rd_idx = 0; rd_idx < rRange.length; rd_idx++) {
    for (let rs1_idx = 0; rs1_idx < rRange.length; rs1_idx++) {
      for (let rs2_idx = 0; rs2_idx < rRange.length; rs2_idx++) {
        const [rd, rs1, rs2] = [
          rRange[rd_idx],
          rRange[rs1_idx],
          rRange[rs2_idx],
        ];
        for (let f_idx = 0; f_idx < fRange.length; f_idx++) {
          const f = fRange[f_idx];
          const f3 = zeroExtend(f[0].toString(2), 3);
          const f7 = zeroExtend(f[1].toString(2), 7);
          yield [f7, rs2, rs1, f3, rd, opcode_6_2, "11"].join("");
        }
      }
    }
  }
}

module.exports = {
  opcodes_6_2,
  sampleOpcode,
};
