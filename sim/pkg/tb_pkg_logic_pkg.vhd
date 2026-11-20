-------------------------------------------------------------------------------
-- Title      : tb_pkg_logic_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_logic_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario logic of tb_pkg : reduce_and / reduce_or / reduce_xor
--              (directed, 1 bit, ascending range, exhaustive on 8 bits
--              against a reference), count_ones, mux2 (vector and natural),
--              reverse_bits (any index range)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.logic_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_logic_pkg is

  -- Functions of logic_pkg
  procedure run;

end package tb_pkg_logic_pkg;

package body tb_pkg_logic_pkg is

  procedure run is
    variable v_vec  : std_logic_vector(7 downto 0);
    variable v_asc  : std_logic_vector(0 to 4);
    variable v_one  : std_logic_vector(0 downto 0);
    variable v_rev  : std_logic_vector(7 downto 0);
    variable v_off  : std_logic_vector(8 downto 1);
    variable v_asc8 : std_logic_vector(0 to 7);
    variable v_n    : natural;
  begin
    log(ID_SEQUENCER, "reduce_and / reduce_or / reduce_xor : directed values", C_TB_SCOPE);
    check_value(reduce_and(x"FF"), '1', ERROR, "reduce_and(FF)", C_TB_SCOPE);
    check_value(reduce_and(x"00"), '0', ERROR, "reduce_and(00)", C_TB_SCOPE);
    check_value(reduce_and(x"7F"), '0', ERROR, "reduce_and(7F)", C_TB_SCOPE);
    check_value(reduce_and(x"FE"), '0', ERROR, "reduce_and(FE)", C_TB_SCOPE);
    check_value(reduce_or (x"00"), '0', ERROR, "reduce_or(00)" , C_TB_SCOPE);
    check_value(reduce_or (x"80"), '1', ERROR, "reduce_or(80)" , C_TB_SCOPE);
    check_value(reduce_or (x"01"), '1', ERROR, "reduce_or(01)" , C_TB_SCOPE);
    check_value(reduce_xor(x"00"), '0', ERROR, "reduce_xor(00)", C_TB_SCOPE);
    check_value(reduce_xor(x"01"), '1', ERROR, "reduce_xor(01)", C_TB_SCOPE);
    check_value(reduce_xor(x"03"), '0', ERROR, "reduce_xor(03)", C_TB_SCOPE);
    check_value(reduce_xor(x"07"), '1', ERROR, "reduce_xor(07)", C_TB_SCOPE);

    v_one := "1";
    check_value(reduce_and(v_one), '1', ERROR, "reduce_and 1-bit '1'", C_TB_SCOPE);
    check_value(reduce_or (v_one), '1', ERROR, "reduce_or  1-bit '1'", C_TB_SCOPE);
    check_value(reduce_xor(v_one), '1', ERROR, "reduce_xor 1-bit '1'", C_TB_SCOPE);
    v_one := "0";
    check_value(reduce_and(v_one), '0', ERROR, "reduce_and 1-bit '0'", C_TB_SCOPE);
    check_value(reduce_or (v_one), '0', ERROR, "reduce_or  1-bit '0'", C_TB_SCOPE);
    check_value(reduce_xor(v_one), '0', ERROR, "reduce_xor 1-bit '0'", C_TB_SCOPE);

    v_asc := "11111";
    check_value(reduce_and(v_asc), '1', ERROR, "reduce_and ascending 11111", C_TB_SCOPE);
    v_asc := "11011";
    check_value(reduce_and(v_asc), '0', ERROR, "reduce_and ascending 11011", C_TB_SCOPE);

    log(ID_SEQUENCER, "reduce_* / count_ones : exhaustive on 8 bits", C_TB_SCOPE);
    for i in 0 to 255 loop
      v_vec := std_logic_vector(to_unsigned(i, 8));
      v_n   := ref_count(v_vec);
      check_value(reduce_and(v_vec), to_sl(v_n = 8)      , ERROR, "reduce_and(" & to_hstring(v_vec) & ")", C_TB_SCOPE);
      check_value(reduce_or (v_vec), to_sl(v_n /= 0)     , ERROR, "reduce_or("  & to_hstring(v_vec) & ")", C_TB_SCOPE);
      check_value(reduce_xor(v_vec), to_sl(v_n mod 2 = 1), ERROR, "reduce_xor(" & to_hstring(v_vec) & ")", C_TB_SCOPE);
      check_value(count_ones(v_vec), v_n                 , ERROR, "count_ones(" & to_hstring(v_vec) & ")", C_TB_SCOPE);
    end loop;

    log(ID_SEQUENCER, "mux2", C_TB_SCOPE);
    check_value(mux2(true , x"A5", x"5A"), x"A5", ERROR, "mux2 slv true"     , C_TB_SCOPE);
    check_value(mux2(false, x"A5", x"5A"), x"5A", ERROR, "mux2 slv false"    , C_TB_SCOPE);
    check_value(mux2(true , 12, 34)      , 12   , ERROR, "mux2 natural true" , C_TB_SCOPE);
    check_value(mux2(false, 12, 34)      , 34   , ERROR, "mux2 natural false", C_TB_SCOPE);

    log(ID_SEQUENCER, "reverse_bits on any index range", C_TB_SCOPE);
    v_rev := reverse_bits(x"01");
    check_value(v_rev, x"80", ERROR, "reverse_bits(01)", C_TB_SCOPE);
    v_rev := reverse_bits(x"C4");
    check_value(v_rev, x"23", ERROR, "reverse_bits(C4)", C_TB_SCOPE);
    v_off := reverse_bits(std_logic_vector'(x"C4"));
    v_off := reverse_bits(v_off);
    check_value(v_off, x"C4", ERROR, "reverse_bits twice on (8 downto 1)", C_TB_SCOPE);
    v_off := x"01";
    v_off := reverse_bits(v_off);
    check_value(v_off(8), '1', ERROR, "reverse_bits(8 downto 1) : bit 1 -> bit 8", C_TB_SCOPE);
    v_asc8 := x"C4";
    v_asc8 := reverse_bits(v_asc8);
    check_value(std_logic_vector(v_asc8), x"23", ERROR, "reverse_bits(0 to 7)", C_TB_SCOPE);
  end procedure;

end package body tb_pkg_logic_pkg;
