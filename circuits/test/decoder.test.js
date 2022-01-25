const { getWasmTester } = require("./utils");
const { decodeIns, encodeIns } = require("../../vm/js/vm");

const registerTestSet = [0, 1, 31];

async function debugTest(circuit, w, ins) {
  await circuit.loadSymbols();
  console.log("circom, js");
  const decodedIns = decodeIns(ins);
  [
    "rd",
    "rs1",
    "rs2",
    "imm",
    "useImm",
    "insOpcode",
    "funcOpcode",
    "neqOpcode",
    "rOpcode",
    "storeOpcode",
    // "insBin.out[30]",
    // "riIncMux.out",
    // "f3Num.out",
  ].forEach(function (signal) {
    console.log(
      signal,
      w[circuit.symbols["main." + signal].varIdx].toString(),
      decodedIns[signal]
    );
  });
  console.log(ins);
  console.log("=====");
}

async function testInsDecoder(circuit, insBin) {
  const w = await circuit.calculateWitness({
    ins: parseInt(insBin, 2),
  });
  // await debugTest(circuit, w, insBin);
  await circuit.assertOut(w, decodeIns(insBin));
}

describe("decoder", function () {
  let circuit;
  before(async () => {
    circuit = await getWasmTester("decoder.test.circom");
  });
  describe("operate", function () {
    it("r", async function () {
      for (let ii = 0; ii < registerTestSet.length; ii++) {
        for (let jj = 0; jj < registerTestSet.length; jj++) {
          for (let kk = 0; kk < registerTestSet.length; kk++) {
            const [rd, rs1, rs2] = [
              registerTestSet[ii],
              registerTestSet[jj],
              registerTestSet[kk],
            ];
            const insBin = encodeIns("operate", {
              rd: rd,
              rs1: rs1,
              rs2: rs2,
              useImm: 0,
            });
            await testInsDecoder(circuit, insBin);
          }
        }
      }
    });
    it("i", async function () {
      const immTestSet = [0, 1, -1];
      for (let ii = 0; ii < registerTestSet.length; ii++) {
        for (let jj = 0; jj < registerTestSet.length; jj++) {
          for (let kk = 0; kk < immTestSet.length; kk++) {
            const [rd, rs1, imm] = [
              registerTestSet[ii],
              registerTestSet[jj],
              immTestSet[kk],
            ];
            const insBin = encodeIns("operate", {
              rd: rd,
              rs1: rs1,
              imm: imm,
              useImm: 1,
            });
            await testInsDecoder(circuit, insBin);
          }
        }
      }
    });
  });
});
