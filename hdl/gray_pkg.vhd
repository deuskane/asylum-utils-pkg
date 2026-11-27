-------------------------------------------------------------------------------
-- Title      : gray_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : gray_pkg.vhd
-- Author     : mrosiere
-- Company    :
-- Created    : 2026-11-27
-- Last update: 2026-11-27
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Gray code (reflected binary) : two consecutive values differ
--              by one bit, also from the largest value back to 0. A counter
--              sent to another clock domain in Gray code through a
--              synchronizer is read as the old or the new value, never a
--              mix (pointers of a dual-clock FIFO).
--              * bin2gray(b) = b xor (b >> 1)
--              * gray2bin(g) : bit i = xor of the bits i and up of g
--              Any width and range ; the result has the range
--              (length-1 downto 0).
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-27  1.0      mrosiere Created (functions of fifo_async)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

package gray_pkg is

  function bin2gray(b : std_logic_vector) return std_logic_vector;
  function gray2bin(g : std_logic_vector) return std_logic_vector;

end package gray_pkg;

package body gray_pkg is

  function bin2gray(b : std_logic_vector) return std_logic_vector is
    alias    v_b : std_logic_vector(b'length-1 downto 0) is b;
    variable v_g : std_logic_vector(b'length-1 downto 0);
  begin
    v_g := v_b xor ('0' & v_b(b'length-1 downto 1));
    return v_g;
  end function bin2gray;

  function gray2bin(g : std_logic_vector) return std_logic_vector is
    alias    v_g : std_logic_vector(g'length-1 downto 0) is g;
    variable v_b : std_logic_vector(g'length-1 downto 0);
  begin
    v_b(g'length-1) := v_g(g'length-1);
    for i in g'length-2 downto 0
    loop
      v_b(i) := v_b(i+1) xor v_g(i);
    end loop;
    return v_b;
  end function gray2bin;

end package body gray_pkg;
