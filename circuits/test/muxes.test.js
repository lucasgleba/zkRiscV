const { getWasmTester } = require("./utils");

describe("muxes", function () {
  it("multiMux6", async function () {
    const circuit = await getWasmTester("multiMux6.test.circom");
    const sSize = 6;
    const inSize = 2 ** sSize;
    const cc = new Array(inSize).fill(null);
    for (let ii = 0; ii < inSize; ii++) {
      cc[ii] = ii + 1;
    }
    for (let ii = 0; ii < inSize; ii++) {
      const ss = ii.toString(2).padStart(sSize, "0").split("").reverse();
      const w = await circuit.calculateWitness({ c: cc, s: ss }, true);
      await circuit.assertOut(w, { "out[0]": ii + 1 });
    }
  });
  it("imux6", async function () {
    const circuit = await getWasmTester("imux6.test.circom");
    const sSize = 6;
    const outSize = 2 ** sSize;
    const out = new Array(outSize).fill(0);
    for (let ii = 0; ii < outSize; ii++) {
      out[ii] = 1;
      const ss = ii.toString(2).padStart(sSize, "0").split("").reverse();
      const w = await circuit.calculateWitness({ in: 1, s: ss }, true);
      await circuit.assertOut(w, { out: out });
      out[ii] = 0;
    }
  });
});
