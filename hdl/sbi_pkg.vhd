-------------------------------------------------------------------------------
-- Title      : sbi
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : sbi_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2025-11-22
-- Last update: 2025-11-22
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Collection of sbi function
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2025-11-22  1.0      mrosiere Created
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

package sbi_pkg is
  constant SBI_ADDR_WIDTH : natural := 8;
  constant SBI_DATA_WIDTH : natural := 8;

  type sbi_addrs_t is array (natural range <>) of std_logic_vector(SBI_ADDR_WIDTH-1 downto 0);
  type sbi_datas_t is array (natural range <>) of std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
  type naturals_t  is array (natural range <>) of natural;
  
  type sbi_ini_t is record
    cs           : std_logic;        -- Chip Select        (READ_STROBE or WRITE_STROBE)
    re           : std_logic;        -- Have a valid read  (READ_STROBE)
    we           : std_logic;        -- Have a valid write (WRITE_STROBE)
    addr         : std_logic_vector; -- Access address     (PORT_ID)
    wdata        : std_logic_vector; -- Write data         (OUT_PORT)
  end record sbi_ini_t;

  type sbi_tgt_t is record
    ready        : std_logic;        -- Additionnal port
    rdata        : std_logic_vector; -- Read data          (IN_PORT)
  end record sbi_tgt_t;
  
  function "and" (i0, i1 : sbi_ini_t) return sbi_ini_t;
  function "or"  (i0, i1 : sbi_ini_t) return sbi_ini_t;
  function "xor" (i0, i1 : sbi_ini_t) return sbi_ini_t;

  function "and" (i0, i1 : sbi_tgt_t) return sbi_tgt_t;
  function "or"  (i0, i1 : sbi_tgt_t) return sbi_tgt_t;
  function "xor" (i0, i1 : sbi_tgt_t) return sbi_tgt_t;

  type sbi_inis_t is array (natural range <>) of sbi_ini_t;
  type sbi_tgts_t is array (natural range <>) of sbi_tgt_t;

  function "or"  (i0 : sbi_tgts_t)    return sbi_tgt_t;

end sbi_pkg;

package body sbi_pkg is

  function "and" (i0, i1 : sbi_ini_t) return sbi_ini_t is
    variable z : sbi_ini_t(addr (i0.addr 'range),
                            wdata(i0.wdata'range));
  begin
    z.cs    := i0.cs    and i1.cs    ;
    z.re    := i0.re    and i1.re    ;
    z.we    := i0.we    and i1.we    ;
    z.addr  := i0.addr  and i1.addr  ;
    z.wdata := i0.wdata and i1.wdata ;

    return z;
  end function "and";

  function "or" (i0, i1 : sbi_ini_t) return sbi_ini_t is
    variable z : sbi_ini_t(addr (i0.addr 'range),
                           wdata(i0.wdata'range));
  begin
    z.cs    := i0.cs    or i1.cs    ;
    z.re    := i0.re    or i1.re    ;
    z.we    := i0.we    or i1.we    ;
    z.addr  := i0.addr  or i1.addr  ;
    z.wdata := i0.wdata or i1.wdata ;

    return z;
  end function "or";

  function "xor" (i0, i1 : sbi_ini_t) return sbi_ini_t is
    variable z : sbi_ini_t(addr (i0.addr 'range),
                            wdata(i0.wdata'range));
  begin
    z.cs    := i0.cs    xor i1.cs    ;
    z.re    := i0.re    xor i1.re    ;
    z.we    := i0.we    xor i1.we    ;
    z.addr  := i0.addr  xor i1.addr  ;
    z.wdata := i0.wdata xor i1.wdata ;

    return z;
  end function "xor";

  function "and" (i0, i1 : sbi_tgt_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.ready := i0.ready and i1.ready ;
    z.rdata := i0.rdata and i1.rdata ;

    return z;
  end function "and";

  function "or" (i0, i1 : sbi_tgt_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.ready := i0.ready or i1.ready ;
    z.rdata := i0.rdata or i1.rdata ;

    return z;
  end function "or";

  function "xor" (i0, i1 : sbi_tgt_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.ready := i0.ready xor i1.ready ;
    z.rdata := i0.rdata xor i1.rdata ;

    return z;
  end function "xor";

  function "or" (i0 : sbi_tgts_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0(0).rdata'range));
  begin
    z.ready := '0';
    z.rdata := (others => '0');

    for i in i0'range loop
      z := z or i0(i);
    end loop;  -- i
    
    return z;
  end function "or";

  
end package body sbi_pkg;
