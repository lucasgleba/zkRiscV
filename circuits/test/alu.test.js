const { Operator, ImmLoader } = require("../../vm/js/vm");

const { getWasmTester } = require("./utils");

const BITS = 32;

const maxValueP1 = 2 ** BITS;
const testSet = [0, 1, 2, maxValueP1 - 1, maxValueP1 - 2];

const operator = new Operator(BITS);
const immLoader = new ImmLoader(BITS);

async function testOperator(circuit, opName, aTestSet, bTestSet) {
  const opcode = operator.opcodes[opName];
  for (let ii = 0; ii < aTestSet.length; ii++) {
    for (let jj = 0; jj < bTestSet.length; jj++) {
      const [aa, bb] = [aTestSet[ii], bTestSet[jj]];
      const out = operator.execute(opcode, aa, bb);
      console.log(aa, bb, out);
      const w = await circuit.calculateWitness(
        { a: aa, b: bb, opcode: opcode },
        true
      );
      await circuit.assertOut(w, { out: out });
    }
  }
}

async function testImmLoader(circuit, opName, immTestSet, pcTestSet) {
  const opcode = immLoader.opcodes[opName];
  for (let ii = 0; ii < immTestSet.length; ii++) {
    for (let jj = 0; jj < pcTestSet.length; jj++) {
      const [imm, pc] = [immTestSet[ii], pcTestSet[jj]];
      const out = immLoader.execute(opcode, imm, pc);
      const w = await circuit.calculateWitness(
        { imm: imm, pc: pc, opcode: opcode },
        true
      );
      await circuit.assertOut(w, { out: out });
    }
  }
}

describe("alu", function () {
  let circuit;
  describe("operator", function () {
    before(async () => {
      circuit = await getWasmTester("operator.test.circom");
    });
    ["add", "sub", "xor", "or", "and", "slt", "sltu"].forEach(
      (opName) => {
        xit(opName, async () => {
          await testOperator(circuit, opName, testSet, testSet);
        });
      }
    );
    ["sll", "srl", "sra"].forEach(
      (opName) => {
        it(opName, async () => {
          await testOperator(circuit, opName, testSet, testSet.slice(0, 3));
        });
      }
    );
  });
  xdescribe("immLoader", function () {
    before(async () => {
      circuit = await getWasmTester("immLoader.test.circom");
    });
    ["lui", "auipc"].forEach((opName) => {
      it(opName, async () => {
        await testImmLoader(circuit, opName, testSet.slice(0, 3), testSet);
      });
    });
  });
});
