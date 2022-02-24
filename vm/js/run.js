/*
node run.js <filepath> <steps>
 */

const fs = require("fs");
const MerkleTree = require("fixed-merkle-tree");
const { multiStep_flat, multiStep_tree } = require("./vm");

function programTextToMemory_Flat(programText) {
  const memory = new Array(64).fill(0);
  let pos = 0;
  programText.split("\n").forEach((line, index) => {
    if (line.startsWith("//") || line.length == 0) return;
    if (line.length != 32) throw "instruction.length != 32";
    for (var ii = 0; ii < 4; ii++) {
      memory[pos + 3 - ii] = parseInt(line.slice(8 * ii, 8 * (ii + 1)), 2);
    }
    pos += 4;
    if (pos > 64) throw "program too big for 64 byte flat program memory";
  });
  return memory;
}

function programTextToMemory_Tree(programText) {
  const memory = new Array(16).fill(0);
  let pos = 0;
  programText.split("\n").forEach((line, index) => {
    if (line.startsWith("//") || line.length == 0) return;
    if (line.length != 32) throw "instruction.length != 32";
    memory[pos] = parseInt(line, 2);
    pos += 1;
    if (pos > 16) throw "program too big for 64 byte flat program memory";
  });
  return memory;
}

function dataTextToMemory(dataText) {
  const memory = new Array(64).fill(0);
  let pos = 0;
  dataText.split(",").forEach((str, index) => {
    if (str.startsWith("//")) return;
    const value = parseInt(str, 10);
    if (value >= 256) throw "memory value too big (>= 256)";
    memory[pos] = value;
    pos += 1;
    if (pos > 64) throw "data too big for 64 byte flat data memory";
  });
  return memory;
}

function preprocessText(text) {
  text = text.replace(/[^\S\r\n]/g, "");
  let [program, data] = text.split("========", 2);
  data = data.replace("\n", "");
  return [program, data];
}

// FLAT memory
function textToMemory(text) {
  const [program, data] = preprocessText(text);
  return programTextToMemory_Flat(program).concat(dataTextToMemory(data));
}

function textToMemoryTree(text) {
  const [program, data] = preprocessText(text);
  const elements = programTextToMemory_Tree(program)
    .concat(dataTextToMemory(data))
    .concat(new Array(48).fill(0));
  return new MerkleTree(7, elements);
}

// Run in flat memory machine
function run_flat(memory0, steps) {

  const state = {
    m: memory0.slice(),
    r: new Array(31).fill(0),
    pc: 0,
  };
  console.log("Program:")
  console.log(state.m.slice(0, 64).join(","));
  console.log("\nData0:");
  console.log(state.m.slice(64, 128).join(","));
  // console.log("\npc\tinstruction");
  multiStep_flat(state, steps);
  console.log("");
  console.log(`Data${steps}:`);
  console.log(state.m.slice(64, 128).join(","));
}

function run_tree(memoryTree, steps) {

  const state = {
    mTree: memoryTree,
    r: new Array(31).fill(0),
    pc: 0,
  };
  console.log("Program:")
  console.log(state.mTree._layers[0].slice(0, 16).join(","));
  console.log("\nData0:");
  console.log(state.mTree._layers[0].slice(16, 128).join(","));
  multiStep_tree(state, { programSize: 16 }, steps);
  console.log("");
  console.log(`Data${steps}:`);
  console.log(state.mTree._layers[0].slice(16, 128).join(","));
}

function runFile(filepath, steps, flat) {
  const text = fs.readFileSync(filepath, "utf8");
  if (flat) {
    const memory = textToMemory(text);
    run_flat(memory, steps);
  } else {
    const memoryTree = textToMemoryTree(text);
    run_tree(memoryTree, steps);
  }
}

function main() {
  let [filepath, steps, flat] = process.argv.slice(2, 5);
  flat = flat != "tree";
  runFile(filepath, steps, flat);
}

if (require.main === module) {
  main();
}

module.exports = {
  run_flat,
  runFile,
  textToMemory,
};
