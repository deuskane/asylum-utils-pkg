-------------------------------------------------------------------------------
-- Title      : tb_pkg_math_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_math_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario math of tb_pkg : clog2 / log2 up to natural'high, max
--              / min, is_pow2
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg, max / min /
--                               is_pow2 added)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_math_pkg is

  -- Functions of math_pkg
  procedure run;

end package tb_pkg_math_pkg;

package body tb_pkg_math_pkg is

  -- Selected names (asylum.math_pkg.<f>) : uvvm_util also declares log2
  procedure run is
  begin
    log(ID_SEQUENCER, "clog2 / log2, up to natural'high", C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(0)           ,  0, ERROR, "clog2(0)"           , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(1)           ,  0, ERROR, "clog2(1)"           , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(2)           ,  1, ERROR, "clog2(2)"           , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(3)           ,  2, ERROR, "clog2(3)"           , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(4)           ,  2, ERROR, "clog2(4)"           , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(5)           ,  3, ERROR, "clog2(5)"           , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(2**30)       , 30, ERROR, "clog2(2**30)"       , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(2**30+1)     , 31, ERROR, "clog2(2**30+1)"     , C_TB_SCOPE);
    check_value(asylum.math_pkg.clog2(natural'high), 31, ERROR, "clog2(natural'high)", C_TB_SCOPE);
    check_value(asylum.math_pkg.log2(1)            ,  0, ERROR, "log2(1)"            , C_TB_SCOPE);
    check_value(asylum.math_pkg.log2(5)            ,  2, ERROR, "log2(5)"            , C_TB_SCOPE);
    check_value(asylum.math_pkg.log2(natural'high) , 30, ERROR, "log2(natural'high)" , C_TB_SCOPE);

    log(ID_SEQUENCER, "max / min", C_TB_SCOPE);
    check_value(asylum.math_pkg.max( 3, -2)                  ,  3, ERROR, "max(3, -2)", C_TB_SCOPE);
    check_value(asylum.math_pkg.max(-2,  3)                  ,  3, ERROR, "max(-2, 3)", C_TB_SCOPE);
    check_value(asylum.math_pkg.min( 3, -2)                  , -2, ERROR, "min(3, -2)", C_TB_SCOPE);
    check_value(asylum.math_pkg.min(-2,  3)                  , -2, ERROR, "min(-2, 3)", C_TB_SCOPE);

    log(ID_SEQUENCER, "is_pow2", C_TB_SCOPE);
    check_value(asylum.math_pkg.is_pow2(0)         , false, ERROR, "is_pow2(0)"     , C_TB_SCOPE);
    check_value(asylum.math_pkg.is_pow2(1)         , true , ERROR, "is_pow2(1)"     , C_TB_SCOPE);
    check_value(asylum.math_pkg.is_pow2(2)         , true , ERROR, "is_pow2(2)"     , C_TB_SCOPE);
    check_value(asylum.math_pkg.is_pow2(6)         , false, ERROR, "is_pow2(6)"     , C_TB_SCOPE);
    check_value(asylum.math_pkg.is_pow2(64)        , true , ERROR, "is_pow2(64)"    , C_TB_SCOPE);
    check_value(asylum.math_pkg.is_pow2(96)        , false, ERROR, "is_pow2(96)"    , C_TB_SCOPE);
    check_value(asylum.math_pkg.is_pow2(2**30)     , true , ERROR, "is_pow2(2**30)" , C_TB_SCOPE);
  end procedure;

end package body tb_pkg_math_pkg;
