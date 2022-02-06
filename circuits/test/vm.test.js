const { getWasmTester } = require("./utils");
const { step } = require("../../vm/js/vm");

const PROGRAM = new Array(64).fill(0);

const compOpcode = parseInt("0110011", 2);

for (let ii = 0; ii < PROGRAM.length; ii += 4) {
  PROGRAM[ii] = compOpcode;
}

const DATA = new Array(64).fill(0);
const N_STEPS = 32;

describe("vm", function () {
  let circuit;
  before(async function () {
    circuit = await getWasmTester("vm.test.circom");
  });
  it("ok", async function () {
    const state = {
      m: PROGRAM.concat(DATA),
      r: new Array(31).fill(0),
      pc: 0,
    };
    console.log(state);
    for (let ss = 0; ss < N_STEPS; ss++) {
      const w = await circuit.calculateWitness(
        {
          pcIn: state.pc,
          rIn: state.r,
          mIn: state.m,
        },
        true
      );
      step(state);
      console.log(state);
      await circuit.assertOut(w, {
        pcOut: state.pc,
        rOut: state.r,
        mOut: state.m,
      });
    }
  });
});
