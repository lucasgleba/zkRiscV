/**
 * Scaffold emulator, follows circuit structure
 */

function assertSize(value, maxSize) {
  if (value >= 2 ** maxSize) {
    throw "value too big";
  }
}

function assertSize32(value) {
  assertSize(value, 32);
}

function assertAllSize32(...values) {
  values.forEach((val) => assertSize32(val));
}

// TODO: cache powers of two [?]
function toSigned(value, size) {
  size = size || 32;
  pow2_size = 2 ** size;
  return value >= pow2_size / 2 ? -(pow2_size - value) : value;
}

function fitToBits(value, size) {
  size = size || 32;
  pow2_size = 2 ** size;
  value = value % pow2_size;
  return value < 0 ? pow2_size + value : value;
}

function fitToBitsBin(value, size) {
  size = size || 32;
  return value.slice(value.length - size, value.length).padStart(size, "0");
}

function signExtend(value, ogSize, newSize) {
  newSize = newSize || 32;
  pow2_ogSize = 2 ** ogSize;
  if (value >= pow2_ogSize) {
    throw "value >= pow2_ogSize";
  }
  if (value >= pow2_ogSize / 2) {
    return (2 ** (newSize - ogSize) - 1) * pow2_ogSize + value;
  } else {
    return value;
  }
}

function signExtendBin(value, newSize) {
  newSize = newSize || 32;
  return value.padStart(newSize, value[0]);
}

function opDicts(ops, opNamesByCode) {
  opsByCode = {};
  opcodes = {};
  for (const opcode in opNamesByCode) {
    const opName = opNamesByCode[opcode];
    opsByCode[opcode] = ops[opName];
    opcodes[opName] = opcode;
  }
  return [opsByCode, opcodes];
}

function Operator() {
  self = this;
  this._rawOps = {
    add: (aa, bb) => aa + bb,
    sub: (aa, bb) => aa - bb,
    xor: (aa, bb) => aa ^ bb,
    or: (aa, bb) => aa | bb,
    and: (aa, bb) => aa & bb,
    sll: (aa, bb) => aa << fitToBits(bb, 5),
    srl: (aa, bb) => aa >>> fitToBits(bb, 5),
    sra: (aa, bb) => aa >> fitToBits(bb, 5),
    slt: (aa, bb) => (toSigned(aa) < toSigned(bb) ? 1 : 0),
    sltu: (aa, bb) => (aa < bb ? 1 : 0),
  };
  this._opWrapper = function (op) {
    function wrapped() {
      return fitToBits(op(...arguments));
    }
    return wrapped;
  };
  this.ops = {};
  for (const key in this._rawOps) {
    this.ops[key] = this._opWrapper(this._rawOps[key]);
  }
  this.opNamesByCode = {
    0: "add",
    1: "sub",
    2: "xor",
    3: "or",
    4: "and",
    5: "sll",
    6: "srl",
    7: "sra",
    8: "slt",
    9: "sltu",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  // aa, bb are two's complement 32 bit
  this.execute = function (opcode, aa, bb) {
    assertAllSize32(aa, bb);
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(aa, bb);
  };
}

function ImmLoader() {
  this.ops = {
    lui: (imm, pc) => imm, // << 12,
    auipc: (imm, pc) => pc + imm, // (imm << 12),
  };
  this.opNamesByCode = {
    0: "lui",
    1: "auipc",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  this.execute = function (opcode, imm, pc) {
    assertAllSize32(imm, pc);
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(imm, pc);
  };
}

function Jumper() {
  this.ops = {
    // out, pc
    jal: (rs1, imm, pc) => [pc + 4, pc + imm],
    jalr: (rs1, imm, pc) => [pc + 4, rs1 + imm],
  };
  this.opNamesByCode = {
    0: "jal",
    1: "jalr",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  this.execute = function (opcode, rs1, imm, pc) {
    assertAllSize32(rs1, imm, pc);
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(rs1, imm, pc);
  };
}

function Brancher() {
  this._branch = function (cmp, imm, pc, eq) {
    return cmp == 0 && eq ? pc + imm : pc + 4;
  };
  this._operator = new Operator();
  this._preops = {
    beq: this._operator.ops.sub,
    bne: this._operator.ops.sub,
    blt: this._operator.ops.slt,
    bge: this._operator.ops.slt,
    bltu: this._operator.ops.slt,
    bgeu: this._operator.ops.slt,
  };
  this.ops = {
    beq: (rs1, rs2, imm, pc) =>
      this._branch(this._preops.beq(rs1, rs2), imm, pc, 1),
    bne: (rs1, rs2, imm, pc) =>
      this._branch(this._preops.bne(rs1, rs2), imm, pc, 0),
    blt: (rs1, rs2, imm, pc) =>
      this._branch(this._preops.blt(rs1, rs2), imm, pc, 1),
    bge: (rs1, rs2, imm, pc) =>
      this._branch(this._preops.bge(rs1, rs2), imm, pc, 0),
    bltu: (rs1, rs2, imm, pc) =>
      this._branch(this._preops.bltu(rs1, rs2), imm, pc, 1),
    bgeu: (rs1, rs2, imm, pc) =>
      this._branch(this._preops.bgeu(rs1, rs2), imm, pc, 0),
  };
  this.opNamesByCode = {
    0: "beq",
    1: "bne",
    2: "blt",
    3: "bge",
    4: "bltu",
    5: "bgeu",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  this.execute = function (opcode, rs1, rs2, imm, pc) {
    assertAllSize32(rs1, rs2, imm, pc);
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(rs1, rs2, imm, pc);
  };
}

function ALU() {
  this.operator = new Operator();
  this.immLoader = new ImmLoader();
  this.jumper = new Jumper();
  this.brancher = new Brancher();
  this.insTypesByName = {
    operate: 0,
    loadImm: 1,
    jump: 2,
    branch: 3,
  };
  this.execute = function (
    rs1,
    rs2,
    imm,
    useImm,
    pc,
    iOpcode,
    fOpcode,
    eqOpcode
  ) {
    let pcOut = pc + 4;
    let out;
    if (iOpcode == 0) {
      const bb = useImm ? imm : rs2;
      out = this.operator.execute(fOpcode, rs1, bb);
    } else if (iOpcode == 1) {
      out = this.immLoader.execute(fOpcode, imm, pc);
    } else if (iOpcode == 2) {
      [out, pcOut] = this.jumper.execute(fOpcode, rs1, imm, pc);
    } else if (iOpcode == 3) {
      const cmp = this.operator.execute(fOpcode, rs1, rs2);
      pcOut = this.brancher._branch(cmp, imm, pc, eqOpcode);
      out = 0;
    } else {
      throw "iOpcode not valid";
    }
    return [out, pcOut];
  };
}

// TODO: abstract
function parseIns(ins) {
  const opcode = ins.slice(25, 32);
  const funct7 = parseInt(ins.slice(0, 7), 2);
  const rs2 = parseInt(ins.slice(7, 12), 2);
  const rs1 = parseInt(ins.slice(12, 17), 2);
  const funct3 = parseInt(ins.slice(17, 20), 2);
  const rd = parseInt(ins.slice(20, 25), 2);
  const imm20_31 = parseInt(ins.slice(0, 12), 2);
  const imm25_31__7_11 = parseInt(ins.slice(0, 7) + ins.slice(20, 25), 2);
  const imm12_31 = parseInt(ins.slice(0, 20), 2);
  return {
    opcode,
    funct7,
    rs2,
    rs1,
    funct3,
    rd,
    imm20_31,
    imm25_31__7_11,
    imm12_31,
    base: {
      rd,
      rs1,
      rs2,
      useImm: opcode[1] == "1" ? 0 : 1,
    },
  };
}

function decodeRIns(ins) {
  return {
    ...ins.base,
    imm: ins.imm20_31,
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}
function decodeIIns(ins) {
  return {
    ...ins.base,
    imm: signExtend(ins.imm20_31, 12, 32),
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeSIns(ins) {
  return {
    ...ins.base,
    imm: signExtend(ins.imm25_31__7_11, 12, 32),
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeBIns(ins) {
  return {
    ...ins.base,
    imm: signExtend(ins.imm25_31__7_11 * 2, 13, 32),
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeUIns(ins) {
  return {
    ...ins.base,
    imm: ins.imm12_31 * 2 ** 12,
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeJIns(ins) {
  return {
    ...ins.base,
    imm: signExtend(ins.imm12_31 * 2, 21, 32),
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeIns(ins) {
  if (ins.length != 32) {
    throw "ins length != 32";
  }
  opcode = ins.slice(32 - 7, 32);
  return {
    ".01100": decodeRIns,
    ".00100": decodeIIns,
    ".00000": decodeIIns,
    ".01000": decodeSIns,
    ".11000": decodeBIns,
    ".11011": decodeJIns,
    ".11001": decodeIIns,
    ".01101": decodeUIns,
    ".00101": decodeUIns,
  }["." + opcode.slice(0, 5)](parseIns(ins));
}

function propsTo32Bits(insData) {
  const newObj = {};
  for (const key in insData) {
    const value = fitToBits(Number(insData[key]), 32);
    newObj[key] = value.toString(2);
  }
  return newObj;
}

function encodeOperateIns(insDataBin) {
  // console.log(insDataBin);
  if (Number(insDataBin.useImm) == 0) {
    return (
      "0".repeat(7) +
      fitToBitsBin(insDataBin.rs2, 5) +
      fitToBitsBin(insDataBin.rs1, 5) +
      "0".repeat(3) +
      fitToBitsBin(insDataBin.rd, 5) +
      "0110011"
    );
  } else {
    return (
      fitToBitsBin(insDataBin.imm, 12) +
      fitToBitsBin(insDataBin.rs1, 5) +
      "0".repeat(3) +
      fitToBitsBin(insDataBin.rd, 5) +
      "0010011"
    );
  }
}

// TODO: check var size, abstract
function encodeIns(insType, insData) {
  const insDataBin = propsTo32Bits(insData);
  if (insType == "operate") {
    return encodeOperateIns(insDataBin, insData);
  }
}

module.exports = {
  Operator,
  ImmLoader,
  Jumper,
  Brancher,
  ALU,

  decodeIns,
  encodeIns,
};
