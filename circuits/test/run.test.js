const fs = require("fs");
const { getWasmTester } = require("./utils");
const { textToMemory, textToMemoryTree } = require("../../vm/js/run");
const { multiStep_flat, multiStep_tree } = require("../../vm/js/vm");

describe("run", function () {
  this.timeout(30000);
  const programNames = ["null", "hw"];
  describe("flat", function () {
    let circuit;
    before(async function () {
      circuit = await getWasmTester("vmMultiStep_Flat.test.circom");
    });
    for (let ii = 0; ii < programNames.length; ii++) {
      const programName = programNames[ii];
      it(programName, async function () {
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
        multiStep_flat(refState, nSteps);
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
  describe("tree", function () {
    let circuit;
    before(async function () {
      circuit = await getWasmTester("vmMultiStep_Tree.test.circom");
    });
    for (let ii = 1; ii < programNames.length; ii++) {
      const programName = programNames[ii];
      it(programName, async function () {
        const filepath = `../vm/js/programs/${programName}.txt`;
        const nSteps = 8;
        const text = fs.readFileSync(filepath, "utf8");
        const pc0 = 0;
        const registers0 = new Array(31).fill(0);
        const mTree = textToMemoryTree(text);
        const refState = {
          mTree: mTree,
          r: registers0.slice(),
          pc: pc0,
        };
        const mRoot0 = mTree.root();
        const helpers = multiStep_tree(refState, { programSize: 16 }, nSteps);
        const w = await circuit.calculateWitness(
          {
            pcIn: pc0,
            rIn: registers0.slice(),
            mRoot0: mRoot0,
            ...helpers,
          },
          true
        );
        await circuit.assertOut(w, {
          mRoot1: refState.mTree.root(),
          rOut: refState.r,
          pcOut: refState.pc,
        });
      });
    }
  });
});