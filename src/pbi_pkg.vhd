-------------------------------------------------------------------------------
-- Title      : pbi
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : pbi_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2017-03-15
-- Last update: 2025-03-30
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Collection of pbi function
-------------------------------------------------------------------------------
-- Copyright (c) 2017
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2017-03-15  1.0      mrosiere	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pbi_pkg is
  constant PBI_ADDR_WIDTH : natural := 8;
  constant PBI_DATA_WIDTH : natural := 8;

  type pbi_addrs_t     is array (natural range <>) of std_logic_vector(PBI_ADDR_WIDTH-1 downto 0);
  type pbi_datas_t     is array (natural range <>) of std_logic_vector(PBI_DATA_WIDTH-1 downto 0);
  type pbi_naturals_t  is array (natural range <>) of natural;
  
  type pbi_ini_t is record
    cs           : std_logic;                                   -- Have a valid read  (READ_STROBE)
    re           : std_logic;                                   -- Have a valid read  (READ_STROBE)
    we           : std_logic;                                   -- Have a valid write (WRITE_STROBE)
    addr         : std_logic_vector;                            -- Access address     (PORT_ID)
    wdata        : std_logic_vector;                            -- Write data         (OUT_PORT)
  end record pbi_ini_t;

  type pbi_tgt_t is record
    busy         : std_logic;                                   -- Additionnal port
    rdata        : std_logic_vector;                            -- Read data          (IN_PORT)
  end record pbi_tgt_t;
  
  function "and" (i0, i1 : pbi_ini_t) return pbi_ini_t;
  function "or"  (i0, i1 : pbi_ini_t) return pbi_ini_t;
  function "xor" (i0, i1 : pbi_ini_t) return pbi_ini_t;

  function "and" (i0, i1 : pbi_tgt_t) return pbi_tgt_t;
  function "or"  (i0, i1 : pbi_tgt_t) return pbi_tgt_t;
  function "xor" (i0, i1 : pbi_tgt_t) return pbi_tgt_t;

  type pbi_inis_t is array (natural range <>) of pbi_ini_t;
  type pbi_tgts_t is array (natural range <>) of pbi_tgt_t;

  function "or"  (i0 : pbi_tgts_t)    return pbi_tgt_t;

end pbi_pkg;

package body pbi_pkg is

  function "and" (i0, i1 : pbi_ini_t) return pbi_ini_t is
    variable z : pbi_ini_t(addr (i0.addr 'range),
                            wdata(i0.wdata'range));
  begin
    z.cs    := i0.cs    and i1.cs    ;
    z.re    := i0.re    and i1.re    ;
    z.we    := i0.we    and i1.we    ;
    z.addr  := i0.addr  and i1.addr  ;
    z.wdata := i0.wdata and i1.wdata ;

    return z;
  end function "and";

  function "or" (i0, i1 : pbi_ini_t) return pbi_ini_t is
    variable z : pbi_ini_t(addr (i0.addr 'range),
                           wdata(i0.wdata'range));
  begin
    z.cs    := i0.cs    or i1.cs    ;
    z.re    := i0.re    or i1.re    ;
    z.we    := i0.we    or i1.we    ;
    z.addr  := i0.addr  or i1.addr  ;
    z.wdata := i0.wdata or i1.wdata ;

    return z;
  end function "or";

  function "xor" (i0, i1 : pbi_ini_t) return pbi_ini_t is
    variable z : pbi_ini_t(addr (i0.addr 'range),
                            wdata(i0.wdata'range));
  begin
    z.cs    := i0.cs    xor i1.cs    ;
    z.re    := i0.re    xor i1.re    ;
    z.we    := i0.we    xor i1.we    ;
    z.addr  := i0.addr  xor i1.addr  ;
    z.wdata := i0.wdata xor i1.wdata ;

    return z;
  end function "xor";

  function "and" (i0, i1 : pbi_tgt_t) return pbi_tgt_t is
    variable z : pbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.busy  := i0.busy  and i1.busy  ;
    z.rdata := i0.rdata and i1.rdata ;

    return z;
  end function "and";

  function "or" (i0, i1 : pbi_tgt_t) return pbi_tgt_t is
    variable z : pbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.busy  := i0.busy  or i1.busy  ;
    z.rdata := i0.rdata or i1.rdata ;

    return z;
  end function "or";

  function "xor" (i0, i1 : pbi_tgt_t) return pbi_tgt_t is
    variable z : pbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.busy  := i0.busy  xor i1.busy  ;
    z.rdata := i0.rdata xor i1.rdata ;

    return z;
  end function "xor";

  function "or" (i0 : pbi_tgts_t) return pbi_tgt_t is
    variable z : pbi_tgt_t(rdata(i0(0).rdata'range));
  begin
    z.busy  := '0';
    z.rdata := (others => '0');

    for i in i0'range loop
      z := z or i0(i);
    end loop;  -- i
    
    return z;
  end function "or";

  
end package body pbi_pkg;
