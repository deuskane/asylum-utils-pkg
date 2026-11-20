-------------------------------------------------------------------------------
-- Title      : tb_pkg_convert_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_convert_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario convert of tb_pkg : onehot_to_integer on any index
--              range (position from the low index, -1 when not one-hot),
--              to_slv, to_stdulogic
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg, to_slv and
--                               to_stdulogic added)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.convert_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_convert_pkg is

  -- Functions of convert_pkg
  procedure run;

end package tb_pkg_convert_pkg;

package body tb_pkg_convert_pkg is

  procedure run is
    variable v_vec  : std_logic_vector(7 downto 0);
    variable v_off  : std_logic_vector(8 downto 1);
    variable v_asc8 : std_logic_vector(0 to 7);
  begin
    log(ID_SEQUENCER, "onehot_to_integer on any index range", C_TB_SCOPE);
    v_vec  := x"04";
    check_value(onehot_to_integer(v_vec) ,  2, ERROR, "onehot_to_integer(7 downto 0)"       , C_TB_SCOPE);
    v_asc8 := "00100000";
    check_value(onehot_to_integer(v_asc8),  2, ERROR, "onehot_to_integer(0 to 7)"           , C_TB_SCOPE);
    v_off  := x"04";
    check_value(onehot_to_integer(v_off) ,  2, ERROR, "onehot_to_integer(8 downto 1)"       , C_TB_SCOPE);
    v_off  := x"06";
    check_value(onehot_to_integer(v_off) , -1, ERROR, "onehot_to_integer(8 downto 1) 2 bits", C_TB_SCOPE);
    v_vec  := x"00";
    check_value(onehot_to_integer(v_vec) , -1, ERROR, "onehot_to_integer(00) : no bit"      , C_TB_SCOPE);

    log(ID_SEQUENCER, "to_slv / to_stdulogic", C_TB_SCOPE);
    check_value(to_slv(5  , 4), "0101", ERROR, "to_slv(5, 4)"  , C_TB_SCOPE);
    check_value(to_slv(200, 8), x"C8" , ERROR, "to_slv(200, 8)", C_TB_SCOPE);
    check_value(to_stdulogic(true ), '1', ERROR, "to_stdulogic(true)" , C_TB_SCOPE);
    check_value(to_stdulogic(false), '0', ERROR, "to_stdulogic(false)", C_TB_SCOPE);
  end procedure;

end package body tb_pkg_convert_pkg;
