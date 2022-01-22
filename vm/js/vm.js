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
    jal: (rs1, imm, pc) => [pc + 1, pc + imm],
    jalr: (rs1, imm, pc) => [pc + 1, rs1 + imm],
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
    return cmp == 0 && eq ? pc + imm : pc + 1;
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

module.exports = {
  Operator,
  ImmLoader,
  Jumper,
  Brancher,
};
