const { getWasmTester, objToBinInput } = require("./utils");
const { decodeRV32I } = require("../../vm/js/decoder");
const { opcodes_6_2, sampleOpcode } = require("./sample");

describe("RV32I_Decoder", function () {
  let circuit;
  before(async function () {
    circuit = await getWasmTester("decoder.test.circom");
  });
  for (let ii = 0; ii < opcodes_6_2.length; ii++) {
    const opcode = opcodes_6_2[ii];
    it(opcode, async function () {
      const samples = sampleOpcode(opcode);
      let instruction_bin = samples.next().value;
      while (instruction_bin != undefined) {
        const input = { instruction_bin: instruction_bin };
        const w = await circuit.calculateWitness(objToBinInput(input), true);
        const expected = decodeRV32I(instruction_bin);
        delete expected.instructionType_bin;
        delete expected.imm_dec;
        await circuit.assertOut(w, objToBinInput(expected));
        instruction_bin = samples.next().value;
      }
    });
  }
});
