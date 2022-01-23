const { getWasmTester } = require("./utils");

async function testMultiMux5(circuit) {
  const cc = new Array(32).fill(null);
  for (let ii = 0; ii < 32; ii++) {
    cc[ii] = ii + 1;
  }
  for (let ii = 0; ii < 32; ii++) {
    const ss = (ii).toString(2).padStart(5, "0").split("").reverse();
    const w = await circuit.calculateWitness({ c: cc, s: ss }, true);
    // await circuit.loadSymbols();
    // console.log(ii, ss, ii + 1, w[circuit.symbols["main.out[0]"].varIdx].toString());
    // console.log(w[circuit.symbols["main.s[4]"].varIdx].toString());
    await circuit.assertOut(w, { "out[0]": ii + 1 });
  }
}

describe("gates", function () {
  it("multiMux5", async function () {
    const circuit = await getWasmTester("multiMux5.test.circom");
    testMultiMux5(circuit);
  });
});
