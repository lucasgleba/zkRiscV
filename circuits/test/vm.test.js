const { getWasmTester, objToBinInput } = require("./utils");
const { step, alu, computeWrapped } = require("../../vm/js/vm");
const { zeroExtend } = require("../../vm/js/utils");
const { fetchRegister, fetchMemory } = require("../../vm/js/state");
const { decodeRV32I } = require("../../vm/js/decoder");
const { opcodes_6_2, sampleOpcode } = require("./sample");

// TODO: test alu modules and alu end to end
// TODO: test entire execution of program end to end
// TODO: test against modded risc-v tests
// TODO: test valid vm multistep

function instrToDecArray(instruction_bin) {
  const arr = new Array(4).fill(null);
  for (let ii = 0; ii < 4; ii++) {
    arr[4 - ii - 1] = parseInt(instruction_bin.slice(ii * 8, (ii + 1) * 8), 2);
  }
  return arr;
}

describe("vm", function () {
  this.timeout(30000);
  let vmCircuit, aluCircuit, computatorWCircuit;
  const rr = new Array(31).fill(null);
  for (let ii = 0; ii < rr.length; ii++) rr[ii] = ii;
  const data = new Array(64).fill(null);
  for (let ii = 0; ii < data.length; ii++) data[ii] = ii;
  before(async function () {
    vmCircuit = await getWasmTester("VMStep.test.circom");
    aluCircuit = await getWasmTester("alu.test.circom");
    computatorWCircuit = await getWasmTester("computatorWrapped.test.circom");
  });
  for (let ii = 0; ii < opcodes_6_2.length; ii++) {
    const opcode = opcodes_6_2[ii];
    it(opcode, async function () {
      const program = new Array(64).fill(null);
      const sampler = sampleOpcode(opcode);
      let ok = true;

      while (ok) {
        // gen test program
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

        // setup state
        const state = {
          m: program.concat(data),
          r: rr.slice(),
          pc: 0,
        };

        // run test program forcing pc += 4
        for (let pc = 0; pc < program.length; pc += 4) {
          state.pc = pc;

          const rawInstr_bin = zeroExtend(
            fetchMemory(program, 4, pc).toString(2),
            32
          );
          const instr = decodeRV32I(rawInstr_bin);
          const rs1_dec = parseInt(instr.rs1_bin, 2);
          const rs1Value_dec = fetchRegister(state.r, rs1_dec);
          const rs2_dec = parseInt(instr.rs2_bin, 2);
          const rs2Value_dec = fetchRegister(state.r, rs2_dec);

          if (opcode == "00000" || opcode == "01000") {
            // skip invalid load/stores
            const mPointer = rs1Value_dec + instr.imm_dec;
            if (mPointer < 64 || mPointer >= 128) {
              continue;
            }
          // disabled
          } else if (false) {
            // test alu alone
            const aluInput = {
              pcIn_dec: state.pc,
              instructionType_bin: instr.instructionType_bin,
              opcode_bin_6_2: instr.opcode_bin_6_2,
              f3_bin: instr.f3_bin,
              f7_bin: instr.f7_bin,
              rs1Value_bin: zeroExtend(rs1Value_dec.toString(2), 32),
              rs2Value_bin: zeroExtend(rs2Value_dec.toString(2), 32),
              rs1Value_dec: rs1Value_dec,
              rs2Value_dec: rs2Value_dec,
              imm_dec: instr.imm_dec,
            };

            // disabled
            if (false && (opcode == "01100" || opcode == "00100")) {
              // test computatorWrapped alone
              const wComp = await computatorWCircuit.calculateWitness(
                objToBinInput(aluInput),
                true
              );
              const { out, pcOut } = computeWrapped(
                instr,
                rs1Value_dec,
                rs2Value_dec,
                state.pc
              );

              await computatorWCircuit.loadSymbols();
              console.log(
                "debugOutput:",
                wComp[
                  computatorWCircuit.symbols["main." + "debugOutput"].varIdx
                ].toString()
              );

              await computatorWCircuit.assertOut(wComp, {
                out_dec: out,
                pcOut_dec: pcOut,
              });
            }

            const wAlu = await aluCircuit.calculateWitness(
              objToBinInput(aluInput),
              true
            );
            const { out, pcOut } = alu(
              instr,
              rs1Value_dec,
              rs2Value_dec,
              state.pc
            );

            // await aluCircuit.loadSymbols();
            // console.log(
            //   "debug:",
            //   wAlu[aluCircuit.symbols["main." + "debug"].varIdx].toString()
            // );

            await aluCircuit.assertOut(wAlu, {
              out_dec: out,
              pcOut_dec: pcOut,
            });
          }

          // test vm end to end
          const w = await vmCircuit.calculateWitness(
            {
              pcIn: state.pc,
              rIn: state.r,
              mIn: state.m,
            },
            true
          );
          step(state);
          await vmCircuit.assertOut(w, {
            pcOut: state.pc,
            rOut: state.r,
            mOut: state.m,
          });
        }
      }
    });
  }
});
