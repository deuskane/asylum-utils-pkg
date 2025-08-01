-------------------------------------------------------------------------------
-- Title      : convert_pkg
-- Project    : 
-------------------------------------------------------------------------------
-- Description: Collection of convertion function
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

package convert_pkg is

  function to_stdulogic     ( V: boolean )
    return std_ulogic; 

  function onehot_to_integer(one_hot : std_logic_vector)
    return integer;
  
end convert_pkg;

package body convert_pkg is

  function to_stdulogic( V: boolean ) return std_ulogic is 
  begin 
    if V
    then 
      return '1'; 
    else 
      return '0';
    end if;     
  end to_stdulogic;

  function onehot_to_integer(one_hot : std_logic_vector) return integer  is
    variable result : integer := -1; -- Defaut value for invalid case
  begin
    for i in 0 to one_hot'length - 1
    loop
      if one_hot(i) = '1'
      then
        if result = -1
        then
          result := i;
        else
          return -1;
        end if;
      end if;
    end loop;
    return result;
  end function;

  
end convert_pkg;
