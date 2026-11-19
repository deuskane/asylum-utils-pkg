-------------------------------------------------------------------------------
-- Title      : tb_sbi_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_sbi_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking testbench of the "=" / "/=" of sbi_ini_t :
--              every combination of cs, re, we of the two requests, with
--              addr and wdata equal or different, is compared with a
--              reference model (cs, re and we always compared, addr only
--              when cs = '1', wdata only when cs = '1' and we = '1').
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-19  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.sbi_pkg.all;

entity tb_sbi_pkg is
end entity tb_sbi_pkg;

architecture sim of tb_sbi_pkg is

  constant C_SCOPE : string := "TB_SBI_PKG";

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

  function to_sl(i : natural; bit : natural) return std_logic is
  begin
    if (i / 2**bit) mod 2 = 1
    then
      return '1';
    else
      return '0';
    end if;
  end function;

begin

  p_main : process
    variable v_a      : ini_t;
    variable v_b      : ini_t;
    variable v_nb_eq  : natural := 0;
    variable v_nb_ne  : natural := 0;
  begin
    log(ID_LOG_HDR, "START: sbi_pkg comparison of sbi_ini_t", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, """="" / ""/="" : cs, re, we of both requests x addr x wdata", C_SCOPE);
    ---------------------------------------------------------------------------
    -- bits 2..0 : cs, re, we of a ; bits 5..3 : cs, re, we of b
    -- bit  6    : addr  differs   ; bit  7    : wdata differs
    for i in 0 to 2**8-1
    loop
      v_a.cs    := to_sl(i,2);
      v_a.re    := to_sl(i,1);
      v_a.we    := to_sl(i,0);
      v_a.addr  := x"3C";
      v_a.wdata := x"A5";
      v_b.cs    := to_sl(i,5);
      v_b.re    := to_sl(i,4);
      v_b.we    := to_sl(i,3);
      v_b.addr  := x"3C" xor (8-1 downto 0 => to_sl(i,6));
      v_b.wdata := x"A5" xor (8-1 downto 0 => to_sl(i,7));

      check_value(v_a  = v_b,     ref_equal(v_a,v_b), ERROR, """="" case "  & integer'image(i));
      check_value(v_a /= v_b, not ref_equal(v_a,v_b), ERROR, """/="" case " & integer'image(i));

      if ref_equal(v_a,v_b)
      then
        v_nb_eq := v_nb_eq + 1;
      else
        v_nb_ne := v_nb_ne + 1;
      end if;
    end loop;

    -- Equal requests : same control (8 cases), addr and wdata ignored or equal :
    --   cs = 0      : 4 cases x 4 (addr, wdata free)            = 16
    --   cs = 1 we 0 : 2 cases x 2 (wdata free, addr equal)      =  4
    --   cs = 1 we 1 : 2 cases x 1 (addr and wdata equal)        =  2
    check_value(v_nb_eq,      22, ERROR, "number of equal requests");
    check_value(v_nb_ne, 256-22, ERROR, "number of different requests");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "Directed : idle bus, read, write", C_SCOPE);
    ---------------------------------------------------------------------------
    v_a := (cs => '0', re => '0', we => '0', addr => x"12", wdata => x"34");
    v_b := (cs => '0', re => '0', we => '0', addr => x"FF", wdata => x"00");
    check_value(v_a  = v_b, true , ERROR, "idle : addr and wdata ignored");
    v_a := (cs => '1', re => '1', we => '0', addr => x"12", wdata => x"34");
    v_b := (cs => '1', re => '1', we => '0', addr => x"12", wdata => x"00");
    check_value(v_a  = v_b, true , ERROR, "read : wdata ignored");
    v_b.addr := x"13";
    check_value(v_a /= v_b, true , ERROR, "read : addr compared");
    v_a := (cs => '1', re => '0', we => '1', addr => x"12", wdata => x"34");
    v_b := (cs => '1', re => '0', we => '1', addr => x"12", wdata => x"35");
    check_value(v_a /= v_b, true , ERROR, "write : wdata compared");

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end architecture sim;
