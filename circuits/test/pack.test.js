const { getWasmTester } = require("./utils");
const { pack } = require("../../vm/js/state");

const N = 32;
const SIZE = 32;

describe("pack", function () {
  it("ok", async function () {
    const circuit = await getWasmTester("pack.test.circom");
    const data = new Array(N).fill(null);
    for (let ii = 0; ii < N; ii++) {
      data[ii] = ii + 1;
    }
    const w = await circuit.calculateWitness({ in: data }, true);
    const expected = pack(data, SIZE);
    await circuit.assertOut(w, { out: expected });
  });
});
