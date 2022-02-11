const fs = require("fs");
const { multiStep } = require("./vm");

// FLAT memory
function textToMemory(text) {
  text = text.replace(" ", "");
  const memory = new Array(128).fill(0);
  let [program, data] = text.split("========", 2);
  data = data.replace("\n", "");
  let pos = 0;
  program.split("\n").forEach((line, index) => {
    if (line.startsWith('//') || line.length == 0) {
      return;
    }
    if (line.length != 32) {
      throw "instruction.length != 32";
    }
    for (var ii = 0; ii < 4; ii++) {
      memory[pos + 3 - ii] = parseInt(line.slice(8 * ii, 8 * (ii + 1)), 2);
    }
    pos += 1;
    if (pos > 64) {
      throw "program too big for 64 byte flat program memory"
    }
  });
  pos = 64;
  data.split(",").forEach((str, index) => {
    if (str.startsWith('//')) {
      return;
    }
    const value = parseInt(str, 10);
    if (value >= 256) {
      throw "memory value too big (>= 256)";
    }
    memory[pos] = value;
    pos += 1;
    if (pos > 128) {
      throw "data too big for 64 byte flat data memory"
    }
  });
  return memory;
}

function run(memory0, steps) {
  const state = {
    m: memory0.slice(),
    r: new Array(31).fill(null),
    pc: 0,
  };
  // console.log(state.m);
  multiStep(state, steps);
  // console.log(state.m);
}

function runFile(filepath, steps) {
  const text = fs.readFileSync(filepath, "utf8");''
  const memory = textToMemory(text);
  run(memory, steps);
}

function main() {
  let [filepath, steps] = process.argv.slice(2, 4);
  runFile(filepath, steps);
}

if (require.main === module) {
  main();
}

module.exports = {
  run,
  runFile,
};
