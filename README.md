# Asylum Utils Package

## Table of Contents

1. [Introduction](#introduction)
2. [VHDL Utility Modules](#vhdl-utility-modules)
   - [Convert Package](#convert-package)
   - [Logic Package](#logic-package)
   - [Math Package](#math-package)
   - [PBI Package](#pbi-package)
   - [SBI Package](#sbi-package)
   - [String Package](#string-package)

---

## Introduction

The **Asylum Utils Package** is a comprehensive collection of VHDL utility packages designed to provide reusable functions and components for digital design and hardware description. This package includes mathematical functions, logical operations, data type conversions, string comparisons, and protocol support for Parallel Byte Interface (PBI) and Serial Byte Interface (SBI) standards.

### Features

- **Modular Design**: Organized into specialized packages for different functional areas
- **VHDL'93/02 Compatible**: Written to standard VHDL with IEEE library support
- **Reusable Components**: Functions and record types that can be easily integrated into larger designs
- **Protocol Support**: Includes PBI and SBI interface definitions for system integration

---

## VHDL Utility Modules

### Convert Package

**File**: `hdl/convert_pkg.vhd`

The Convert Package provides functions for converting between different data types and formats.

#### Functions

| Function | Input(s) | Output | Description |
|----------|----------|--------|-------------|
| `to_stdulogic` | `V: boolean` | `std_ulogic` | Converts a boolean value to standard logic (`'1'` for true, `'0'` for false) |
| `onehot_to_integer` | `one_hot: std_logic_vector` | `integer` | Converts a one-hot encoded vector to an integer index. Returns -1 if the input is invalid (multiple bits set or no bits set) |

#### Description

This package facilitates type conversions commonly needed in VHDL designs. The `to_stdulogic` function is useful for converting boolean logic to standard logic levels, while the `onehot_to_integer` function supports the decoding of one-hot encoded signals, which are commonly used in priority encoders and state machines.

---

### Logic Package

**File**: `hdl/logic_pkg.vhd`

The Logic Package provides functions for logical operations on vectors.

#### Functions

| Function | Input(s) | Output | Description |
|----------|----------|--------|-------------|
| `reduce_xor` | `x: std_logic_vector` | `std_logic` | Performs reduction XOR (parity) on all bits of the input vector |
| `reduce_and` | `x: std_logic_vector` | `std_logic` | Performs reduction AND on all bits of the input vector |
| `reduce_or` | `x: std_logic_vector` | `std_logic` | Performs reduction OR on all bits of the input vector |
| `mux2` | `sel: boolean`, `d_true`, `d_false: std_logic_vector` | `std_logic_vector` | 2-to-1 multiplexer: selects `d_true` if sel is true, `d_false` otherwise |
| `reverse_bits` | `v: std_logic_vector` | `std_logic_vector` | Reverses the bit order of the input vector |

#### Description

The Logic Package provides fundamental logical reduction and manipulation functions. The reduction functions are essential for parity checking and status evaluation. The `mux2` function provides a vector-aware multiplexer, while `reverse_bits` is useful for endianness conversion and bit reordering operations.

---

### Math Package

**File**: `hdl/math_pkg.vhd`

The Math Package provides mathematical functions commonly used in hardware design.

#### Functions

| Function | Input(s) | Output | Description |
|----------|----------|--------|-------------|
| `log2` | `i: natural` | `integer` | Calculates the logarithm base 2 of the input (floor) |
| `clog2` | `i: natural` | `integer` | Calculates the ceiling of logarithm base 2 (useful for calculating required bit widths) |
| `max` | `x1, x2: integer` | `integer` | Returns the maximum of two integers (alias for `max2`) |
| `max2` | `x1, x2: integer` | `integer` | Returns the maximum of two integers |
| `min` | `x1, x2: integer` | `integer` | Returns the minimum of two integers (alias for `min2`) |
| `min2` | `x1, x2: integer` | `integer` | Returns the minimum of two integers |

#### Description

The Math Package is essential for parametric hardware design. The logarithmic functions (`log2` and `clog2`) are used to calculate the number of bits required to represent a range of values, which is critical for defining bus widths and memory depths. The min/max functions are used for constraint checking and optimization calculations.

**Note**: `clog2` (ceiling log2) is preferred for bit width calculations, as it ensures the width is sufficient to represent all values up to the input.

---

### PBI Package

**File**: `hdl/pbi_pkg.vhd`

The Parallel Byte Interface (PBI) Package defines record types and operations for a synchronous parallel interface protocol.

#### Type Definitions

**Constants**:

| Constant | Value | Description |
|----------|-------|-------------|
| `PBI_ADDR_WIDTH` | 8 | Address bus width in bits |
| `PBI_DATA_WIDTH` | 8 | Data bus width in bits |

**Record Types**:

**`pbi_ini_t`** - Initiator-side signals:

| Field | Type | Description |
|-------|------|-------------|
| `cs` | `std_logic` | Chip Select (READ_STROBE or WRITE_STROBE) |
| `re` | `std_logic` | Read Enable / Read Strobe |
| `we` | `std_logic` | Write Enable / Write Strobe |
| `addr` | `std_logic_vector` | Address bus |
| `wdata` | `std_logic_vector` | Write Data |

**`pbi_tgt_t`** - Target-side signals:

| Field | Type | Description |
|-------|------|-------------|
| `busy` | `std_logic` | Busy flag (indicates the target is busy and cannot accept new requests) |
| `rdata` | `std_logic_vector` | Read Data |

**Array Types**:

| Type | Description |
|------|-------------|
| `pbi_inis_t` | Array of PBI initiator signals |
| `pbi_tgts_t` | Array of PBI target signals |
| `pbi_addrs_t` | Array of addresses |
| `pbi_datas_t` | Array of data words |
| `naturals_t` | Array of natural numbers |

#### Functions

| Function | Operands | Return Type | Description |
|----------|----------|-------------|-------------|
| `"and"` | `pbi_ini_t, pbi_ini_t` | `pbi_ini_t` | Bitwise AND of two initiator signals |
| `"or"` | `pbi_ini_t, pbi_ini_t` | `pbi_ini_t` | Bitwise OR of two initiator signals |
| `"xor"` | `pbi_ini_t, pbi_ini_t` | `pbi_ini_t` | Bitwise XOR of two initiator signals |
| `"and"` | `pbi_tgt_t, pbi_tgt_t` | `pbi_tgt_t` | Bitwise AND of two target signals |
| `"or"` | `pbi_tgt_t, pbi_tgt_t` | `pbi_tgt_t` | Bitwise OR of two target signals |
| `"xor"` | `pbi_tgt_t, pbi_tgt_t` | `pbi_tgt_t` | Bitwise XOR of two target signals |
| `"or"` | `pbi_tgts_t` | `pbi_tgt_t` | Reduction OR over an array of target signals |

#### Description

The PBI Package defines a parallel, byte-oriented interface suitable for synchronous communication between components. The protocol supports independent read and write operations with a `busy` signal for handshaking. The overloaded logical operators (`and`, `or`, `xor`) enable multiplexing and arbitration logic to be implemented concisely.

**Protocol Operation**:
- **Write Transaction**: Set `we='1'`, provide address on `addr`, provide data on `wdata`, set `cs='1'`
- **Read Transaction**: Set `re='1'`, provide address on `addr`, set `cs='1'`, receive data on `rdata`
- **Busy Handling**: If `busy='1'`, the target cannot accept new transactions

---

### SBI Package

**File**: `hdl/sbi_pkg.vhd`

The Serial Byte Interface (SBI) Package is a variant of the PBI protocol that replaces the `busy` signal with a `ready` signal.

#### Type Definitions

**Constants**:

| Constant | Value | Description |
|----------|-------|-------------|
| `SBI_ADDR_WIDTH` | 8 | Address bus width in bits |
| `SBI_DATA_WIDTH` | 8 | Data bus width in bits |

**Record Types**:

**`sbi_ini_t`** - Initiator-side signals:

| Field | Type | Description |
|-------|------|-------------|
| `cs` | `std_logic` | Chip Select (READ_STROBE or WRITE_STROBE) |
| `re` | `std_logic` | Read Enable / Read Strobe |
| `we` | `std_logic` | Write Enable / Write Strobe |
| `addr` | `std_logic_vector` | Address bus |
| `wdata` | `std_logic_vector` | Write Data |

**`sbi_tgt_t`** - Target-side signals:

| Field | Type | Description |
|-------|------|-------------|
| `ready` | `std_logic` | Ready flag (indicates the target is ready to accept new requests) |
| `rdata` | `std_logic_vector` | Read Data |

**Array Types**:

| Type | Description |
|------|-------------|
| `sbi_inis_t` | Array of SBI initiator signals |
| `sbi_tgts_t` | Array of SBI target signals |
| `sbi_addrs_t` | Array of addresses |
| `sbi_datas_t` | Array of data words |
| `naturals_t` | Array of natural numbers |

#### Functions

| Function | Operands | Return Type | Description |
|----------|----------|-------------|-------------|
| `"and"` | `sbi_ini_t, sbi_ini_t` | `sbi_ini_t` | Bitwise AND of two initiator signals |
| `"or"` | `sbi_ini_t, sbi_ini_t` | `sbi_ini_t` | Bitwise OR of two initiator signals |
| `"xor"` | `sbi_ini_t, sbi_ini_t` | `sbi_ini_t` | Bitwise XOR of two initiator signals |
| `"and"` | `sbi_tgt_t, sbi_tgt_t` | `sbi_tgt_t` | Bitwise AND of two target signals |
| `"or"` | `sbi_tgt_t, sbi_tgt_t` | `sbi_tgt_t` | Bitwise OR of two target signals |
| `"xor"` | `sbi_tgt_t, sbi_tgt_t` | `sbi_tgt_t` | Bitwise XOR of two target signals |
| `"or"` | `sbi_tgts_t` | `sbi_tgt_t` | Reduction OR over an array of target signals |

#### Description

The SBI Package is similar to the PBI Package but uses a `ready` signal instead of a `busy` signal. The semantics are inverted:
- **PBI**: `busy='1'` means the target is busy (cannot accept transactions)
- **SBI**: `ready='1'` means the target is ready (can accept transactions)

This version may be preferred in designs where the ready/valid protocol is more natural. The overloaded logical operators support the same multiplexing and arbitration patterns as PBI.

**Protocol Operation**:
- **Write Transaction**: Set `we='1'`, provide address on `addr`, provide data on `wdata`, set `cs='1'`
- **Read Transaction**: Set `re='1'`, provide address on `addr`, set `cs='1'`, receive data on `rdata`
- **Ready Handling**: If `ready='0'`, the target cannot accept new transactions

---

### String Package

**File**: `hdl/string_pkg.vhd`

The String Package provides functions for string comparisons.

#### Functions

| Function | Input(s) | Output | Description |
|----------|----------|--------|-------------|
| `string_eq` | `str1, str2: string` | `boolean` | Returns true if the two strings are equal (case-sensitive) |
| `string_ne` | `str1, str2: string` | `boolean` | Returns true if the two strings are not equal (case-sensitive) |

#### Description

The String Package provides string comparison functions for VHDL. These functions are useful for:
- Generic parameter validation
- Configuration string matching
- Behavior selection in testbenches

The functions perform exact, case-sensitive comparisons and check string length as part of the equality test.

---

## Project Structure

```
asylum-utils-pkg/
├── README.md              # This file
├── utils_pkg.core         # FuseSoC core file for synthesis integration
└── hdl/                   # VHDL source files
    ├── convert_pkg.vhd    # Data type conversion functions
    ├── logic_pkg.vhd      # Logical operations and reductions
    ├── math_pkg.vhd       # Mathematical functions
    ├── pbi_pkg.vhd        # Parallel Byte Interface protocol
    ├── sbi_pkg.vhd        # Serial Byte Interface protocol
    └── string_pkg.vhd     # String comparison functions
```

## Usage

To use this package in your VHDL designs, include the desired packages in your use clauses:

```vhdl
library ieee;
use ieee.std_logic_1164.all;

-- Include utility packages
use work.convert_pkg.all;
use work.logic_pkg.all;
use work.math_pkg.all;
use work.pbi_pkg.all;
use work.sbi_pkg.all;
use work.string_pkg.all;
```
