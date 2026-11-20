-------------------------------------------------------------------------------
-- Title      : tb_pkg_string_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_string_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario string of tb_pkg : to_string of std_logic and
--              std_logic_vector (format of the VHDL-2008 TO_STRING),
--              string_eq / string_ne on different index ranges and lengths
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg, lengths added)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_string_pkg is

  -- string_eq, string_ne and to_string of string_pkg
  procedure run;

end package tb_pkg_string_pkg;

package body tb_pkg_string_pkg is

  procedure run is
    variable v_str  : string(1 to 10);
    variable v_slv  : std_logic_vector(3 downto 0);
  begin
    log(ID_SEQUENCER, "to_string : same format as the VHDL-2008 TO_STRING", C_TB_SCOPE);
    check_value(asylum.string_pkg.to_string(std_logic'('1'))          , "1"   , ERROR, "to_string(std_logic '1')"  , C_TB_SCOPE);
    check_value(asylum.string_pkg.to_string(std_logic'('Z'))          , "Z"   , ERROR, "to_string(std_logic 'Z')"  , C_TB_SCOPE);
    check_value(asylum.string_pkg.to_string(std_logic_vector'("10XZ")), "10XZ", ERROR, "to_string(std_logic_vector, ascending)", C_TB_SCOPE);
    v_slv := "10XZ";
    check_value(asylum.string_pkg.to_string(v_slv)                    , "10XZ", ERROR, "to_string(std_logic_vector(3 downto 0))", C_TB_SCOPE);

    log(ID_SEQUENCER, "string_eq / string_ne on different index ranges and lengths", C_TB_SCOPE);
    v_str := "....abc...";
    check_value(string_eq("abc", v_str(5 to 7)), true , ERROR, "string_eq(abc, s(5 to 7))", C_TB_SCOPE);
    check_value(string_ne("abc", v_str(5 to 7)), false, ERROR, "string_ne(abc, s(5 to 7))", C_TB_SCOPE);
    check_value(string_eq("abd", v_str(5 to 7)), false, ERROR, "string_eq(abd, s(5 to 7))", C_TB_SCOPE);
    check_value(string_ne("abd", v_str(5 to 7)), true , ERROR, "string_ne(abd, s(5 to 7))", C_TB_SCOPE);
    check_value(string_eq("ab" , v_str(5 to 7)), false, ERROR, "string_eq(ab, s(5 to 7))" , C_TB_SCOPE);
    check_value(string_ne("ab" , v_str(5 to 7)), true , ERROR, "string_ne(ab, s(5 to 7))" , C_TB_SCOPE);
  end procedure;

end package body tb_pkg_string_pkg;
