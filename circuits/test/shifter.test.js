const { getWasmTester } = require("./utils");

function zeroExtend(str, size) {
  return "0".repeat(size - str.length).concat(str);
}

const TEST_VALUE = 2863311530;
const TEST_VALUE_BIN = TEST_VALUE.toString(2);

describe("shift", function () {
  it("left", async function () {
    circuit = await getWasmTester("shiftLeft.test.circom");
    for (let shift = 0; shift < 32; shift++) {
      const w = await circuit.calculateWitness(
        {
          in: TEST_VALUE,
          shift: zeroExtend(shift.toString(2), 5).split("").reverse(),
          k: 0,
        },
        true
      );
      await circuit.assertOut(w, {
        out: BigInt("0b" + TEST_VALUE_BIN + "0".repeat(shift), 2).toString(),
      });
    }
  });
  it("right", async function () {
    circuit = await getWasmTester("shiftRight.test.circom");
    for (let shift = 0; shift < 32; shift++) {
      for (let kk = 0; kk < 2; kk++) {
        const w = await circuit.calculateWitness(
          {
            in: TEST_VALUE,
            shift: zeroExtend(shift.toString(2), 5).split("").reverse(),
            k: kk,
          },
          true
        );
        await circuit.assertOut(w, {
          out: BigInt(
            "0b" +
              kk.toString().repeat(shift) +
              TEST_VALUE_BIN.slice(0, TEST_VALUE_BIN.length - shift),
            2
          ).toString(),
        });
      }
    }
  });
});
