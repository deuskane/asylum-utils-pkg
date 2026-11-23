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
--              - vote of sbi_ini_t and of sbi_tgt_t, on two widths, against
--                a reference majority (count of '1') : every combination
--                of the three copies, random copies, one copy different in
--                every field
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_sbi_pkg and tb_logic_pkg,
--                               to_sbi_name added)
-- 2026-11-23  1.1      mrosiere vote of sbi_ini_t and of sbi_tgt_t
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

  -- Comparison of sbi_ini_t, "or" of sbi_tgts_t, to_sbi_name, vote
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

  -- Reference majority of three bits, from the number of '1' (independent
  -- of the "and" / "or" of sbi_pkg)
  function ref_vote(a, b, c : std_logic) return std_logic is
  begin
    return to_sl(ref_count(a & b & c) >= 2);
  end function;

  function ref_vote(a, b, c : std_logic_vector) return std_logic_vector is
    variable z : std_logic_vector(a'range);
  begin
    for i in a'range
    loop
      z(i) := ref_vote(a(i), b(i), c(i));
    end loop;
    return z;
  end function;

  -- Reference vote of three requests and of three responses, field by field
  function ref_vote(i0, i1, i2 : sbi_ini_t) return sbi_ini_t is
    variable z : sbi_ini_t(addr (i0.addr 'range),
                           wdata(i0.wdata'range));
  begin
    z.cs    := ref_vote(i0.cs   , i1.cs   , i2.cs   );
    z.re    := ref_vote(i0.re   , i1.re   , i2.re   );
    z.we    := ref_vote(i0.we   , i1.we   , i2.we   );
    z.addr  := ref_vote(i0.addr , i1.addr , i2.addr );
    z.wdata := ref_vote(i0.wdata, i1.wdata, i2.wdata);
    return z;
  end function;

  function ref_vote(i0, i1, i2 : sbi_tgt_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.ready     := ref_vote(i0.ready, i1.ready, i2.ready);
    z.rdata     := ref_vote(i0.rdata, i1.rdata, i2.rdata);
    z.info.name := to_sbi_name("voted");
    return z;
  end function;

  -- vote of three sbi_ini_t (addr on addr_w bits, wdata on data_w bits) and
  -- of three sbi_tgt_t (rdata on data_w bits)
  procedure check_vote(addr_w, data_w : positive) is
    constant C_MSG      : string := "vote (addr " & integer'image(addr_w) &
                                    ", data " & integer'image(data_w) & ")";
    variable v_ini      : sbi_inis_t(0 to 2)(addr (addr_w-1 downto 0),
                                             wdata(data_w-1 downto 0));
    variable v_tgt      : sbi_tgts_t(0 to 2)(rdata(data_w-1 downto 0));
    variable v_ini_base : sbi_ini_t(addr (addr_w-1 downto 0),
                                    wdata(data_w-1 downto 0));
    variable v_tgt_base : sbi_tgt_t(rdata(data_w-1 downto 0));
  begin
    log(ID_SEQUENCER, C_MSG & " : every combination of the three copies", C_TB_SCOPE);
    -- Every bit of copy k is bit k of c
    for c in 0 to 2**3-1
    loop
      for k in 0 to 2
      loop
        v_ini(k).cs        := bit_of(c,k);
        v_ini(k).re        := bit_of(c,k);
        v_ini(k).we        := bit_of(c,k);
        v_ini(k).addr      := (others => bit_of(c,k));
        v_ini(k).wdata     := (others => bit_of(c,k));
        v_tgt(k).ready     := bit_of(c,k);
        v_tgt(k).rdata     := (others => bit_of(c,k));
        v_tgt(k).info.name := to_sbi_name("t" & integer'image(k));
      end loop;
      check_ini(C_MSG & " copies " & integer'image(c), vote(v_ini(0), v_ini(1), v_ini(2)), ref_vote(v_ini(0), v_ini(1), v_ini(2)));
      check_tgt(C_MSG & " copies " & integer'image(c), vote(v_tgt(0), v_tgt(1), v_tgt(2)), ref_vote(v_tgt(0), v_tgt(1), v_tgt(2)));
    end loop;

    log(ID_SEQUENCER, C_MSG & " : random copies", C_TB_SCOPE);
    for i in 0 to 32-1
    loop
      for k in 0 to 2
      loop
        v_ini(k).cs    := random(VOID);
        v_ini(k).re    := random(VOID);
        v_ini(k).we    := random(VOID);
        v_ini(k).addr  := random(addr_w);
        v_ini(k).wdata := random(data_w);
        v_tgt(k).ready := random(VOID);
        v_tgt(k).rdata := random(data_w);
      end loop;
      check_ini(C_MSG & " random " & integer'image(i), vote(v_ini(0), v_ini(1), v_ini(2)), ref_vote(v_ini(0), v_ini(1), v_ini(2)));
      check_tgt(C_MSG & " random " & integer'image(i), vote(v_tgt(0), v_tgt(1), v_tgt(2)), ref_vote(v_tgt(0), v_tgt(1), v_tgt(2)));
    end loop;

    log(ID_SEQUENCER, C_MSG & " : one copy different in every field", C_TB_SCOPE);
    -- Copies equal to a random base, but copy k inverted in every bit of
    -- every field : the vote is the base
    v_ini_base           := v_ini(0);
    v_tgt_base           := v_tgt(0);
    v_tgt_base.info.name := to_sbi_name("voted");
    for k in 0 to 2
    loop
      v_ini          := (others => v_ini_base);
      v_tgt          := (others => v_tgt_base);
      v_ini(k).cs    := not v_ini(k).cs;
      v_ini(k).re    := not v_ini(k).re;
      v_ini(k).we    := not v_ini(k).we;
      v_ini(k).addr  := not v_ini(k).addr;
      v_ini(k).wdata := not v_ini(k).wdata;
      v_tgt(k).ready := not v_tgt(k).ready;
      v_tgt(k).rdata := not v_tgt(k).rdata;
      check_ini(C_MSG & " copy " & integer'image(k) & " inverted", vote(v_ini(0), v_ini(1), v_ini(2)), v_ini_base);
      check_tgt(C_MSG & " copy " & integer'image(k) & " inverted", vote(v_tgt(0), v_tgt(1), v_tgt(2)), v_tgt_base);
    end loop;
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

    check_vote( 8,  8);
    check_vote(12, 32);
  end procedure;

end package body tb_pkg_sbi_pkg;
