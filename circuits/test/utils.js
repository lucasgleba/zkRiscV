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

function objToBinInput(obj) {
  const newObj = {};
  for (let key in obj) {
    const val = obj[key];
    if (typeof val === "string" && val.length > 1) {
      newObj[key] = val.split("").reverse();
    } else {
      newObj[key] = val.toString();
    }
  }
  return newObj;
}

module.exports = {
  getWasmTester,
  objToBinInput,
};
