-------------------------------------------------------------------------------
-- Title      : logic_pkg
-- Project    : 
-------------------------------------------------------------------------------
-- Description: Collection of logical function
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-03-19  1.0      mrosiere Created
-- 2025-11-29  1.1      mrosiere Add mux2 and reverse_bits
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package logic_pkg is

  type sls_t  is array (natural range <>) of std_logic;
  type slvs_t is array (natural range <>) of std_logic_vector;

  
  function reduce_xor  (x       : std_logic_vector) return std_logic;
  function reduce_and  (x       : std_logic_vector) return std_logic;
  function reduce_or   (x       : std_logic_vector) return std_logic;
  function mux2        (sel     : boolean;
                        d_true  : std_logic_vector;
                        d_false : std_logic_vector) return std_logic_vector;
  function mux2        (sel     : boolean;
                        d_true  : natural;
                        d_false : natural) return natural;
  
  function reverse_bits(v       : std_logic_vector) return std_logic_vector ;

end logic_pkg;

package body logic_pkg is
  
  function reduce_xor(x : std_logic_vector) return std_logic is
    variable z : std_logic := '0';
  begin
    for i in x'range loop
      z := z xor x(i);
    end loop;
    return z;
  end reduce_xor;

  function reduce_and(x : std_logic_vector) return std_logic is
    variable z : std_logic := '0';
  begin
    for i in x'range loop
      z := z and x(i);
    end loop;
    return z;
  end reduce_and;

  function reduce_or(x : std_logic_vector) return std_logic is
    variable z : std_logic := '0';
  begin
    for i in x'range loop
      z := z or x(i);
    end loop;
    return z;
  end reduce_or;
    
  function mux2(sel     : boolean;
                d_true  : std_logic_vector;
                d_false : std_logic_vector) return std_logic_vector is
  begin
    if sel
    then
      return d_true;
    else
      return d_false;
    end if;
  end function;

  function mux2(sel     : boolean;
                d_true  : natural;
                d_false : natural) return natural is
  begin
    if sel
    then
      return d_true;
    else
      return d_false;
    end if;
  end function;
  
  -- Function to reverse bits in a vector
  function reverse_bits(v : std_logic_vector) return std_logic_vector is
    variable res : std_logic_vector(v'range);
  begin
    for i in v'range loop
      res(i) := v(v'length-1 - i);
    end loop;
    return res;
  end function;

end logic_pkg;
