const { getWasmTester } = require("./utils");

describe("gates", function () {
  it("multiMux6", async function () {
    const circuit = await getWasmTester("multiMux6.test.circom");
    const cc = new Array(64).fill(null);
    for (let ii = 0; ii < 64; ii++) {
      cc[ii] = ii + 1;
    }
    for (let ii = 0; ii < 64; ii++) {
      const ss = ii.toString(2).padStart(6, "0").split("").reverse();
      const w = await circuit.calculateWitness({ c: cc, s: ss }, true);
      await circuit.assertOut(w, { "out[0]": ii + 1 });
    }
  });
});
