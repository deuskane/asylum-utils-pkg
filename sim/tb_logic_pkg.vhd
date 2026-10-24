-------------------------------------------------------------------------------
-- Title      : tb_logic_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_logic_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking testbench of the logic_pkg functions
--              (reduce_and / reduce_or / reduce_xor, count_ones, mux2,
--              reverse_bits) and of the naturals_t visibility when sbi_pkg,
--              pbi_pkg and types_pkg are used together.
--              Functions called on vectors not indexed (N-1 downto 0) :
--              reverse_bits, onehot_to_integer, string_eq / string_ne,
--              "or" of sbi_tgts_t / pbi_tgts_t, ft_pkg encode / decode.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.logic_pkg.all;
use     asylum.convert_pkg.all;
use     asylum.string_pkg.all;
use     asylum.ft_pkg.all;
-- The three packages export naturals_t : this must not be ambiguous
use     asylum.sbi_pkg.all;
use     asylum.pbi_pkg.all;
use     asylum.types_pkg.all;

entity tb_logic_pkg is
end entity tb_logic_pkg;

architecture sim of tb_logic_pkg is

  constant C_SCOPE : string := "TB_LOGIC_PKG";

  -- naturals_t used through sbi_pkg / pbi_pkg / types_pkg at the same time
  constant C_NATURALS : naturals_t(0 to 2) := (3, 5, 7);

  -- Reference models (bit by bit, independent from logic_pkg)
  function ref_count(x : std_logic_vector) return natural is
    variable n : natural := 0;
  begin
    for i in x'range loop
      if x(i) = '1' then
        n := n + 1;
      end if;
    end loop;
    return n;
  end function;

  function to_sl(b : boolean) return std_logic is
  begin
    if b then
      return '1';
    else
      return '0';
    end if;
  end function;

begin

  p_main : process
    variable v_vec  : std_logic_vector(7 downto 0);
    variable v_asc  : std_logic_vector(0 to 4);
    variable v_one  : std_logic_vector(0 downto 0);
    variable v_rev  : std_logic_vector(7 downto 0);
    variable v_n    : natural;
    variable v_off  : std_logic_vector(8 downto 1);
    variable v_asc8 : std_logic_vector(0 to 7);
    variable v_str  : string(1 to 10);
    variable v_stgt : sbi_tgts_t(1 to 2)(rdata(7 downto 0));
    variable v_sres : sbi_tgt_t(rdata(7 downto 0));
    variable v_ptgt : pbi_tgts_t(1 to 2)(rdata(7 downto 0));
    variable v_pres : pbi_tgt_t(rdata(7 downto 0));
    variable v_word : std_logic_vector(127 downto 0);
    variable v_easc : std_logic_vector(0 to 38);
    variable v_dec  : ft_dec_t(data(31 downto 0));
  begin
    log(ID_LOG_HDR, "START: logic_pkg functions", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "reduce_and / reduce_or / reduce_xor : directed values", C_SCOPE);
    ---------------------------------------------------------------------------
    check_value(reduce_and(x"FF"), '1', ERROR, "reduce_and(FF)");
    check_value(reduce_and(x"00"), '0', ERROR, "reduce_and(00)");
    check_value(reduce_and(x"7F"), '0', ERROR, "reduce_and(7F)");
    check_value(reduce_and(x"FE"), '0', ERROR, "reduce_and(FE)");
    check_value(reduce_or (x"00"), '0', ERROR, "reduce_or(00)");
    check_value(reduce_or (x"80"), '1', ERROR, "reduce_or(80)");
    check_value(reduce_or (x"01"), '1', ERROR, "reduce_or(01)");
    check_value(reduce_xor(x"00"), '0', ERROR, "reduce_xor(00)");
    check_value(reduce_xor(x"01"), '1', ERROR, "reduce_xor(01)");
    check_value(reduce_xor(x"03"), '0', ERROR, "reduce_xor(03)");
    check_value(reduce_xor(x"07"), '1', ERROR, "reduce_xor(07)");

    v_one := "1";
    check_value(reduce_and(v_one), '1', ERROR, "reduce_and 1-bit '1'");
    check_value(reduce_or (v_one), '1', ERROR, "reduce_or  1-bit '1'");
    check_value(reduce_xor(v_one), '1', ERROR, "reduce_xor 1-bit '1'");
    v_one := "0";
    check_value(reduce_and(v_one), '0', ERROR, "reduce_and 1-bit '0'");
    check_value(reduce_or (v_one), '0', ERROR, "reduce_or  1-bit '0'");
    check_value(reduce_xor(v_one), '0', ERROR, "reduce_xor 1-bit '0'");

    v_asc := "11111";
    check_value(reduce_and(v_asc), '1', ERROR, "reduce_and ascending 11111");
    v_asc := "11011";
    check_value(reduce_and(v_asc), '0', ERROR, "reduce_and ascending 11011");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "reduce_* / count_ones : exhaustive on 8 bits", C_SCOPE);
    ---------------------------------------------------------------------------
    for i in 0 to 255 loop
      v_vec := std_logic_vector(to_unsigned(i, 8));
      v_n   := ref_count(v_vec);
      check_value(reduce_and(v_vec), to_sl(v_n = 8)      , ERROR, "reduce_and(" & to_hstring(v_vec) & ")", C_SCOPE, ID_NEVER);
      check_value(reduce_or (v_vec), to_sl(v_n /= 0)     , ERROR, "reduce_or("  & to_hstring(v_vec) & ")", C_SCOPE, ID_NEVER);
      check_value(reduce_xor(v_vec), to_sl(v_n mod 2 = 1), ERROR, "reduce_xor(" & to_hstring(v_vec) & ")", C_SCOPE, ID_NEVER);
      check_value(count_ones(v_vec), v_n                 , ERROR, "count_ones(" & to_hstring(v_vec) & ")", C_SCOPE, ID_NEVER);
    end loop;

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "mux2", C_SCOPE);
    ---------------------------------------------------------------------------
    check_value(mux2(true , x"A5", x"5A"), x"A5", ERROR, "mux2 slv true");
    check_value(mux2(false, x"A5", x"5A"), x"5A", ERROR, "mux2 slv false");
    check_value(mux2(true , 12, 34), 12, ERROR, "mux2 natural true");
    check_value(mux2(false, 12, 34), 34, ERROR, "mux2 natural false");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "string_pkg to_string : same format as the VHDL-2008 TO_STRING", C_SCOPE);
    ---------------------------------------------------------------------------
    check_value(asylum.string_pkg.to_string(std_logic'('1'))           , "1"   , ERROR, "to_string(std_logic '1')");
    check_value(asylum.string_pkg.to_string(std_logic'('Z'))           , "Z"   , ERROR, "to_string(std_logic 'Z')");
    check_value(asylum.string_pkg.to_string(std_logic_vector'("10XZ")) , "10XZ", ERROR, "to_string(std_logic_vector)");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "reverse_bits", C_SCOPE);
    ---------------------------------------------------------------------------
    v_rev := reverse_bits(x"01");
    check_value(v_rev, x"80", ERROR, "reverse_bits(01)");
    v_rev := reverse_bits(x"C4");
    check_value(v_rev, x"23", ERROR, "reverse_bits(C4)");
    v_off := reverse_bits(std_logic_vector'(x"C4"));
    v_off := reverse_bits(v_off);
    check_value(v_off, x"C4", ERROR, "reverse_bits twice on (8 downto 1)");
    v_off := x"01";
    v_off := reverse_bits(v_off);
    check_value(v_off(8), '1', ERROR, "reverse_bits(8 downto 1) : bit 1 -> bit 8");
    v_asc8 := x"C4";
    v_asc8 := reverse_bits(v_asc8);
    check_value(std_logic_vector(v_asc8), x"23", ERROR, "reverse_bits(0 to 7)");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "onehot_to_integer on any index range", C_SCOPE);
    ---------------------------------------------------------------------------
    v_vec  := x"04";
    check_value(onehot_to_integer(v_vec), 2, ERROR, "onehot_to_integer(7 downto 0)");
    v_asc8 := "00100000";
    check_value(onehot_to_integer(v_asc8), 2, ERROR, "onehot_to_integer(0 to 7)");
    v_off  := x"04";
    check_value(onehot_to_integer(v_off), 2, ERROR, "onehot_to_integer(8 downto 1)");
    v_off  := x"06";
    check_value(onehot_to_integer(v_off), -1, ERROR, "onehot_to_integer(8 downto 1) 2 bits");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "string_eq / string_ne on different index ranges", C_SCOPE);
    ---------------------------------------------------------------------------
    v_str := "....abc...";
    check_value(string_eq("abc", v_str(5 to 7)), true , ERROR, "string_eq(abc, s(5 to 7))");
    check_value(string_ne("abc", v_str(5 to 7)), false, ERROR, "string_ne(abc, s(5 to 7))");
    check_value(string_eq("abd", v_str(5 to 7)), false, ERROR, "string_eq(abd, s(5 to 7))");
    check_value(string_ne("abd", v_str(5 to 7)), true , ERROR, "string_ne(abd, s(5 to 7))");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "or of sbi_tgts_t / pbi_tgts_t not starting at 0", C_SCOPE);
    ---------------------------------------------------------------------------
    v_stgt(1).ready := '0'; v_stgt(1).rdata := x"0F"; v_stgt(1).info.name := to_sbi_name("t1");
    v_stgt(2).ready := '1'; v_stgt(2).rdata := x"30"; v_stgt(2).info.name := to_sbi_name("t2");
    v_sres := "or"(v_stgt);
    check_value(v_sres.ready, '1'  , ERROR, "or(sbi_tgts_t(1 to 2)).ready");
    check_value(v_sres.rdata, x"3F", ERROR, "or(sbi_tgts_t(1 to 2)).rdata");
    v_ptgt(1).busy  := '0'; v_ptgt(1).rdata := x"0F";
    v_ptgt(2).busy  := '1'; v_ptgt(2).rdata := x"30";
    v_pres := "or"(v_ptgt);
    check_value(v_pres.busy , '1'  , ERROR, "or(pbi_tgts_t(1 to 2)).busy");
    check_value(v_pres.rdata, x"3F", ERROR, "or(pbi_tgts_t(1 to 2)).rdata");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "ft_pkg decode on a slice and on an ascending vector", C_SCOPE);
    ---------------------------------------------------------------------------
    -- ECC word stored in the upper part of a wider vector
    v_word := (others => '0');
    v_word(77 downto 39) := encode(std_logic_vector'(x"deadbeef"), USE_ECC);
    v_word(40) := not v_word(40);
    v_dec  := decode(v_word(77 downto 39), USE_ECC);
    check_value(v_dec.data, x"deadbeef", ERROR, "ECC decode(77 downto 39) data");
    check_value(v_dec.status.error_corrected, '1', ERROR, "ECC decode(77 downto 39) corrected");
    -- ECC word in an ascending vector (assignment by position)
    v_easc := encode(std_logic_vector'(x"deadbeef"), USE_ECC);
    v_dec  := decode(v_easc, USE_ECC);
    check_value(v_dec.data, x"deadbeef", ERROR, "ECC decode(0 to 38) data");
    check_value(v_dec.status.error_detected, '0', ERROR, "ECC decode(0 to 38) no error");
    v_easc := encode(v_dec.data(31 downto 0), USE_ECC);
    v_dec  := decode(v_easc, USE_ECC);
    check_value(v_dec.data, x"deadbeef", ERROR, "ECC encode/decode (0 to 38) round trip");
    -- TMR word in the middle of a wider vector, one copy corrupted
    v_word := (others => '0');
    v_word(111 downto 16) := encode(std_logic_vector'(x"deadbeef"), USE_TMR);
    v_word(40) := not v_word(40);
    v_dec  := decode(v_word(111 downto 16), USE_TMR);
    check_value(v_dec.data, x"deadbeef", ERROR, "TMR decode(111 downto 16) data");
    check_value(v_dec.status.error_corrected, '1', ERROR, "TMR decode(111 downto 16) corrected");
    -- Parity word in an ascending vector
    v_easc(0 to 32) := encode(std_logic_vector'(x"deadbeef"), USE_PARITY_EVEN);
    v_dec  := decode(v_easc(0 to 32), USE_PARITY_EVEN);
    check_value(v_dec.data, x"deadbeef", ERROR, "PARITY decode(0 to 32) data");
    check_value(v_dec.status.error_detected, '0', ERROR, "PARITY decode(0 to 32) no error");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "naturals_t visible through sbi_pkg, pbi_pkg and types_pkg", C_SCOPE);
    ---------------------------------------------------------------------------
    check_value(C_NATURALS'length, 3, ERROR, "naturals_t length");
    check_value(C_NATURALS(1)    , 5, ERROR, "naturals_t element");

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end architecture sim;
