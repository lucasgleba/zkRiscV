const { getWasmTester } = require("./utils");

describe("bitify", function () {
  it("num2bits_soft", async function () {
    const circuit = await getWasmTester("num2bits_soft.test.circom");
    const size = 8;
    const p2size = 2 ** size;
    for (let ii = 0; ii < 3 * p2size; ii += 30) {
      const w = await circuit.calculateWitness({ in: ii }, true);
      await circuit.assertOut(w, {
        out: (ii % p2size).toString(2).split("").reverse(),
      });
    }
  });
});
