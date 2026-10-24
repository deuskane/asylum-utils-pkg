-------------------------------------------------------------------------------
-- Title      : string_pkg
-- Project    : 
-------------------------------------------------------------------------------
-- Description: Collection of string function
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-03-19  1.0      mrosiere Created
-- 2026-07-29  1.1      mrosiere Add function to_string for std_logic
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package string_pkg is

  function string_eq (str1 : string; str2 : string) return boolean; 
  function string_ne (str1 : string; str2 : string) return boolean; 
  -- In VHDL-2008, std_logic_1164 implicitly declares TO_STRING for
  -- std_ulogic and std_ulogic_vector. These explicit homographs hide them
  -- where string_pkg is used (LRM 2008 12.4, no ambiguity), so they return
  -- the same format : one character per bit, without quotes.
  -- They are kept for VHDL-93 users and backward compatibility.
  function to_string ( a: std_logic_vector) return string;
  function to_string ( a: std_logic       ) return string;  
end string_pkg;

package body string_pkg is

  function string_eq(str1 : string; str2 : string) return boolean is
    -- Compare by position : the strings may have different index ranges
    alias s1 : string(1 to str1'length) is str1;
    alias s2 : string(1 to str2'length) is str2;
  begin
    if str1'length /= str2'length then
      return false;
    else
      for i in s1'range loop
        if s1(i) /= s2(i) then
          return false;
        end if;
      end loop;
      return true;
    end if;
  end function;

  function string_ne(str1 : string; str2 : string) return boolean is
    -- Compare by position : the strings may have different index ranges
    alias s1 : string(1 to str1'length) is str1;
    alias s2 : string(1 to str2'length) is str2;
  begin
    if str1'length /= str2'length then
      return true;
    else
      for i in s1'range loop
        if s1(i) /= s2(i) then
          return true;
        end if;
      end loop;
      return false;
    end if;
  end function;

  function to_string ( a: std_logic_vector) return string is
    variable b : string (1 to a'length) := (others => NUL);
    variable stri : integer := 1; 
  begin
    for i in a'range loop
      b(stri) := std_logic'image(a((i)))(2);
      stri := stri+1;
    end loop;
    return b;
  end function;

  function to_string ( a: std_logic) return string is
    variable b : string (1 to 1);
  begin
    -- std_logic'image returns the literal with its quotes ('1')
    b(1) := std_logic'image(a)(2);
    return b;
  end function;
 
end string_pkg;
