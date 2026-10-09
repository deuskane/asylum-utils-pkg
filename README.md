<!--
  README GENERATION INSTRUCTIONS (for the next regeneration run)
  ----------------------------------------------------------------
  This README follows the common Asylum IP model. Regenerate it from the
  sources, never from the previous README text alone.

  Sources of truth (in priority order):
    1. hdl/*.vhd            : entities, generics, ports, packages
    2. hdl/csr/*.hjson      : register map (regtool); *_csr.md/.h are generated
    3. <IP>.core            : VLNV (name), filesets, targets, depends, revisions
    4. mk/targets.txt       : target list shown by `make help`; mk/defs.mk
    5. sim/, syn/, esw/, boards/ : testbenches, constraints, software
  Section order (keep it, same headings in every IP):
    CI badge / Title + one-line description + VLNV / Table of Contents /
    Introduction (Key Features) / Block Diagram / Top-Level (Parameters,
    Ports, Instantiation Example) / HDL Modules / Register Map /
    Verification / Synthesis / Design Notes (optional) /
    Directory Structure / Dependencies
  Rules:
    - Language: English. Tables: Parameters = Name|Type|Default|Description,
      Ports = Name|Direction|Type|Description (grouped by interface).
    - Register Map: link to the generated hdl/csr/<X>_csr.md (plus the
      .hjson source and _csr.h header); never copy register tables here.
    - Top-Level = sbi_* wrapper if present, else the entity used by the
      `default` target, else the main entity (libraries: list packages).
    - Write "This IP has no software-visible registers." / "No dedicated
      synthesis target ..." instead of removing a section.
    - Keep still-accurate hand-written content (ISA tables, results,
      images) in "Design Notes"; drop anything not backed by the sources.
    - Block diagram: doc/<NAME>.drawio (NAME = 4th field of the VLNV),
      top entity box with generics on top, inputs left, outputs right,
      bus interfaces as bold arrows, internal blocks colour-coded
      (CSR yellow, FIFO/memory green, core logic blue, external grey).
      Update it whenever ports/generics/sub-blocks change.
    - Do not edit generated files (hdl/csr/*_csr.*) or the CI badge URL.
-->
[![CI](https://github.com/deuskane/asylum-utils-pkg/actions/workflows/ci.yml/badge.svg)](https://github.com/deuskane/asylum-utils-pkg/actions/workflows/ci.yml)

# asylum-utils-pkg

**VHDL utility library of the Asylum project: math / logic / conversion / string helpers, SBI and PBI bus records, and fault-tolerance (parity, TMR, ECC) encoders, decoders and protected register.**

VLNV: `asylum:utils:pkg:1.8.0`

## Table of Contents

1. [Introduction](#introduction)
2. [Block Diagram](#block-diagram)
3. [Top-Level](#top-level)
4. [HDL Modules](#hdl-modules)
5. [Register Map](#register-map)
6. [Verification](#verification)
7. [Synthesis](#synthesis)
8. [Design Notes](#design-notes)
9. [Directory Structure](#directory-structure)
10. [Dependencies](#dependencies)

## Introduction

This repository is a library, not a block with a single top-level. It is compiled in library `asylum` and is a dependency of almost every Asylum IP: `sbi_pkg` defines the SBI bus records used by all CSR banks, `math_pkg` / `logic_pkg` / `convert_pkg` / `string_pkg` provide elaboration-time and RTL helper functions, and the `ft_*` units implement fault-tolerance codes (parity, triple modular redundancy, SEC-DED Hamming ECC) usable as functions or as entities. The `default` target also compiles copies of the IEEE VITAL packages in a separate library `IEEE_dummy`, used by the vendor flash models of `asylum-communication-spi`.

### Key Features

- `sbi_pkg`: SBI initiator / target records with unconstrained `addr` / `wdata` / `rdata`, target `info.name` field, array types, null-record functions and bitwise / reduction operators to build interconnects
- `pbi_pkg`: older PBI records (`busy` instead of `ready`), same operator set
- `types_pkg`: common types (`naturals_t`), re-exported by `sbi_pkg` and `pbi_pkg` through aliases so that both packages can be used together
- `math_pkg`: `log2`, `clog2`, `min` / `max`, `is_pow2`
- `logic_pkg`: reductions, `count_ones`, `mux2` (vector and natural), `reverse_bits`, generic array types `sls_t` / `slvs_t`
- `convert_pkg`: `to_stdulogic`, `to_slv`, `onehot_to_integer`
- `string_pkg`: `string_eq`, `string_ne`, `to_string` for `std_logic` and `std_logic_vector`
- `ft_pkg`: `encoded_size` / `decoded_size` / `encode` / `decode` for `NONE`, `PARITY_ODD`, `PARITY_EVEN`, `TMR`, `ECC`, selectable by enumeration (`ft_algo_t`) or by overloading type
- `ft_enc`, `ft_dec`, `ft_dff`: entity wrappers (combinational encoder / decoder, protected register)
- UVVM self-checking testbenches for every FT algorithm, for `ft_dff` (reset, self refresh, fault injection) and for `logic_pkg`; NanoXplore NG-MEDIUM synthesis targets for `ft_dff`
- VHDL-2008 (`file_type: vhdlSource-2008`)

## Block Diagram

Diagram: [doc/pkg.drawio](doc/pkg.drawio) (open with diagrams.net or the VS Code Draw.io extension).

- The library box contains every compilation unit of `hdl/` plus the synthesis wrapper `syn/top_ft_dff.vhd`; the ports drawn are those of `ft_dff`, the main reusable entity.
- `ft_dff` = `ft_enc` (encode `data_i`) + register of `encoded_size(WIDTH, FT_ALGO)` bits + `ft_dec` (decode, raise `error_detected_o` / `error_corrected_o`).
- `ft_enc` / `ft_dec` are thin wrappers around the `encode` / `decode` subprograms of `ft_pkg`, whose body uses `math_pkg` (`clog2`, `is_pow2`) and `logic_pkg`.
- `top_ft_dff` adds input and output registers around `ft_dff` for the `emu_ng_medium_ft_dff_*` synthesis targets.
- `types_pkg` declares `naturals_t` once; `sbi_pkg` and `pbi_pkg` re-export it with an alias.
- `IEEE_dummy` (grey) holds the VITAL timing / primitives copies, independent from the rest.

## Top-Level

Library IP: there is no single top-level. Units compiled by the `default` target:

| Unit | Kind | File | Description |
|------|------|------|-------------|
| `convert_pkg` | package | [hdl/convert_pkg.vhd](hdl/convert_pkg.vhd) | Type conversion functions |
| `logic_pkg` | package | [hdl/logic_pkg.vhd](hdl/logic_pkg.vhd) | Logic reductions, mux, bit reversal, array types |
| `math_pkg` | package | [hdl/math_pkg.vhd](hdl/math_pkg.vhd) | Integer math for generics |
| `types_pkg` | package | [hdl/types_pkg.vhd](hdl/types_pkg.vhd) | Common types (`naturals_t`) |
| `pbi_pkg` | package | [hdl/pbi_pkg.vhd](hdl/pbi_pkg.vhd) | PBI bus records and operators |
| `sbi_pkg` | package | [hdl/sbi_pkg.vhd](hdl/sbi_pkg.vhd) | SBI bus records and operators |
| `string_pkg` | package | [hdl/string_pkg.vhd](hdl/string_pkg.vhd) | String comparison and conversion |
| `ft_pkg` | package (+ body) | [hdl/ft_pkg.vhd](hdl/ft_pkg.vhd), [hdl/ft_pkg_body.vhd](hdl/ft_pkg_body.vhd) | Fault-tolerance types, size / encode / decode subprograms, components |
| `ft_enc` | entity | [hdl/ft_enc.vhd](hdl/ft_enc.vhd) | Combinational FT encoder |
| `ft_dec` | entity | [hdl/ft_dec.vhd](hdl/ft_dec.vhd) | Combinational FT decoder with status |
| `ft_dff` | entity | [hdl/ft_dff.vhd](hdl/ft_dff.vhd) | FT-protected register (main reusable entity) |
| `VITAL_Timing`, `VITAL_Primitives` | packages (library `IEEE_dummy`) | [hdl/vital/](hdl/vital/) | Copies of the IEEE 1076.4 VITAL packages |

The parameters and ports below are those of `ft_dff`.

### Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `WIDTH` | natural | `32` | Width of the protected data |
| `FT_ALGO` | ft_algo_t | `USE_NONE` | Protection: `USE_NONE`, `USE_PARITY_ODD`, `USE_PARITY_EVEN`, `USE_TMR`, `USE_ECC` |
| `SELF_REFRESH` | boolean | `false` | `true`: when `we_i = 0` and the decoder corrected an error, the register reloads the re-encoded corrected value (scrubbing); `false`: it keeps its encoded value (see Design Notes) |

### Ports

#### Clock & Reset

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | Clock |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low (encoded register loaded with the code word of an all-zero data) |

#### Data

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `we_i` | in | std_logic | Write enable: load `encode(data_i)` on the next rising edge |
| `data_i` | in | std_logic_vector(WIDTH-1 downto 0) | Data to store |
| `data_o` | out | std_logic_vector(WIDTH-1 downto 0) | Decoded (corrected when possible) stored data |

#### Status

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `error_detected_o` | out | std_logic | The stored word is not a valid code word |
| `error_corrected_o` | out | std_logic | The error was corrected on `data_o` (TMR, ECC single error) |

### Instantiation Example

```vhdl
library asylum;
use     asylum.math_pkg.all;
use     asylum.sbi_pkg.all;
use     asylum.ft_pkg.all;

  constant ADDR_WIDTH : natural := clog2(NB_TARGET);       -- math_pkg

  signal   tgt_sel    : sbi_tgt_t(rdata(SBI_DATA_WIDTH-1 downto 0));

  -- Read-data / ready multiplexing of an SBI interconnect (sbi_pkg reduction "or")
  tgt_sel <= "or"(sbi_tgts);

  -- ECC-protected 32-bit configuration register
  ins_ft_dff : entity asylum.ft_dff
    generic map
    ( WIDTH             => 32
     ,FT_ALGO           => USE_ECC
     ,SELF_REFRESH      => false
    )
    port map
    ( clk_i             => clk
     ,arst_b_i          => arst_b
     ,we_i              => cfg_we
     ,data_i            => cfg_wdata
     ,data_o            => cfg
     ,error_detected_o  => cfg_err_detected
     ,error_corrected_o => cfg_err_corrected
    );
```

## HDL Modules

| File | Unit | Kind | Role |
|------|------|------|------|
| [hdl/convert_pkg.vhd](hdl/convert_pkg.vhd) | `convert_pkg` | package | Conversions |
| [hdl/logic_pkg.vhd](hdl/logic_pkg.vhd) | `logic_pkg` | package | Logic functions and array types |
| [hdl/math_pkg.vhd](hdl/math_pkg.vhd) | `math_pkg` | package | Math functions |
| [hdl/types_pkg.vhd](hdl/types_pkg.vhd) | `types_pkg` | package | Common types |
| [hdl/pbi_pkg.vhd](hdl/pbi_pkg.vhd) | `pbi_pkg` | package | PBI bus |
| [hdl/sbi_pkg.vhd](hdl/sbi_pkg.vhd) | `sbi_pkg` | package | SBI bus |
| [hdl/string_pkg.vhd](hdl/string_pkg.vhd) | `string_pkg` | package | Strings |
| [hdl/ft_pkg.vhd](hdl/ft_pkg.vhd) | `ft_pkg` | package | FT declarations and components `ft_enc`, `ft_dec`, `ft_dff` |
| [hdl/ft_pkg_body.vhd](hdl/ft_pkg_body.vhd) | `ft_pkg` | package body | FT algorithms |
| [hdl/ft_enc.vhd](hdl/ft_enc.vhd) | `ft_enc` | entity | `data_o <= encode(data_i, FT_ALGO)` |
| [hdl/ft_dec.vhd](hdl/ft_dec.vhd) | `ft_dec` | entity | `decode` procedure in a `process (all)` |
| [hdl/ft_dff.vhd](hdl/ft_dff.vhd) | `ft_dff` | entity | `ft_enc` + register + `ft_dec` |
| [hdl/vital/vital_timing.vhdl](hdl/vital/vital_timing.vhdl) + [-body](hdl/vital/vital_timing-body.vhdl) | `VITAL_Timing` | package + body | Library `IEEE_dummy` |
| [hdl/vital/vital_primitives.vhdl](hdl/vital/vital_primitives.vhdl) + [-body](hdl/vital/vital_primitives-body.vhdl) | `VITAL_Primitives` | package + body | Library `IEEE_dummy` (uses `IEEE_dummy.VITAL_Timing`) |

### convert_pkg

| Function | Parameters | Return | Description |
|----------|------------|--------|-------------|
| `to_stdulogic` | `V : boolean` | std_ulogic | `'1'` when true, `'0'` otherwise |
| `to_slv` | `val : natural; size : natural` | std_logic_vector(size-1 downto 0) | Unsigned conversion of `val` on `size` bits |
| `onehot_to_integer` | `one_hot : std_logic_vector` | integer | Index of the single bit set; `-1` if no bit or several bits are set |

### logic_pkg

| Item | Parameters | Return | Description |
|------|------------|--------|-------------|
| `sls_t` | - | type | `array (natural range <>) of std_logic` |
| `slvs_t` | - | type | `array (natural range <>) of std_logic_vector` (VHDL-2008) |
| `reduce_xor` | `x : std_logic_vector` | std_logic | XOR of all bits (parity) |
| `reduce_or` | `x : std_logic_vector` | std_logic | OR of all bits |
| `reduce_and` | `x : std_logic_vector` | std_logic | AND of all bits |
| `count_ones` | `x : std_logic_vector` | natural | Number of bits at `'1'` |
| `mux2` | `sel : boolean; d_true, d_false : std_logic_vector` | std_logic_vector | `d_true` when `sel`, else `d_false` |
| `mux2` | `sel : boolean; d_true, d_false : natural` | natural | Same for naturals (generic computation) |
| `reverse_bits` | `v : std_logic_vector` | std_logic_vector | Bit-reversed vector (same range) |

### math_pkg

| Function | Parameters | Return | Description |
|----------|------------|--------|-------------|
| `log2` | `i : natural` | integer | floor(log2(i)), 0 for `i <= 1` |
| `clog2` | `i : natural` | integer | ceil(log2(i)), number of bits to encode `i` values |
| `max`, `max2` | `x1, x2 : integer` | integer | Maximum (`max` calls `max2`) |
| `min`, `min2` | `x1, x2 : integer` | integer | Minimum (`min` calls `min2`) |
| `is_pow2` | `n : natural` | boolean | True when `n` is a power of 2 (false for 0) |

### types_pkg

| Item | Kind | Description |
|------|------|-------------|
| `naturals_t` | array type | `array (natural range <>) of natural`; also visible through `sbi_pkg` and `pbi_pkg` (aliases of this declaration) |

### string_pkg

| Function | Parameters | Return | Description |
|----------|------------|--------|-------------|
| `string_eq` | `str1, str2 : string` | boolean | Same length and same characters |
| `string_ne` | `str1, str2 : string` | boolean | Negation of `string_eq` |
| `to_string` | `a : std_logic_vector` | string | One character per bit (`'0'`, `'1'`, `'X'`, ...) |
| `to_string` | `a : std_logic` | string | `std_logic'image(a)` |

### sbi_pkg

| Item | Kind | Description |
|------|------|-------------|
| `NAME_MAX_LEN` | constant | `16`, length of `sbi_tgt_info_t.name` |
| `SBI_ADDR_WIDTH`, `SBI_DATA_WIDTH` | constant | `8`, used by `sbi_addrs_t` / `sbi_datas_t` |
| `sbi_ini_t` | record | `cs`, `re`, `we` (std_logic), `addr`, `wdata` (unconstrained std_logic_vector) |
| `sbi_tgt_t` | record | `ready` (std_logic), `rdata` (unconstrained std_logic_vector), `info` (`sbi_tgt_info_t`: `name : string(1 to 16)`) |
| `sbi_inis_t`, `sbi_tgts_t` | array type | Arrays of initiator / target records |
| `sbi_addrs_t`, `sbi_datas_t` | array type | Arrays of 8-bit addresses / data |
| `naturals_t` | alias | Alias of `types_pkg.naturals_t` |
| `to_sbi_name(s)` | function | `s` truncated or space-padded to 16 characters |
| `sbi_ini_null(i)`, `sbi_tgt_null(i)` | function | All-zero record with the ranges of `i` (target name `"null"`) |
| `"and"`, `"or"`, `"xor"` | function | Field-wise operators on two `sbi_ini_t` or two `sbi_tgt_t` (target name set to `"anded"` / `"ored"` / `"xored"`) |
| `"or"(sbi_tgts_t)` | function | Reduction OR of all targets (read-data multiplexing of an interconnect) |

### pbi_pkg

| Item | Kind | Description |
|------|------|-------------|
| `PBI_ADDR_WIDTH`, `PBI_DATA_WIDTH` | constant | `8` |
| `pbi_ini_t` | record | `cs`, `re`, `we`, `addr`, `wdata` (same as `sbi_ini_t`) |
| `pbi_tgt_t` | record | `busy` (std_logic), `rdata` (unconstrained std_logic_vector); no `info` field |
| `pbi_inis_t`, `pbi_tgts_t`, `pbi_addrs_t`, `pbi_datas_t` | array type | Same as SBI |
| `naturals_t` | alias | Alias of `types_pkg.naturals_t` |
| `"and"`, `"or"`, `"xor"`, `"or"(pbi_tgts_t)` | function | Same operators as SBI |

### ft_pkg

| Item | Kind | Description |
|------|------|-------------|
| `ft_algo_t` | enumeration | `USE_NONE`, `USE_PARITY_ODD`, `USE_PARITY_EVEN`, `USE_TMR`, `USE_ECC` (run-time / generic selection) |
| `ft_none_t`, `ft_parity_odd_t`, `ft_parity_even_t`, `ft_tmr_t`, `ft_ecc_t` | enumeration | One-literal types (`FT_NONE`, ...) used to select an overload statically |
| `ft_status_t` | record | `error_detected`, `error_corrected` |
| `ft_dec_t` | record | `status : ft_status_t`, `data : std_logic_vector` (unconstrained) |
| `encoded_size(data_len, ft)` | function | Width of the encoded word |
| `decoded_size(data_len, ft)` | function | Width of the data carried by an encoded word |
| `encode(data, ft)` | function | Encoded word |
| `decode(data_enc, ft)` | function | `ft_dec_t` (data + status) |
| `decode(data_enc, ft, data_dec, error_detected, error_corrected)` | procedure | Same, driving three signals |
| `ft_enc`, `ft_dec`, `ft_dff` | component | Component declarations |

### ft_enc

| Name | Kind | Type | Description |
|------|------|------|-------------|
| `FT_ALGO` | generic | ft_algo_t := `USE_NONE` | Algorithm |
| `data_i` | in | std_logic_vector (unconstrained) | Data |
| `data_o` | out | std_logic_vector (unconstrained) | Encoded data, must be `encoded_size(data_i'length, FT_ALGO)` wide |

### ft_dec

| Name | Kind | Type | Description |
|------|------|------|-------------|
| `FT_ALGO` | generic | ft_algo_t := `USE_NONE` | Algorithm |
| `data_i` | in | std_logic_vector (unconstrained) | Encoded data |
| `data_o` | out | std_logic_vector (unconstrained) | Decoded data, `decoded_size(data_i'length, FT_ALGO)` wide |
| `error_detected_o` | out | std_logic | Error detected |
| `error_corrected_o` | out | std_logic | Error corrected |

## Register Map

This IP has no software-visible registers.

## Verification

### Testbenches

All testbenches are UVVM-based (`uvvm_util` log / `check_value`, `report_alert_counters(FINAL)`). The `tb_ft_<algo>` benches connect `ft_enc` to `ft_dec`, inject bit flips on the encoded word and check `data_o`, `error_detected_o`, `error_corrected_o`, then check `encoded_size` / `decoded_size`.

| File | DUT | Description |
|------|-----|-------------|
| [sim/tb_ft_none.vhd](sim/tb_ft_none.vhd) | `ft_enc` + `ft_dec` (`USE_NONE`) | 4-bit data: no error reported for 0 to 3 flipped bits; sizes = data length for 1..100 |
| [sim/tb_ft_parity_odd.vhd](sim/tb_ft_parity_odd.vhd) | `ft_enc` + `ft_dec` (`USE_PARITY_ODD`) | 4-bit data: every single and triple flip detected, every double flip undetected, never corrected; sizes n+1 for 1..100 |
| [sim/tb_ft_parity_even.vhd](sim/tb_ft_parity_even.vhd) | `ft_enc` + `ft_dec` (`USE_PARITY_EVEN`) | Same checks as parity odd |
| [sim/tb_ft_tmr.vhd](sim/tb_ft_tmr.vhd) | `ft_enc` + `ft_dec` (`USE_TMR`) | 4-bit data (12-bit word): every single flip corrected, double and triple flips on bits 0..2 (different bit positions of one copy) corrected; sizes 3n for 1..100 |
| [sim/tb_ft_ecc4.vhd](sim/tb_ft_ecc4.vhd) | `ft_enc` + `ft_dec` (`USE_ECC`) | 4-bit data (8-bit word): every single flip corrected, every double flip detected and not corrected; sizes checked for 1..502 data bits |
| [sim/tb_ft_ecc32.vhd](sim/tb_ft_ecc32.vhd) | `ft_enc` + `ft_dec` (`USE_ECC`) | `x"deadbeef"` (39-bit word): all single flips corrected, all double flips detected; two hand-built multi-bit patterns on an all-zero word (decoder mis-correction behaviour); sizes for 1..502 |
| [sim/tb_ft_dff.vhd](sim/tb_ft_dff.vhd) | 10 x `ft_dff` (`WIDTH=8`, every `FT_ALGO`, `SELF_REFRESH` false and true) | Reset: `data_o = 0` and no error flag (valid code word, PARITY_ODD included); write / hold with `data_i` changing while `we_i = 0`; fault injection in the encoded register (wrapper `tb_ft_dff_unit`, VHDL-2008 external name + `force` / `release`) on bit 0, bits 0-1 and the MSB: expected flags and output for each algorithm, then after the next clock edges the error is scrubbed when `SELF_REFRESH = true` and the error was corrected, kept otherwise; a write restores a clean word; reset after a fault. 1488 checks |
| [sim/tb_logic_pkg.vhd](sim/tb_logic_pkg.vhd) | `logic_pkg` functions | `reduce_and` / `reduce_or` / `reduce_xor` on directed values (1-bit, ascending range) and exhaustively on 8 bits together with `count_ones` against a bit-by-bit model; `mux2` (vector and natural); `reverse_bits`; `naturals_t` used with `sbi_pkg`, `pbi_pkg` and `types_pkg` all visible (no ambiguity). 1051 checks |

### Targets

| Target | Toplevel | Description |
|--------|----------|-------------|
| `default` | *(none)* | `hdl` + `pkg_ieee_dummy` filesets (not a simulation) |
| `sim` | *(none)* | Base of the simulation targets (adds `sim` fileset, GHDL `-Wall -frelaxed`, `--fst=dut.fst`) |
| `sim_ft_none` | `tb_ft_none` | Unit test for NONE algorithm |
| `sim_ft_parity_odd` | `tb_ft_parity_odd` | Unit test for parity odd algorithm |
| `sim_ft_parity_even` | `tb_ft_parity_even` | Unit test for parity even algorithm |
| `sim_ft_tmr` | `tb_ft_tmr` | Unit test for TMR algorithm |
| `sim_ft_ecc4` | `tb_ft_ecc4` | Unit test for ECC algorithm (4b) |
| `sim_ft_ecc32` | `tb_ft_ecc32` | Unit test for ECC algorithm (32b) |
| `sim_ft_dff` | `tb_ft_dff` | Unit test for ft_dff (all algorithms, reset, self refresh) |
| `sim_logic_pkg` | `tb_logic_pkg` | Unit test for logic_pkg functions |
| `emu_ng_medium_ft_dff_none` | `top_ft_dff` | NanoXplore NG-MEDIUM synthesis, `FT_ALGO=USE_NONE` |
| `emu_ng_medium_ft_dff_parity_odd` | `top_ft_dff` | NanoXplore NG-MEDIUM synthesis, `FT_ALGO=USE_PARITY_ODD` |
| `emu_ng_medium_ft_dff_parity_even` | `top_ft_dff` | NanoXplore NG-MEDIUM synthesis, `FT_ALGO=USE_PARITY_EVEN` |
| `emu_ng_medium_ft_dff_tmr` | `top_ft_dff` | NanoXplore NG-MEDIUM synthesis, `FT_ALGO=USE_TMR` |
| `emu_ng_medium_ft_dff_ecc` | `top_ft_dff` | NanoXplore NG-MEDIUM synthesis, `FT_ALGO=USE_ECC` |

The eight `sim_*` targets are the CI jobs ([.github/workflows/ci.yml](.github/workflows/ci.yml)).

### How to Run

The default tool is GHDL (`mk/defs.mk`: `TOOL ?= ghdl`, `TARGET ?= sim_ft_none`, used by the `target` / `setup` / `build` / `run` rules).

```bash
make help                 # variables, rules and target list (mk/targets.txt)
make sim_ft_ecc32         # run one target (log in log/)
make nonreg_sim           # run every sim_* target (8 tests)
make TARGETS_FILTER=^sim_ft_parity nonreg_sim   # run a filtered subset
make nonreg_emu           # run the 5 emu_* synthesis targets (needs NanoXplore nxmap)
make clean                # remove build/ and log/
```

Equivalent FuseSoC command:

```bash
fusesoc --cores-root . run --build-root build --target sim_ft_ecc32 asylum:utils:pkg:1.8.0
```

The `sim` target passes `--fst=dut.fst` directly (not `$(GHDL_RUN_OPTION)`), so the waveform is written also in CI.

## Synthesis

- **Targets**: `emu_ng_medium_ft_dff_{none,parity_odd,parity_even,tmr,ecc}` run the FuseSoC `nxmap` backend (NanoXplore) with `fpga: NG-MEDIUM-EMBEDDED`, `program: False`, top-level `top_ft_dff` and parameters `WIDTH=32`, `SELF_REFRESH=false`, `FT_ALGO=USE_NONE` (base target) then `FT_ALGO=USE_PARITY_ODD` / `USE_PARITY_EVEN` / `USE_TMR` / `USE_ECC` appended by each variant. `FT_ALGO` is a `str` parameter whose value is the `ft_algo_t` literal.
- **[syn/top_ft_dff.vhd](syn/top_ft_dff.vhd)**: same generics and ports as `ft_dff`; registers `we_i` / `data_i` before `ft_dff` and `data_o` / `error_detected_o` / `error_corrected_o` after it (asynchronous reset), so that the encoder and decoder logic sits between registers.
- **[syn/constraints/options.py](syn/constraints/options.py)** (`file_type: nx_options`): nxpython script creating clock `Clock` on `clk_i` with a 10 ns period (100 MHz).
- `ft_dff` marks its encoded register with `syn_preserve` to keep the redundancy from being optimized away.
- The `hdl` fileset is synthesizable (functions, `ft_*` entities; `assert` statements only in unreachable `when others` branches). The `pkg_ieee_dummy` fileset (VITAL) is meant for simulation models only.

## Design Notes

### Fault-Tolerance Algorithms

| Algorithm | Encoded width (n data bits) | Encoded layout | Detects | Corrects |
|-----------|-----------------------------|----------------|---------|----------|
| NONE | n | data | nothing | nothing |
| PARITY_ODD | n + 1 | `parity & data`, parity = `not xor(data)` | odd number of flips | nothing |
| PARITY_EVEN | n + 1 | `parity & data`, parity = `xor(data)` | odd number of flips | nothing |
| TMR | 3n | `data & data & data` | any difference between copies | bitwise 2-out-of-3 majority (`error_corrected = error_detected`) |
| ECC | n + r + 1 | extended Hamming: bit 0 = global parity, bits at power-of-2 positions = Hamming parity, data in the other positions | double flips | single flips |

For ECC, r is the smallest value with 2^r >= n + r + 1: 4 data bits give an 8-bit word, 32 data bits a 39-bit word. On decode, a global parity mismatch is treated as a single error: the bit designated by the Hamming syndrome (bit 0, the global parity bit, when the syndrome is zero) is flipped and both flags are set. A non-zero syndrome with a correct global parity is reported as detected, not corrected. Three or more flips can be mis-corrected (exercised by `tb_ft_ecc32`).

### ft_dff Notes

- The reset value of the encoded register is `encode((others => '0'), FT_ALGO)`, a valid code word for every algorithm (for PARITY_ODD the parity bit is `'1'`): no error flag is raised after reset.
- `SELF_REFRESH = true`: when `we_i = 0` and `error_corrected_o = '1'` (TMR, ECC single error), the corrected data is re-encoded and written back on the next clock edge, so the flags return to `'0'`. Uncorrectable errors (parity, ECC double error) are not rewritten: `error_detected_o` stays high until the next write. Without error the register keeps its value, as with `SELF_REFRESH = false`.

### Other Notes (as coded)

- `reverse_bits` and `string_eq` / `string_ne` index their arguments assuming a range starting at 0 (vector) or identical ranges (strings).

### ft_pkg Results

Synthesis of **ft_dff** with `WIDTH=32`, `SELF_REFRESH=false`, target **NG-MEDIUM-EMBEDDED**, **Impulse 25.1.0.6** tool chain. The LUT / DFF columns are *measured* results kept from an earlier README (before version 1.8.0, not re-run); the last column is *derived from the code* (`encoded_size(32, FT_ALGO)`, i.e. the width of the `ft_dff` encoded register).

| FT_ALGO           | LUT (measured) | DFF (measured) | Encoded register bits (from code) |
|-------------------|----------------|----------------|-----------------------------------|
| USE_NONE          |   1            |  32            | 32                                |
| USE_PARITY_ODD    |  23            |  33            | 33                                |
| USE_PARITY_EVEN   |  23            |  33            | 33                                |
| USE_TMR           |  93            |  96            | 96                                |
| USE_ECC           | 101            |  48 (stale)    | 39                                |

*Notes*: 1 LUT is used to invert the reset signal. The measured ECC row was obtained with an older encoder (48 DFF); the current encoder stores 32 + 6 Hamming bits + 1 global parity bit = 39 bits (checked by `tb_ft_ecc32`), so the ECC LUT / DFF figures must be measured again with `make emu_ng_medium_ft_dff_ecc`.

## Directory Structure

```
asylum-utils-pkg/
├── utils_pkg.core              # FuseSoC core (asylum:utils:pkg)
├── Makefile                    # Common Asylum Makefile (FuseSoC wrapper)
├── mk/
│   ├── defs.mk                 # FILE_CORE, default TARGET and TOOL
│   └── targets.txt             # Target list (generated from the .core)
├── doc/
│   └── pkg.drawio              # Block diagram
├── hdl/
│   ├── convert_pkg.vhd
│   ├── logic_pkg.vhd
│   ├── math_pkg.vhd
│   ├── types_pkg.vhd           # naturals_t (aliased by sbi_pkg / pbi_pkg)
│   ├── pbi_pkg.vhd
│   ├── sbi_pkg.vhd
│   ├── string_pkg.vhd
│   ├── ft_pkg.vhd
│   ├── ft_pkg_body.vhd
│   ├── ft_enc.vhd
│   ├── ft_dec.vhd
│   ├── ft_dff.vhd
│   └── vital/                  # VITAL copies (library IEEE_dummy)
│       ├── vital_timing.vhdl
│       ├── vital_timing-body.vhdl
│       ├── vital_primitives.vhdl
│       └── vital_primitives-body.vhdl
├── sim/                        # UVVM testbenches
│   ├── tb_ft_{none,parity_odd,parity_even,tmr,ecc4,ecc32}.vhd
│   ├── tb_ft_dff.vhd           # ft_dff (+ fault injection wrapper tb_ft_dff_unit)
│   └── tb_logic_pkg.vhd        # logic_pkg functions, naturals_t visibility
├── syn/
│   ├── top_ft_dff.vhd          # Synthesis wrapper of ft_dff
│   └── constraints/
│       └── options.py          # NanoXplore clock constraint
└── .github/workflows/ci.yml    # CI (sim_* jobs)
```

## Dependencies

| Core | Used by (fileset) | Purpose |
|------|-------------------|---------|
| `bitvis:verification:uvvm` | `sim` | UVVM utility library (`uvvm_util`) for the `tb_*` testbenches |

The `hdl`, `pkg_ieee_dummy` and `syn` filesets have no dependency.
