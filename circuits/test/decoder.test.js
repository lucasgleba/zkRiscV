const { getWasmTester } = require("./utils");

describe("decoder", function () {
  let circuit;
  before(async () => {
    circuit = await getWasmTester("decoder.test.circom");
  });
  it("r", async function () {
    const w = await circuit.calculateWitness({
      ins: parseInt("00000000000000000000000000110011", 2),
    });
    await circuit.assertOut(w, {
      rd: 0,
      rs1: 0,
      rs2: 0,
      imm: 0,
      useImm: 0,
      insOpcode: 0,
      funcOpcode: 0,
      eqOpcode: 0,
    });
  });
});
