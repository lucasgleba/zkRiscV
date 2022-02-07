const { getWasmTester } = require("./utils");
const { step } = require("../../vm/js/vm");
const { zeroExtend } = require("../../vm/js/utils");
const { fetchRegister, fetchMemory } = require("../../vm/js/state");
const { decodeRV32I } = require("../../vm/js/decoder");
const { opcodes_6_2, sampleOpcode } = require("./sample");

function instrToDecArray(instruction_bin) {
  const arr = new Array(4).fill(null);
  for (let ii = 0; ii < 4; ii++) {
    arr[4 - ii - 1] = parseInt(instruction_bin.slice(ii * 8, (ii + 1) * 8), 2);
  }
  return arr;
}

describe("vm", function () {
  let circuit;
  const rr = new Array(31).fill(null);
  for (let ii = 0; ii < rr.length; ii++) rr[ii] = ii;
  const data = new Array(64).fill(null);
  for (let ii = 0; ii < data.length; ii++) data[ii] = ii;
  before(async function () {
    circuit = await getWasmTester("vm.test.circom");
  });
  for (let ii = 0; ii < opcodes_6_2.length; ii++) {
    const opcode = opcodes_6_2[ii];
    // if (opcode != "00000") {
    //   continue;
    // }
    it(opcode, async function () {
      const program = new Array(64).fill(null);
      const sampler = sampleOpcode(opcode);
      let ok = true;
      while (ok) {
        for (let jj = 0; jj < program.length; jj += 4) {
          const val = ok ? sampler.next().value : undefined;
          if (val == undefined) {
            ok = false;
            if (jj == 0) {
              break;
            }
          }
          const valArr = instrToDecArray(val || "0".repeat(32));
          for (let kk = 0; kk < 4; kk++) {
            program[jj + kk] = valArr[kk];
          }
        }
        const state = {
          m: program.concat(data),
          r: rr.slice(),
          pc: 0,
        };
        for (let pc = 0; pc < program.length; pc += 4) {
          state.pc = pc;
          if (opcode == "00000" || opcode == "01000") {
            const rawInstr_bin = zeroExtend(
              fetchMemory(program, 4, pc).toString(2),
              32
            );
            const instr = decodeRV32I(rawInstr_bin);
            const rs1_dec = parseInt(instr.rs1_bin, 2);
            const rs1Value_dec = fetchRegister(state.r, rs1_dec);
            const mPointer = rs1Value_dec + instr.imm_dec;
            if (mPointer < 64 || mPointer >= 128) {
              continue;
            }
          }
          const w = await circuit.calculateWitness(
            {
              pcIn: state.pc,
              rIn: state.r,
              mIn: state.m,
            },
            true
          );
          step(state);
          await circuit.assertOut(w, {
            pcOut: state.pc,
            rOut: state.r,
            mOut: state.m,
          });
        }
      }
    });
  }
});
