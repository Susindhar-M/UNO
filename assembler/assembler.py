import math
import os
import sys

instruction_file = "instructions.s"
output_file = "instruction.mem"

# Field widths: [addr_1, addr_2, addr_3, jump, data]
width = [15, 15, 15, 11, 8]
total_width = sum(width)

if total_width != 64:
    sys.exit(f"Error: Bit-width sum is {total_width}, expected 64 bits.")

if not os.path.isfile(instruction_file):
    sys.exit(f"Error: File '{instruction_file}' not found.")

hex_width = math.ceil(total_width / 4)  # 16 hex digits
all_errors = []


# Pass 1: Parse labels and separate raw instructions

labels = {}
instructions = []  # List of tuples: (line_num, instr_address, raw_instruction_text)
current_address = 0

with open(instruction_file, "r") as infile:
    for line_num, raw_line in enumerate(infile, start=1):
        line = raw_line.split("#")[0].strip()
        if not line:
            continue

        # Handle label definitions (e.g. "loop:" or "loop: uno 0, 1, 2, loop, 0")
        while ":" in line:
            label_part, remaining = line.split(":", 1)
            label_name = label_part.strip()

            if not label_name.isidentifier():
                all_errors.append(f"Line {line_num}: Invalid label name '{label_name}'.")
            elif label_name in labels:
                all_errors.append(f"Line {line_num}: Duplicate label definition '{label_name}'.")
            else:
                labels[label_name] = current_address

            line = remaining.strip()

        if line:
            instructions.append((line_num, current_address, line))
            current_address += 1


# Pass 2: Assemble instructions and resolve fields

valid_hex_outputs = []

for line_num, addr, line in instructions:
    parts = line.split(maxsplit=1)
    opcode = parts[0]

    if opcode.lower() != "uno":
        all_errors.append(
            f"Line {line_num}: Unrecognized opcode '{opcode}'. Expected 'uno'."
        )
        continue

    if len(parts) < 2:
        all_errors.append(f"Line {line_num}: Missing operands for '{opcode}'.")
        continue

    fields = [f.strip() for f in parts[1].split(",") if f.strip()]

    if len(fields) != len(width):
        all_errors.append(
            f"Line {line_num}: Expected {len(width)} fields, but got {len(fields)}."
        )
        continue

    binary_fields = []
    line_has_error = False

    for i, (field, w) in enumerate(zip(fields, width), start=1):
        val = None

        # Field 4 is the Jump target: check if it's a label first
        if i == 4 and field in labels:
            val = labels[field]
        else:
            try:
                val = int(field, 0)
            except ValueError:
                all_errors.append(
                    f"Line {line_num}: Field {i} ('{field}') is not a valid integer or known label."
                )
                line_has_error = True
                continue

        # Field 5 is Data (allow signed -128..127 or unsigned 0..255)
        if i == 5:
            min_val = -(1 << (w - 1))
            max_val = (1 << w) - 1
            if val < min_val or val > max_val:
                all_errors.append(
                    f"Line {line_num}: Field {i} ({field} = {val}) out of range ({min_val} to {max_val})."
                )
                line_has_error = True
                continue
            if val < 0:
                val = (1 << w) + val  # 2's complement conversion
        else:
            # Address and Jump fields (strictly unsigned within field bit-width)
            max_val = (1 << w) - 1
            if val < 0 or val > max_val:
                all_errors.append(
                    f"Line {line_num}: Field {i} ({field} = {val}) out of range (0 to {max_val})."
                )
                line_has_error = True
                continue

        binary_fields.append(f"{val:0{w}b}")

    if not line_has_error:
        binary_str = "".join(binary_fields)
        hex_str = f"{int(binary_str, 2):0{hex_width}X}"
        valid_hex_outputs.append(hex_str)


# Error reporting and file output

if all_errors:
    print(f"\n[-] Assembly aborted with {len(all_errors)} error(s):")
    for err in all_errors:
        print(f"    {err}")
    sys.exit(1)

try:
    with open(output_file, "w") as mem_file:
        for out in valid_hex_outputs:
            mem_file.write(out + "\n")
    print(f"[+] Assembly successful: {len(valid_hex_outputs)} instructions written to '{output_file}'.")
except OSError as e:
    sys.exit(f"Error writing '{output_file}': {e}")