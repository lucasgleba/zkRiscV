/**
 * NOTE: If circom files don't have a pragma statement,
 * their tests will fail because stderr won't be null during compilation.
 */

const path = require("path");
const wasm_tester = require("circom_tester").wasm;

async function getWasmTester(...args) {
  const circuitPath = path.join(__dirname, "circuits", ...args);
  return await wasm_tester(circuitPath);
}

module.exports = {
  getWasmTester,
};
