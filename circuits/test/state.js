const { getWasmTester } = require("./utils");
const { fetchMemory } = require("../../vm/js/memory");

describe("state", function () {
  it("memory load", async function () {
    const circuit = await getWasmTester("memory64Load.test.circom");
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
  it("memory store1", async function () {
    const circuit = await getWasmTester("memory64Store1.test.circom");
    const mSize = 64;
    const input = 255;
    const m = new Array(mSize).fill(null);
    for (let ii = 0; ii < mSize; ii++) {
      m[ii] = ii + 1;
    }
    for (let ii = 0; ii < mSize; ii++) {
      const w = await circuit.calculateWitness({ in: input, mIn: m, pointer_dec: ii }, true);
      const temp = m[ii];
      m[ii] = input;
      await circuit.assertOut(w, { mOut: m });
      m[ii] = temp;
    }
  });
});
