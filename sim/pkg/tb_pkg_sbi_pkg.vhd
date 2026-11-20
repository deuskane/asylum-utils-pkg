-------------------------------------------------------------------------------
-- Title      : tb_pkg_sbi_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_sbi_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario sbi of tb_pkg :
--              - "=" / "/=" of sbi_ini_t : every combination of cs, re, we
--                of both requests, addr and wdata equal or different,
--                against a reference model (cs, re, we always compared,
--                addr only when cs = '1', wdata only when cs = '1' and
--                we = '1')
--              - "and" / "or" / "xor" of sbi_ini_t and of sbi_tgt_t
--              - "or" of sbi_tgts_t not starting at 0
--              - sbi_ini_null, sbi_tgt_null, to_sbi_name
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_sbi_pkg and tb_logic_pkg,
--                               to_sbi_name added)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.sbi_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_sbi_pkg is

  -- Comparison of sbi_ini_t, "or" of sbi_tgts_t, to_sbi_name
  procedure run;

end package tb_pkg_sbi_pkg;

package body tb_pkg_sbi_pkg is

  subtype ini_t is sbi_ini_t(addr (8-1 downto 0),
                             wdata(8-1 downto 0));

  -- Reference model, written from the specification of the operators
  function ref_equal(a, b : ini_t) return boolean is
    variable v_equal : boolean := true;
  begin
    if a.cs /= b.cs or a.re /= b.re or a.we /= b.we
    then
      v_equal := false;
    end if;
    if a.cs = '1' and a.addr /= b.addr
    then
      v_equal := false;
    end if;
    if a.cs = '1' and a.we = '1' and a.wdata /= b.wdata
    then
      v_equal := false;
    end if;
    return v_equal;
  end function;

  -- Bit b of i
  function bit_of(i : natural; b : natural) return std_logic is
  begin
    return to_sl((i / 2**b) mod 2 = 1);
  end function;

  -- Field by field check of a request
  procedure check_ini(msg : string; act, exp : sbi_ini_t) is
  begin
    check_value(act.cs   , exp.cs   , ERROR, msg & " : cs"   , C_TB_SCOPE);
    check_value(act.re   , exp.re   , ERROR, msg & " : re"   , C_TB_SCOPE);
    check_value(act.we   , exp.we   , ERROR, msg & " : we"   , C_TB_SCOPE);
    check_value(act.addr , exp.addr , ERROR, msg & " : addr" , C_TB_SCOPE);
    check_value(act.wdata, exp.wdata, ERROR, msg & " : wdata", C_TB_SCOPE);
  end procedure;

  -- Field by field check of a response
  procedure check_tgt(msg : string; act, exp : sbi_tgt_t) is
  begin
    check_value(act.ready, exp.ready, ERROR, msg & " : ready", C_TB_SCOPE);
    check_value(act.rdata, exp.rdata, ERROR, msg & " : rdata", C_TB_SCOPE);
    check_value(act.info.name, exp.info.name, ERROR, msg & " : info.name", C_TB_SCOPE);
  end procedure;

  procedure run is
    variable v_a      : ini_t;
    variable v_b      : ini_t;
    variable v_nb_eq  : natural := 0;
    variable v_ia     : sbi_ini_t(addr(7 downto 0), wdata(7 downto 0));
    variable v_ib     : sbi_ini_t(addr(7 downto 0), wdata(7 downto 0));
    variable v_ta     : sbi_tgt_t(rdata(7 downto 0));
    variable v_tb     : sbi_tgt_t(rdata(7 downto 0));
    variable v_tgts   : sbi_tgts_t(1 to 2)(rdata(7 downto 0));
  begin
    log(ID_SEQUENCER, """="" / ""/="" : cs, re, we of both requests x addr x wdata", C_TB_SCOPE);
    -- bits 2..0 : cs, re, we of a ; bits 5..3 : cs, re, we of b
    -- bit  6    : addr  differs   ; bit  7    : wdata differs
    for i in 0 to 2**8-1
    loop
      v_a.cs    := bit_of(i,2);
      v_a.re    := bit_of(i,1);
      v_a.we    := bit_of(i,0);
      v_a.addr  := x"3C";
      v_a.wdata := x"A5";
      v_b.cs    := bit_of(i,5);
      v_b.re    := bit_of(i,4);
      v_b.we    := bit_of(i,3);
      v_b.addr  := x"3C" xor (8-1 downto 0 => bit_of(i,6));
      v_b.wdata := x"A5" xor (8-1 downto 0 => bit_of(i,7));

      check_value(v_a  = v_b,     ref_equal(v_a,v_b), ERROR, """="" case "  & integer'image(i), C_TB_SCOPE);
      check_value(v_a /= v_b, not ref_equal(v_a,v_b), ERROR, """/="" case " & integer'image(i), C_TB_SCOPE);

      if ref_equal(v_a,v_b)
      then
        v_nb_eq := v_nb_eq + 1;
      end if;
    end loop;

    -- Equal requests : same control (8 cases), addr and wdata ignored or equal :
    --   cs = 0      : 4 cases x 4 (addr, wdata free)            = 16
    --   cs = 1 we 0 : 2 cases x 2 (wdata free, addr equal)      =  4
    --   cs = 1 we 1 : 2 cases x 1 (addr and wdata equal)        =  2
    check_value(v_nb_eq, 22, ERROR, "number of equal requests (the model itself)", C_TB_SCOPE);

    log(ID_SEQUENCER, "Directed : idle bus, read, write", C_TB_SCOPE);
    v_a := (cs => '0', re => '0', we => '0', addr => x"12", wdata => x"34");
    v_b := (cs => '0', re => '0', we => '0', addr => x"FF", wdata => x"00");
    check_value(v_a  = v_b, true , ERROR, "idle : addr and wdata ignored", C_TB_SCOPE);
    v_a := (cs => '1', re => '1', we => '0', addr => x"12", wdata => x"34");
    v_b := (cs => '1', re => '1', we => '0', addr => x"12", wdata => x"00");
    check_value(v_a  = v_b, true , ERROR, "read : wdata ignored", C_TB_SCOPE);
    v_b.addr := x"13";
    check_value(v_a /= v_b, true , ERROR, "read : addr compared", C_TB_SCOPE);
    v_a := (cs => '1', re => '0', we => '1', addr => x"12", wdata => x"34");
    v_b := (cs => '1', re => '0', we => '1', addr => x"12", wdata => x"35");
    check_value(v_a /= v_b, true , ERROR, "write : wdata compared", C_TB_SCOPE);

    log(ID_SEQUENCER, """and"" / ""or"" / ""xor"" of two sbi_ini_t and of two sbi_tgt_t", C_TB_SCOPE);
    v_ia := (cs => '1', re => '1', we => '0', addr => x"3C", wdata => x"A5");
    v_ib := (cs => '1', re => '0', we => '1', addr => x"0F", wdata => x"96");
    check_ini("sbi_ini_t and", v_ia and v_ib, (cs => '1', re => '0', we => '0', addr => x"0C", wdata => x"84"));
    check_ini("sbi_ini_t or" , v_ia or  v_ib, (cs => '1', re => '1', we => '1', addr => x"3F", wdata => x"B7"));
    check_ini("sbi_ini_t xor", v_ia xor v_ib, (cs => '0', re => '1', we => '1', addr => x"33", wdata => x"33"));
    v_ta := (ready => '1', rdata => x"A5", info => (name => to_sbi_name("ta")));
    v_tb := (ready => '0', rdata => x"96", info => (name => to_sbi_name("tb")));
    check_tgt("sbi_tgt_t and", v_ta and v_tb, (ready => '0', rdata => x"84", info => (name => to_sbi_name("anded"))));
    check_tgt("sbi_tgt_t or" , v_ta or  v_tb, (ready => '1', rdata => x"B7", info => (name => to_sbi_name("ored"))));
    check_tgt("sbi_tgt_t xor", v_ta xor v_tb, (ready => '1', rdata => x"33", info => (name => to_sbi_name("xored"))));

    log(ID_SEQUENCER, """or"" of sbi_tgts_t(1 to 2) (array not starting at 0)", C_TB_SCOPE);
    v_tgts(1) := (ready => '1', rdata => x"0F", info => (name => to_sbi_name("t1")));
    v_tgts(2) := (ready => '0', rdata => x"03", info => (name => to_sbi_name("t2")));
    check_tgt("or(sbi_tgts_t), overlapping rdata, last ready 0", "or"(v_tgts), (ready => '1', rdata => x"0F", info => (name => to_sbi_name("ored"))));
    v_tgts(1) := (ready => '0', rdata => x"00", info => (name => to_sbi_name("t1")));
    v_tgts(2) := (ready => '0', rdata => x"00", info => (name => to_sbi_name("t2")));
    check_tgt("or(sbi_tgts_t), every target idle"            , "or"(v_tgts), (ready => '0', rdata => x"00", info => (name => to_sbi_name("ored"))));

    log(ID_SEQUENCER, "sbi_ini_null / sbi_tgt_null : idle request and response, same ranges", C_TB_SCOPE);
    check_ini("sbi_ini_null", sbi_ini_null(v_ia), (cs => '0', re => '0', we => '0', addr => x"00", wdata => x"00"));
    check_tgt("sbi_tgt_null", sbi_tgt_null(v_ta), (ready => '0', rdata => x"00", info => (name => to_sbi_name("null"))));

    log(ID_SEQUENCER, "to_sbi_name : padded with spaces, truncated to NAME_MAX_LEN", C_TB_SCOPE);
    check_value(to_sbi_name("t1")                , "t1              ", ERROR, "to_sbi_name(t1)"                , C_TB_SCOPE);
    check_value(to_sbi_name("0123456789abcdefXY"), "0123456789abcdef", ERROR, "to_sbi_name(0123456789abcdefXY)", C_TB_SCOPE);
  end procedure;

end package body tb_pkg_sbi_pkg;
