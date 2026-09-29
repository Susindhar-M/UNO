#!/usr/bin/env python3
import argparse
import sys
import re


# Handles octal, binary, and hexadecimal integer parsing
def parse_int(val_str):    
    val_str = val_str.strip().lower()
    try:
        if val_str.startswith('0x') or val_str.startswith('-0x'):
            return int(val_str, 16)
        elif val_str.startswith('0b') or val_str.startswith('-0b'):
            return int(val_str, 2)
        elif val_str.startswith('0o') or val_str.startswith('-0o'):
            return int(val_str, 8)
        return int(val_str)
    except ValueError:
        return None

def main():
    parser = argparse.ArgumentParser(description="Uno ISA 64-bit Assembler")
    parser.add_argument("input", nargs='?', default="instructions.s", help="Input assembly file (.s)")
    parser.add_argument("-o", "--output", default="instruction.mem", help="Output hex file (.mem)")
    args = parser.parse_args()

    try:
        with open(args.input, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Could not open {args.input}")
        sys.exit(1)

    labels = {}
    instructions = []
    

    # Extract labels and clean instructions

    addr = 0
    for line_num, line in enumerate(lines, start=1):
        clean_line = line.split('#')[0].strip()
        if not clean_line:
            continue
            
        if clean_line.endswith(':'):
            label_name = clean_line[:-1].strip()
            labels[label_name] = addr
        else:
            instructions.append((line_num, addr, clean_line))            
            addr += 1

   
    # Parse operands, resolve labels, pack bits
    
    machine_code = []
    errors = []

    for line_num, current_addr, instr_str in instructions:
        match = re.match(r'^uno\s+(.+)$', instr_str, re.IGNORECASE)
        if not match:
            errors.append(f"Line {line_num}: Invalid syntax. Expected 'uno <op1>, <op2>, <op3>, <op4>, <op5>'")
            continue
            
        operands = [op.strip() for op in match.group(1).split(',')]
        if len(operands) != 5:
            errors.append(f"Line {line_num}: Expected 5 operands, got {len(operands)}")
            continue

        vals = [0] * 5
        
        for i, op in enumerate(operands):
            if i == 3 and op in labels:               
                vals[i] = labels[op] - current_addr                
                continue
                
            val = parse_int(op)
            if val is None:
                errors.append(f"Line {line_num}: Invalid number or undefined label '{op}'")
                continue
            vals[i] = val

        line_has_error = False
        
        for i in range(3):
            if not (0 <= vals[i] <= 32767):
                errors.append(f"Line {line_num}: Field {i+1} ({vals[i]}) out of range (0 to 32767)")
                line_has_error = True
                
        if not (-1024 <= vals[3] <= 1023):
            errors.append(f"Line {line_num}: Jump offset ({vals[3]}) out of range (-1024 to 1023)")
            line_has_error = True
            
        if not (-128 <= vals[4] <= 255):
            errors.append(f"Line {line_num}: Immediate data ({vals[4]}) out of range (-128 to 255)")
            line_has_error = True

        if line_has_error:
            continue

        addr_1 = vals[0] & 0x7FFF
        addr_2 = vals[1] & 0x7FFF
        addr_3 = vals[2] & 0x7FFF
        jump   = vals[3] & 0x7FF
        data   = vals[4] & 0xFF

        word = (addr_1 << 49) | (addr_2 << 34) | (addr_3 << 19) | (jump << 8) | data
        machine_code.append(f"{word:016X}")

    if errors:
        print("Assembly failed with errors:")
        for err in errors:
            print(f"  [-] {err}")
        sys.exit(1)

    with open(args.output, 'w') as f:
        for code in machine_code:
            f.write(code + '\n')
            
    print(f"Successfully assembled {len(machine_code)} instructions to {args.output}")

if __name__ == "__main__":
    main()