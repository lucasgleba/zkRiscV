const { buildMimcSponge } = require("circomlibjs");
const { getWasmTester } = require("./utils");
const { hashState } = require("../../vm/js/state");

describe("stateHash", function () {
  let hashFunc;
  before(async function () {
    const mimcSponge = await buildMimcSponge();
    const key = 0;
    hashFunc = (arr) => mimcSponge.F.toString(mimcSponge.multiHash(arr, key), 10);
  });
  after(async () => {
    globalThis.curve_bn128.terminate();
  });
  it("ok", async function () {
    const state = {
      pc: 0,
      r: new Array(31).fill(1),
      m: new Array(128).fill(2),
    };
    const circuit = await getWasmTester("stateHash.test.circom");
    const w = await circuit.calculateWitness(state, true);
    const expected = hashState(state, hashFunc);
    await circuit.assertOut(w, { out: expected });
  });
});
