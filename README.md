# Uno-ISA: OISC Processor Core

An 8-bit One Instruction Set Computer (OISC) implemented in Verilog-2001, featuring a memory-to-memory 64-bit single-instruction format, a subtractive arithmetic execution pipeline, and a dedicated Python two-pass assembler.

---

## Architecture Overview

Uno executes a single instruction (`uno`) that performs memory reads, subtractive arithmetic, result writeback, and conditional PC manipulation in one unified execution flow.

### 1. Instruction Word Format (64-bit)

Each instruction word is packed into 64 bits across five fields:

```text
 63            49 48            34 33            19 18          8 7          0
+----------------+----------------+----------------+-------------+------------+
|  addr_1 (15b)  |  addr_2 (15b)  |  addr_3 (15b)  |  jump (11b) |  data (8b) |
+----------------+----------------+----------------+-------------+------------+
```

| Field    | Bits      | Width | Description                                                        |
|----------|-----------|-------|--------------------------------------------------------------------|
| `addr_1` | `[63:49]` | 15    | Data memory source address of operand 1                            |
| `addr_2` | `[48:34]` | 15    | Data memory source address of operand 2                            |
| `addr_3` | `[33:19]` | 15    | Data memory destination address for writeback                      |
| `jump`   | `[18:8]`  | 11    | Signed relative instruction offset (-1024 to +1023)                |
| `data`   | `[7:0]`   | 8     | Immediate 8-bit operand for the ALU (used as `operand_3`)          |

### 2. Execution Pipeline & Datapath

Execution is managed by an 8-state control FSM (`ctrl.v`):

```text
instr_adr -> instr_data -> op1_adr -> op1_data -> op2_adr -> op2_data -> str_adr -> str_data
```

1. **Instruction Fetch (`instr_adr`, `instr_data`):** Fetches the 64-bit instruction from byte-addressed memory using relative PC indexing.
2. **Operand Read (`op1_adr` to `op2_data`):** Sequentially reads `operand_1` from `addr_1` and `operand_2` from `addr_2` into internal registers.
3. **Execution & Comparison:**
   * **Arithmetic:** `alu_out = operand_1 - operand_2 - operand_3`, where `operand_3` is the immediate `data` field.
   * **Branch evaluation:** `jmp_flg = (operand_1 > operand_2)`.
4. **Writeback (`str_adr`, `str_data`):** Asserts write enable (`data_we`) and writes `alu_out` to `addr_3`.
5. **Program Counter Update:**

   ```text
   pc_out <= pc_out + ((jmp_flg ? jump : 1) << 3)
   ```

   The PC indexes byte-addressable instruction memory, so every instruction step is scaled by 8 bytes (64 bits per instruction). The `jump` field is sign-extended before scaling.

---

## Subtractive Computation Model

Because every instruction performs subtractive arithmetic and writes the result back to memory, common operations are synthesized as follows (address `0x0000` is assumed to hold the constant `0`):

| Operation        | Computation             | Notes                                          |
|------------------|-------------------------|------------------------------------------------|
| Negation (-A)    | `0 - A - 0 = -A`        | `operand_1` = zero, `data` = 0                 |
| Addition (P + A) | `P - (-A) - 0 = P + A`  | Uses the previously negated value of A         |
| Decrement (B - 1)| `B - 0 - 1 = B - 1`     | `operand_2` = zero, immediate `data = 1`       |

**Zero preservation:** Instructions used only for branching or comparison direct `addr_3` to an unmapped or temporary scratch address so that `0x0000` is never overwritten.

---

## Repository Structure

```text
Uno_ISA/
├── README.md
├── assembler/
│   ├── assembler.py      # Two-pass Python assembler for Uno ISA
│   └── README.md
└── rtl/
    ├── alu.v             # Subtractive ALU with comparison flag
    ├── core.v            # Top-level processor core integration
    ├── ctrl.v            # Main FSM controller
    ├── mux_2x1.v         # Parameterized 2-to-1 multiplexer
    ├── pc.v              # Signed relative program counter with byte scaling
    └── reg_en.v          # Parameterized register with enable
```
