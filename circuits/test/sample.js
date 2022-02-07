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

const fiveBitTestValues = ["00000", "00001", "10000", "10001"];

function* sampleOpcode(opcode) {
  for (let b0_idx = 0; b0_idx < fiveBitTestValues.length; b0_idx++) {
    for (let b1_idx = 0; b1_idx < fiveBitTestValues.length; b1_idx++) {
      for (let b2_idx = 0; b2_idx < fiveBitTestValues.length; b2_idx++) {
        for (let b3_idx = 0; b3_idx < fiveBitTestValues.length; b3_idx++) {
          for (let b4_idx = 0; b4_idx < fiveBitTestValues.length; b4_idx++) {
            const [b0, b1, b2, b3, b4] = [
              fiveBitTestValues[b0_idx],
              fiveBitTestValues[b1_idx],
              fiveBitTestValues[b2_idx],
              fiveBitTestValues[b3_idx],
              fiveBitTestValues[b4_idx],
            ];
            yield [b0, b1, b2, b3, b4, opcode, "11"].join("");
          }
        }
      }
    }
  }
}

module.exports = {
  opcodes_6_2,
  sampleOpcode,
};
