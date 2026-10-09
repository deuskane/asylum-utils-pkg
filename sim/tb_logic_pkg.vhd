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
    log(ID_LOG_HDR, "reverse_bits", C_SCOPE);
    ---------------------------------------------------------------------------
    v_rev := reverse_bits(x"01");
    check_value(v_rev, x"80", ERROR, "reverse_bits(01)");
    v_rev := reverse_bits(x"C4");
    check_value(v_rev, x"23", ERROR, "reverse_bits(C4)");

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
