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

  function to_stdulogic( V: Boolean ) return std_ulogic; 
    
end convert_pkg;

package body convert_pkg is

  function to_stdulogic( V: Boolean ) return std_ulogic is 
  begin 
    if V
    then 
      return '1'; 
    else 
      return '0';
    end if;     
  end to_stdulogic;

end convert_pkg;
