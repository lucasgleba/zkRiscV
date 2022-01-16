const { getWasmTester } = require("./utils");

async function main() {
  let circuit = await getWasmTester("cpu.test.circom");
  let input = {
    rs1Raw: 2 ** 32 - 4,
    rs1Signed: "0",
    rs2Raw: parseInt('1110', 2),
    rs2Signed: "0",
    immRaw: parseInt('11110', 2),
    immSigned: "0",
    useImm: "1",
    funct: "0",
    pcIn: 5,
  };
  const w = await circuit.calculateWitness(input, true);
  const expectedOutput = {
    out: -4 + input.immRaw,
    pcOut: input.pcIn + 1,
  };
  await circuit.assertOut(w, expectedOutput);
}

main();
