# Uno ISA Assembler

A two-pass Python assembler that translates Uno ISA assembly source into 64-bit hex machine words for simulation or memory initialization.

---

## Usage

```bash
python3 assembler.py [input.s] [-o output.mem]
```

| Argument         | Default            | Description                          |
|------------------|---------------------|---------------------------------------|
| `input`          | `instructions.s`    | Path to the assembly source file      |
| `-o`, `--output` | `instruction.mem`   | Path to the generated hex output file |

Example:

```bash
python3 assembler.py instructions.s -o instruction.mem
```

---

## Source Syntax

Each instruction line has the form:

```text
uno addr_1, addr_2, addr_3, jump, data
```

* **`addr_1`, `addr_2`, `addr_3`** — 15-bit unsigned data memory addresses (source, source, destination).
* **`jump`** — signed relative instruction offset. May be a literal number or a label; when a label is given, it is resolved to `label_address - current_address`.
* **`data`** — 8-bit immediate operand for the ALU.

Numbers may be written in decimal, or with `0x` (hex), `0b` (binary), or `0o` (octal) prefixes; a leading `-` is supported for negative values.

**Labels** are declared on their own line, ending in `:`:

```text
loop:
uno 0, 1, 2, loop, 0
```

A label's address is the index of the next instruction (labels don't consume an address themselves). Full-line and end-of-line comments start with `#`.

---

## Two-Pass Assembly

1. **Pass 1 — label collection:** the file is scanned line by line; label declarations are recorded against the address of the following instruction, and instruction lines are collected with their address.
2. **Pass 2 — encoding:** each instruction's operands are parsed, labels are resolved into relative jump offsets, all fields are range-checked, and the fields are packed into a 64-bit word.

---

## Field Packing

```text
 63            49 48            34 33            19 18          8 7          0
+----------------+----------------+----------------+-------------+------------+
|  addr_1 (15b)  |  addr_2 (15b)  |  addr_3 (15b)  |  jump (11b) |  data (8b) |
+----------------+----------------+----------------+-------------+------------+
```

Each output line is the 64-bit word written as 16 uppercase hex digits (zero-padded), one instruction per line.

---

## Valid Ranges

| Field                | Range            |
|-----------------------|-------------------|
| `addr_1`, `addr_2`, `addr_3` | 0 to 32767 |
| `jump`                | -1024 to 1023     |
| `data`                | -128 to 255       |

Values outside these ranges are reported as errors and the file is not written. Negative `jump` and `data` values are stored as their two's-complement bit pattern (masked to 11 and 8 bits respectively).

---

## Error Handling

The assembler collects errors rather than stopping at the first one, and reports all of them together. Checks include:

* Lines that don't match the `uno <op1>, <op2>, <op3>, <op4>, <op5>` syntax.
* A line with a number of operands other than 5.
* An operand that isn't a valid number and isn't a defined label.
* Any field value outside its valid range (see table above).

If any errors are found, no output file is written and the assembler exits with status code 1, printing each error prefixed with `[-]`. On success, it prints the number of instructions assembled and the output path.

---

## Known Limitations

* Only the `jump` field (5th operand) can be given as a label — `addr_1`, `addr_2`, and `addr_3` must be numeric literals.
* An operand that fails to parse is recorded as an error, but assembly continues using a default value of `0` for that field internally; combined with a later out-of-range check, a single bad operand can produce more than one error message for the same line.