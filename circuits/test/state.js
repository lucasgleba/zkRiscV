const { getWasmTester } = require("./utils");
const { fetchMemory } = require("../../vm/js/memory");

describe("state", function () {
  it("memory load", async function () {
    const circuit = await getWasmTester("memory64Fetcher.test.circom");
    const mSize = 64;
    const fetchSize = 4;
    const m = new Array(mSize).fill(null);
    for (let ii = 0; ii < mSize; ii++) {
      m[ii] = ii + 1;
    }
    for (let ii = 0; ii < mSize; ii++) {
      const w = await circuit.calculateWitness({ m: m, pointer_dec: ii }, true);
      await circuit.assertOut(w, { out_dec: fetchMemory(m, fetchSize, ii) });
    }
  });
});
