const { getWasmTester } = require("./utils");
const { decodeIns, encodeIns } = require("../../vm/js/vm");

const registerTestSet = [0, 1, 31];

async function testInsDecoder(circuit, insBin) {
  const w = await circuit.calculateWitness({
    ins: parseInt(insBin, 2),
  });
  await circuit.loadSymbols();
  // console.log("=====");
  // console.log("rd", w[circuit.symbols["main.rd"].varIdx].toString());
  // console.log("rs1", w[circuit.symbols["main.rs1"].varIdx].toString());
  // console.log("rs2", w[circuit.symbols["main.rs2"].varIdx].toString());
  // console.log("imm", w[circuit.symbols["main.imm"].varIdx].toString());
  // console.log("useImm", w[circuit.symbols["main.useImm"].varIdx].toString());
  // console.log("j_ibursiMux.out[1]", w[circuit.symbols["main.j_ibursiMux.out[1]"].varIdx].toString());
  // console.log("rawImm", w[circuit.symbols["main.rawImm"].varIdx].toString());
  // console.log("insTypeBin.out[2]", w[circuit.symbols["main.insTypeBin.out[2]"].varIdx].toString());
  // console.log("immOr.out", w[circuit.symbols["main.immOr.out"].varIdx].toString());
  // console.log(insBin);
  // console.log(decodeIns(insBin));
  await circuit.assertOut(w, decodeIns(insBin));
}

describe("decoder", function () {
  let circuit;
  before(async () => {
    circuit = await getWasmTester("decoder.test.circom");
  });
  describe("operate", function() {
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
