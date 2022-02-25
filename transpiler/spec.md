C code -> Risc-V binary -> zkRiscV binary

Transpilation: All multi-byte load/store operations have to be replaced by multi-instruction implementations that only make use of 1 byte store/load. References to memory positions (e.g., jumps) have to be updated to accommodate the extra instructions.
