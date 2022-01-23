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

function Operator(bits) {
  self = this;
  bits = bits || 32;
  maxValueP1 = 2 ** bits;
  this._rawOps = {
    add: (aa, bb) => aa + bb,
    sub: (aa, bb) => aa - bb,
    xor: (aa, bb) => aa ^ bb,
    or: (aa, bb) => aa | bb,
    and: (aa, bb) => aa & bb,
    sll: (aa, bb) => aa << bb,
    srl: (aa, bb) => aa >>> bb,
    sra: (aa, bb) => aa >> bb,
    slt: (aa, bb) => (this._toSigned(aa) < this._toSigned(bb) ? 1 : 0),
    sltu: (aa, bb) => (aa < bb ? 1 : 0),
  };
  this._fitToBits = function (value) {
    value = value % maxValueP1;
    return value < 0 ? maxValueP1 + value : value;
  };
  this._toSigned = function (value) {
    if (value >= maxValueP1 / 2) {
      return -(maxValueP1 - value);
    } else {
      return value;
    }
  };
  this._opWrapper = function (op) {
    function wrapped() {
      return self._fitToBits(op(...arguments));
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
  // aa, bb are two's complement if negative
  this.execute = function (opcode, aa, bb) {
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(aa, bb);
  };
}

function ImmLoader(bits) {
  bits = bits || 32;
  this.ops = {
    lui: (imm, pc) => imm << 12,
    auipc: (imm, pc) => pc + (imm << 12),
  };
  this.opNamesByCode = {
    0: "lui",
    1: "auipc",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  this.execute = function (opcode, imm, pc) {
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(imm, pc);
  };
}

function Jumper(bits) {
  bits = bits || 32;
  this.ops = {
    jal: (rs1, imm, pc) => [pc + 4, pc + imm * 2],
    jalr: (rs1, imm, pc) => [pc + 4, rs1 + imm * 2],
  };
  this.opNamesByCode = {
    0: "jal",
    1: "jalr",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  this.execute = function (opcode, rs1, imm, pc) {
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(rs1, imm, pc);
  };
}

function Brancher(bits) {
  bits = bits || 32;
  this._branch = function (cmp, imm, pc, eq) {
    return cmp == 0 && eq ? pc + imm * 2 : pc + 4;
  };
  this._operator = new Operator(bits);
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
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(rs1, rs2, imm, pc);
  };
}

function ALU(bits) {
  bits = bits || 32;
  this.operator = new Operator(bits);
  this.immLoader = new ImmLoader(bits);
  this.jumper = new Jumper(bits);
  this.brancher = new Brancher(bits);
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

// function InsDecoder() {}

function _breakUpIns(ins) {
  return {
    opcode: ins.slice(25, 32),
    funct7: parseInt(ins.slice(0, 7), 2),
    rs2: parseInt(ins.slice(7, 12), 2),
    rs1: parseInt(ins.slice(12, 17), 2),
    funct3: parseInt(ins.slice(17, 20), 2),
    rd: parseInt(ins.slice(20, 25), 2),
    imm20_31: parseInt(ins.slice(0, 12), 2),
    imm25_31__7_11: parseInt(ins.slice(0, 7) + ins.slice(20, 25), 2),
    imm12_31: parseInt(ins.slice(0, 20), 2),
  };
}

function _getUseImm(ins) {
  return ins.opcode[1] == "1" ? 0 : 1;
}

function decodeRIns(ins) {
  return {
    rd: ins.rd,
    rs1: ins.rs1,
    rs2: ins.rs2,
    imm: ins.imm20_31,
    useImm: _getUseImm(ins), // should be 0
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}
function decodeIIns(ins) {
  return {
    rd: ins.rd,
    rs1: ins.rs1,
    rs2: ins.rs2,
    imm: ins.imm20_31,
    useImm: _getUseImm(ins), // should be 1
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeSIns(ins) {
  return {
    rd: ins.rd,
    rs1: ins.rs1,
    rs2: ins.rs2,
    imm: ins.imm25_31__7_11,
    useImm: _getUseImm(ins),
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeBIns(ins) {
  return {
    rd: ins.rd,
    rs1: ins.rs1,
    rs2: ins.rs2,
    imm: ins.imm25_31__7_11 * 2,
    useImm: _getUseImm(ins),
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeUIns(ins) {
  return {
    rd: ins.rd,
    rs1: ins.rs1,
    rs2: ins.rs2,
    imm: ins.imm12_31 * 2 ** 12,
    useImm: _getUseImm(ins),
    insOpcode: 0,
    funcOpcode: 0,
    eqOpcode: 0,
  };
}

function decodeJIns(ins) {
  return {
    rd: ins.rd,
    rs1: ins.rs1,
    rs2: ins.rs2,
    imm: ins.imm12_31 * 2,
    useImm: _getUseImm(ins),
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
  }["." + opcode.slice(0, 5)](_breakUpIns(ins));
}

function _propsToBin(insData) {
  const newObj = {};
  for (const key in insData) {
    newObj[key] = Number(insData[key]).toString(2);
  }
  return newObj;
}

function encodeOperateIns(insDataBin) {
  // console.log(insDataBin);
  if (Number(insDataBin.useImm) == 0) {
    return (
      "0".repeat(7) +
      insDataBin.rs2.padStart(5, "0") +
      insDataBin.rs1.padStart(5, "0") +
      "0".repeat(3) +
      insDataBin.rd.padStart(5, "0") +
      "0110011"
    );
  } else {
    return (
      insDataBin.imm.padStart(12, "0") +
      insDataBin.rs1.padStart(5, "0") +
      "0".repeat(3) +
      insDataBin.rd.padStart(5, "0") +
      "0110011"
    );
  }
}

// TODO: check var size, abstract
function encodeIns(insType, insData) {
  const insDataBin = _propsToBin(insData);
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
