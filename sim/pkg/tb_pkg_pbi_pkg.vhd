-------------------------------------------------------------------------------
-- Title      : tb_pkg_pbi_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_pbi_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario pbi of tb_pkg :
--              - "and" / "or" / "xor" of pbi_ini_t and of pbi_tgt_t
--              - "or" of pbi_tgts_t not starting at 0
--              - naturals_t used through sbi_pkg, pbi_pkg and types_pkg at
--                the same time (not ambiguous)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg, operators
--                               added)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.pbi_pkg.all;
-- The three packages export naturals_t : this must not be ambiguous
use     asylum.sbi_pkg.all;
use     asylum.types_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_pbi_pkg is

  -- "or" of pbi_tgts_t, naturals_t of types_pkg
  procedure run;

end package tb_pkg_pbi_pkg;

package body tb_pkg_pbi_pkg is

  constant C_NATURALS : naturals_t(0 to 2) := (3, 5, 7);

  -- Field by field check of a request
  procedure check_ini(msg : string; act, exp : pbi_ini_t) is
  begin
    check_value(act.cs   , exp.cs   , ERROR, msg & " : cs"   , C_TB_SCOPE);
    check_value(act.re   , exp.re   , ERROR, msg & " : re"   , C_TB_SCOPE);
    check_value(act.we   , exp.we   , ERROR, msg & " : we"   , C_TB_SCOPE);
    check_value(act.addr , exp.addr , ERROR, msg & " : addr" , C_TB_SCOPE);
    check_value(act.wdata, exp.wdata, ERROR, msg & " : wdata", C_TB_SCOPE);
  end procedure;

  -- Field by field check of a response
  procedure check_tgt(msg : string; act, exp : pbi_tgt_t) is
  begin
    check_value(act.busy, exp.busy, ERROR, msg & " : busy", C_TB_SCOPE);
    check_value(act.rdata, exp.rdata, ERROR, msg & " : rdata", C_TB_SCOPE);
  end procedure;

  procedure run is
    variable v_ia     : pbi_ini_t(addr(7 downto 0), wdata(7 downto 0));
    variable v_ib     : pbi_ini_t(addr(7 downto 0), wdata(7 downto 0));
    variable v_ta     : pbi_tgt_t(rdata(7 downto 0));
    variable v_tb     : pbi_tgt_t(rdata(7 downto 0));
    variable v_tgts   : pbi_tgts_t(1 to 2)(rdata(7 downto 0));
  begin
    log(ID_SEQUENCER, """and"" / ""or"" / ""xor"" of two pbi_ini_t and of two pbi_tgt_t", C_TB_SCOPE);
    v_ia := (cs => '1', re => '1', we => '0', addr => x"3C", wdata => x"A5");
    v_ib := (cs => '1', re => '0', we => '1', addr => x"0F", wdata => x"96");
    check_ini("pbi_ini_t and", v_ia and v_ib, (cs => '1', re => '0', we => '0', addr => x"0C", wdata => x"84"));
    check_ini("pbi_ini_t or" , v_ia or  v_ib, (cs => '1', re => '1', we => '1', addr => x"3F", wdata => x"B7"));
    check_ini("pbi_ini_t xor", v_ia xor v_ib, (cs => '0', re => '1', we => '1', addr => x"33", wdata => x"33"));
    v_ta := (busy => '1', rdata => x"A5");
    v_tb := (busy => '0', rdata => x"96");
    check_tgt("pbi_tgt_t and", v_ta and v_tb, (busy => '0', rdata => x"84"));
    check_tgt("pbi_tgt_t or" , v_ta or  v_tb, (busy => '1', rdata => x"B7"));
    check_tgt("pbi_tgt_t xor", v_ta xor v_tb, (busy => '1', rdata => x"33"));

    log(ID_SEQUENCER, """or"" of pbi_tgts_t(1 to 2) (array not starting at 0)", C_TB_SCOPE);
    v_tgts(1) := (busy => '1', rdata => x"0F");
    v_tgts(2) := (busy => '0', rdata => x"03");
    check_tgt("or(pbi_tgts_t), overlapping rdata, last busy 0", "or"(v_tgts), (busy => '1', rdata => x"0F"));
    v_tgts(1) := (busy => '0', rdata => x"00");
    v_tgts(2) := (busy => '0', rdata => x"00");
    check_tgt("or(pbi_tgts_t), every target idle"            , "or"(v_tgts), (busy => '0', rdata => x"00"));

    log(ID_SEQUENCER, "naturals_t visible through sbi_pkg, pbi_pkg and types_pkg", C_TB_SCOPE);
    check_value(C_NATURALS'length, 3, ERROR, "naturals_t length" , C_TB_SCOPE);
    check_value(C_NATURALS(1)    , 5, ERROR, "naturals_t element", C_TB_SCOPE);
  end procedure;

end package body tb_pkg_pbi_pkg;
