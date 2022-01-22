const { Operator, ImmLoader, Jumper, Brancher } = require("../../vm/js/vm");

const { getWasmTester } = require("./utils");

const BITS = 32;

const maxValueP1 = 2 ** BITS;
const testSet = [0, 1, 2, maxValueP1 - 1, maxValueP1 - 2];

const operator = new Operator(BITS);
const immLoader = new ImmLoader(BITS);
const jumper = new Jumper(BITS);
const brancher = new Brancher(BITS);

async function testOperator(circuit, opName, aTestSet, bTestSet) {
  const opcode = operator.opcodes[opName];
  for (let ii = 0; ii < aTestSet.length; ii++) {
    for (let jj = 0; jj < bTestSet.length; jj++) {
      const [aa, bb] = [aTestSet[ii], bTestSet[jj]];
      const out = operator.execute(opcode, aa, bb);
      const w = await circuit.calculateWitness(
        { a: aa, b: bb, opcode: opcode, pc: 0 },
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

async function testJumper(circuit, opName, rs1TestSet, immTestSet, pcTestSet) {
  const opcode = jumper.opcodes[opName];
  for (let ii = 0; ii < rs1TestSet.length; ii++) {
    for (let jj = 0; jj < immTestSet.length; jj++) {
      for (let kk = 0; kk < pcTestSet.length; kk++) {
        const [rs1, imm, pc] = [rs1TestSet[ii], immTestSet[jj], pcTestSet[kk]];
        const [out, pcOut] = jumper.execute(opcode, rs1, imm, pc);
        const w = await circuit.calculateWitness(
          { rs1: rs1, imm: imm, pc: pc, opcode: opcode },
          true
        );
        await circuit.assertOut(w, { out: out, pcOut: pcOut });
      }
    }
  }
}

// rs1Test, rs2Test, immTest, pcTest
async function testBrancher(circuit, opName, testSet) {
  const opcode = brancher.opcodes[opName];
  for (let ii = 0; ii < testSet.length; ii++) {
    for (let jj = 0; jj < testSet.length; jj++) {
      for (let kk = 0; kk < testSet.length; kk++) {
        for (let ll = 0; ll < testSet.length; ll++) {
          const [rs1, rs2, imm, pc] = [
            testSet[ii],
            testSet[jj],
            testSet[kk],
            testSet[ll],
          ];
          const pcOut = brancher.execute(opcode, rs1, rs2, imm, pc);
          const cmp = brancher._preops[opName](rs1, rs2);
          const eq = opcode % 2 == 0 ? 1 : 0;
          const w = await circuit.calculateWitness(
            { cmp: cmp, imm: imm, pc: pc, eq: eq },
            true
          );
          await circuit.assertOut(w, { pcOut: pcOut });
        }
      }
    }
  }
}

describe("alu", function () {
  let circuit;
  describe("operator", function () {
    before(async () => {
      circuit = await getWasmTester("operator.test.circom");
    });
    ["add", "sub", "xor", "or", "and", "slt", "sltu"].forEach((opName) => {
      it(opName, async () => {
        await testOperator(circuit, opName, testSet, testSet);
      });
    });
    ["sll", "srl", "sra"].forEach((opName) => {
      it(opName, async () => {
        await testOperator(circuit, opName, testSet, testSet.slice(0, 3));
      });
    });
  });
  describe("immLoader", function () {
    before(async () => {
      circuit = await getWasmTester("immLoader.test.circom");
    });
    ["lui", "auipc"].forEach((opName) => {
      it(opName, async () => {
        await testImmLoader(circuit, opName, testSet.slice(0, 3), testSet);
      });
    });
  });
  describe("jumper", function () {
    before(async () => {
      circuit = await getWasmTester("jumper.test.circom");
    });
    ["jal", "jalr"].forEach((opName) => {
      it(opName, async () => {
        await testJumper(circuit, opName, testSet, testSet, testSet);
      });
    });
  });
  describe("brancher", function () {
    before(async () => {
      circuit = await getWasmTester("brancher.test.circom");
    });
    ["beq", "bne", "blt", "bge", "bltu", "bgeu"].forEach((opName) => {
      it(opName, async () => {
        await testBrancher(circuit, opName, testSet);
      });
    });
  });
});
