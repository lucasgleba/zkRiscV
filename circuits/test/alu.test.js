const { Operator } = require("../../vm/js/vm");

const { getWasmTester } = require("./utils");

const BITS = 32;

const maxValueP1 = 2 ** BITS;
const testSet = [0, 1, 2, maxValueP1 - 1, maxValueP1 - 2];

const operator = new Operator(BITS);

async function testOp(circuit, opName, testSetA, testSetB) {
  const opcode = operator.opcodes[opName];
  for (let ii = 0; ii < testSetA; ii++) {
    for (let jj = 0; jj < testSetB; jj++) {
      const [aa, bb] = [testSetA[ii], testSetB[jj]];
      const out = operator.execute(aa, bb, opcode);
      const w = await circuit.calculateWitness(
        { a: aa, b: bb, opcode: opcode },
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
        it(opName, async () => {
          await testOp(circuit, opName, testSet, testSet);
        });
      }
    );
    ["sfl", "srl", "sra"].forEach(
      (opName) => {
        it(opName, async () => {
          await testOp(circuit, opName, testSet, testSet.slice(0, 3));
        });
      }
    );
  });
});
