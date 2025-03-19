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

  function string_eq(s1 : string; s2 : string) return boolean; 
    
end string_pkg;

package body string_pkg is

  function string_eq(s1 : string; s2 : string) return boolean is
  begin
    if s1'length /= s2'length then
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

end string_pkg;
