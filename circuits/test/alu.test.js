const { Operator } = require("../../vm/js/vm");

const { getWasmTester } = require("./utils");

const BITS = 32;

const maxValueP1 = 2 ** BITS;
const testSet = [0, 1, 2, maxValueP1 - 1, maxValueP1 - 2];

const operator = new Operator(BITS);

async function testOp(circuit, opName) {
  const opcode = operator.opcodes[opName];
  for (let ii = 0; ii < testSet.length; ii++) {
    for (let jj = 0; jj < testSet.length; jj++) {
      const [aa, bb] = [testSet[ii], testSet[jj]];
      const out = operator.execute(aa, bb, opcode);
      const w = await circuit.calculateWitness({ a: aa, b: bb, opcode: opcode }, true);
      await circuit.assertOut(w, { out: out });
    }
  }
}

describe("alu", function () {
  let circuit;
  describe("operator", function() {
    before(async () => {
      circuit = await getWasmTester("operator.test.circom");
    });
    it("add", async () => {
      await testOp(circuit, "add");
    });
    it("sub", async () => {
      await testOp(circuit, "sub");
    });
    it("xor", async () => {
      await testOp(circuit, "xor");
    });
    it("or", async () => {
      await testOp(circuit, "or");
    });
    it("and", async () => {
      await testOp(circuit, "and");
    });
  });
});
