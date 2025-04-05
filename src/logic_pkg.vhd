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
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package logic_pkg is

  function reduce_xor(x : std_logic_vector) return std_logic;
  function reduce_and(x : std_logic_vector) return std_logic;
  function reduce_or (x : std_logic_vector) return std_logic;

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
    
end logic_pkg;
