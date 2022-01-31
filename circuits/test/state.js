const { getWasmTester } = require("./utils");
const { fetchMemory, fetchRegister } = require("../../vm/js/state");

describe("state", function () {
  describe("memory", function () {
    const mSize = 64;
    it("load", async function () {
      const circuit = await getWasmTester("memory64Load.test.circom");
      const fetchSize = 4;
      const m = new Array(mSize).fill(null);
      for (let ii = 0; ii < mSize; ii++) {
        m[ii] = ii + 1;
      }
      for (let ii = 0; ii < mSize; ii++) {
        const w = await circuit.calculateWitness(
          { m: m, pointer_dec: ii },
          true
        );
        await circuit.assertOut(w, { out_dec: fetchMemory(m, fetchSize, ii) });
      }
    });
    it("store1", async function () {
      const circuit = await getWasmTester("memory64Store1.test.circom");
      const input = 255;
      const m = new Array(mSize).fill(null);
      for (let ii = 0; ii < mSize; ii++) {
        m[ii] = ii + 1;
      }
      for (let ii = 0; ii < mSize; ii++) {
        const w = await circuit.calculateWitness(
          { in: input, mIn: m, pointer_dec: ii },
          true
        );
        const temp = m[ii];
        m[ii] = input;
        await circuit.assertOut(w, { mOut: m });
        m[ii] = temp;
      }
    });
  });
  describe("registers", function () {
    const nRegisters = 31;
    it("load", async function () {
      const circuit = await getWasmTester("registerLoad.test.circom");
      const addressSize = 5;
      const r = new Array(nRegisters).fill(null);
      for (let ii = 0; ii < nRegisters; ii++) {
        r[ii] = ii + 1;
      }
      for (let ii = 0; ii < nRegisters; ii++) {
        const address_bin = ii
          .toString(2)
          .padStart(addressSize, "0")
          .split("")
          .reverse();
        const w = await circuit.calculateWitness(
          { r: r, address_bin: address_bin },
          true
        );
        await circuit.assertOut(w, { out_dec: fetchRegister(r, ii) });
      }
    });
    it("store", async function () {
      const circuit = await getWasmTester("registerStore.test.circom");
      const input = 255;
      const r = new Array(nRegisters).fill(null);
      for (let ii = 0; ii < nRegisters; ii++) {
        r[ii] = ii + 1;
      }
      for (let ii = 0; ii < nRegisters + 1; ii++) {
        const w = await circuit.calculateWitness(
          { in: input, rIn: r, pointer_dec: ii },
          true
        );
        let temp;
        if (ii > 0) {
          temp = r[ii - 1];
          r[ii - 1] = input;
        }
        await circuit.assertOut(w, { rOut: r });
        if (ii > 0) {
          r[ii - 1] = temp;
        }
      }
    });
  });
});
