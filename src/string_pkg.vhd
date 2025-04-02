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
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package string_pkg is

  function string_eq (str1 : string; str2 : string) return boolean; 
  function string_ne (str1 : string; str2 : string) return boolean; 
  
end string_pkg;

package body string_pkg is

  function string_eq(str1 : string; str2 : string) return boolean is
  begin
    if str1'length /= str2'length then
      return false;
    else
      for i in str1'range loop
        if str1(i) /= str2(i) then
          return false;
        end if;
      end loop;
      return true;
    end if;
  end function;

  function string_ne(str1 : string; str2 : string) return boolean is
  begin
    if str1'length /= str2'length then
      return true;
    else
      for i in str1'range loop
        if str1(i) /= str2(i) then
          return true;
        end if;
      end loop;
      return false;
    end if;
  end function;
 
end string_pkg;
