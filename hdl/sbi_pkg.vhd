-------------------------------------------------------------------------------
-- Title      : sbi
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : sbi_pkg.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2025-11-22
-- Last update: 2026-11-23
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
-- 2026-06-16  1.1      mrosiere Add null functions
-- 2026-10-05  1.2      mrosiere naturals_t is an alias of types_pkg.naturals_t
-- 2026-11-19  1.3      mrosiere "=" / "/=" of sbi_ini_t : addr compared only when
--                               cs = '1', wdata only when we = '1'
-- 2026-11-23  1.4      mrosiere vote of sbi_ini_t and of sbi_tgt_t
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     std.textio.all;
library asylum;
use     asylum.types_pkg.all;

package sbi_pkg is
  constant NAME_MAX_LEN   : positive := 16;
  constant SBI_ADDR_WIDTH : natural  := 8;
  constant SBI_DATA_WIDTH : natural  := 8;

  type sbi_addrs_t is array (natural range <>) of std_logic_vector(SBI_ADDR_WIDTH-1 downto 0);
  type sbi_datas_t is array (natural range <>) of std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
  -- Declared once in types_pkg (avoids an ambiguity when sbi_pkg and
  -- pbi_pkg are both used), re-exported here for backward compatibility
  alias naturals_t is asylum.types_pkg.naturals_t;
  
  type sbi_ini_t is record
    cs           : std_logic;        -- Chip Select        (READ_STROBE or WRITE_STROBE)
    re           : std_logic;        -- Have a valid read  (READ_STROBE)
    we           : std_logic;        -- Have a valid write (WRITE_STROBE)
    addr         : std_logic_vector; -- Access address     (PORT_ID)
    wdata        : std_logic_vector; -- Write data         (OUT_PORT)
  end record sbi_ini_t;

  type sbi_tgt_info_t is record
    name         : string(1 to NAME_MAX_LEN);
  end record sbi_tgt_info_t;

  type sbi_tgt_t is record
    ready        : std_logic;        -- Additionnal port
    rdata        : std_logic_vector; -- Read data          (IN_PORT)

    info         : sbi_tgt_info_t;
  end record sbi_tgt_t;
  
  function to_sbi_name(s : string) return string;
  
  function sbi_ini_null(i : sbi_ini_t) return sbi_ini_t;
  function sbi_tgt_null(i : sbi_tgt_t) return sbi_tgt_t;

  function "and" (i0, i1 : sbi_ini_t) return sbi_ini_t;
  function "or"  (i0, i1 : sbi_ini_t) return sbi_ini_t;
  function "xor" (i0, i1 : sbi_ini_t) return sbi_ini_t;

  -- Comparison of two requests : cs, re and we are always compared, addr only when
  -- cs = '1' and wdata only when we = '1' (their value is meaningless outside an
  -- access). They replace the predefined "=" / "/=" of the record
  function "="   (i0, i1 : sbi_ini_t) return boolean;
  function "/="  (i0, i1 : sbi_ini_t) return boolean;

  function "and" (i0, i1 : sbi_tgt_t) return sbi_tgt_t;
  function "or"  (i0, i1 : sbi_tgt_t) return sbi_tgt_t;
  function "xor" (i0, i1 : sbi_tgt_t) return sbi_tgt_t;

  -- Majority vote of three copies (TMR), bit by bit on every field :
  -- (i0 and i1) or (i1 and i2) or (i2 and i0). The result takes the
  -- addr / wdata / rdata ranges of i0 (the three copies have the same
  -- widths). info.name of the voted response is "voted"
  function vote  (i0, i1, i2 : sbi_ini_t) return sbi_ini_t;
  function vote  (i0, i1, i2 : sbi_tgt_t) return sbi_tgt_t;

  type sbi_inis_t is array (natural range <>) of sbi_ini_t;
  type sbi_tgts_t is array (natural range <>) of sbi_tgt_t;

  function "or"  (i0 : sbi_tgts_t)    return sbi_tgt_t;

end sbi_pkg;

package body sbi_pkg is

  function to_sbi_name(s : string) return string is
        variable res : string(1 to NAME_MAX_LEN) := (others => ' ');
    begin
        -- On tronque si c'est trop long, ou on copie si c'est plus court
        if s'length > NAME_MAX_LEN then
            res := s(s'left to s'left + NAME_MAX_LEN - 1);
        else
            res(1 to s'length) := s;
        end if;
        return res;
    end function;

  function sbi_ini_null(i : sbi_ini_t) return sbi_ini_t is
    variable z : sbi_ini_t(addr (i.addr 'range),
                           wdata(i.wdata'range));
  begin
    z.cs    := '0';
    z.re    := '0';
    z.we    := '0';
    z.addr  := (others => '0');
    z.wdata := (others => '0');
    return z;
  end function;

  function sbi_tgt_null(i : sbi_tgt_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i.rdata'range));
  begin
    z.ready     := '0';
    z.rdata     := (others => '0');
    z.info.name := to_sbi_name("null");
    return z;
  end function;

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

  function "=" (i0, i1 : sbi_ini_t) return boolean is
  begin
    return (i0.cs = i1.cs) and
           (i0.re = i1.re) and
           (i0.we = i1.we) and
           ((i0.cs = '0')                  or (i0.addr  = i1.addr )) and
           ((i0.cs = '0') or (i0.we = '0') or (i0.wdata = i1.wdata));
  end function "=";

  function "/=" (i0, i1 : sbi_ini_t) return boolean is
  begin
    return not (i0 = i1);
  end function "/=";

  function "and" (i0, i1 : sbi_tgt_t) return sbi_tgt_t is
    variable z    : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.ready     := i0.ready and i1.ready ;
    z.rdata     := i0.rdata and i1.rdata ;

    z.info.name := to_sbi_name("anded");

    return z;
  end function "and";

  function "or" (i0, i1 : sbi_tgt_t) return sbi_tgt_t is
    variable z    : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.ready     := i0.ready or i1.ready ;
    z.rdata     := i0.rdata or i1.rdata ;

    z.info.name := to_sbi_name("ored");

    return z;
  end function "or";

  function "xor" (i0, i1 : sbi_tgt_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z.ready     := i0.ready xor i1.ready ;
    z.rdata     := i0.rdata xor i1.rdata ;

    z.info.name := to_sbi_name("xored");

    return z;
  end function "xor";

  function vote (i0, i1, i2 : sbi_ini_t) return sbi_ini_t is
  begin
    return (i0 and i1) or (i1 and i2) or (i2 and i0);
  end function vote;

  function vote (i0, i1, i2 : sbi_tgt_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0.rdata'range));
  begin
    z           := (i0 and i1) or (i1 and i2) or (i2 and i0);
    z.info.name := to_sbi_name("voted");

    return z;
  end function vote;

  function "or" (i0 : sbi_tgts_t) return sbi_tgt_t is
    variable z : sbi_tgt_t(rdata(i0(i0'low).rdata'range));
  begin
    z.ready    := '0';
    z.rdata    := (others => '0');

    for i in i0'range loop
      z := z or i0(i);
    end loop;  -- i

    z.info.name := to_sbi_name("ored");
    
    return z;
  end function "or";

  
end package body sbi_pkg;
