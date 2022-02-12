const fs = require("fs");
const { getWasmTester } = require("./utils");
const { textToMemory } = require("../../vm/js/run");
const { multiStep } = require("../../vm/js/vm");

describe("run", function () {
  this.timeout(30000);
  const programNames = ["null", "hw"];
  let circuit;
  before(async function () {
    circuit = await getWasmTester("vmMultiStep.test.circom");
  });
  for (let ii = 0; ii < programNames.length; ii++) {
    const programName = programNames[ii];
    it("null", async function () {
      const filepath = `../vm/js/programs/${programName}.txt`;
      const nSteps = 8;
      const text = fs.readFileSync(filepath, "utf8");
      const pc0 = 0;
      const memory0 = textToMemory(text);
      const registers0 = new Array(31).fill(0);
      const refState = {
        m: memory0.slice(),
        r: registers0.slice(),
        pc: pc0,
      };
      multiStep(refState, nSteps);
      const w = await circuit.calculateWitness(
        {
          mIn: memory0.slice(),
          rIn: registers0.slice(),
          pcIn: pc0,
        },
        true
      );
      await circuit.assertOut(w, {
        mOut: refState.m,
        rOut: refState.r,
        pcOut: refState.pc,
      });
    });
  }
});