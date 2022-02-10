Name ideas:
- Jellyfish
- Medusa
- Squid
- Kraken

Testing arch
- Implement VM in js in parts and test circom circuits separately and end-to-end in single and multiple steps.
- Test js machine end to end against output of fast rv32im emulator.
    - (Then, port the emulator to wasm.)

Notes:
- Feb 7, 2022: When using non-merkleized memory, does it make sense to distinguishing between memory and registers? (other than for RISC-V compatibility)
    - Could put it all in the same array and save some load/stores.
    - Would not be possible to address registers with a 5-bit address.