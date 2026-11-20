-------------------------------------------------------------------------------
-- Title      : tb_pkg_bfm_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_bfm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_pkg scenarios : scope and reference
--              functions written bit by bit, independently from the
--              packages under test.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

package tb_pkg_bfm_pkg is

  constant C_TB_SCOPE : string := "TB_PKG";

  -- '1' when b is true
  function to_sl
    (constant b        : in    boolean
    ) return std_logic;

  -- Number of bits at '1'
  function ref_count
    (constant x        : in    std_logic_vector
    ) return natural;

end package tb_pkg_bfm_pkg;

package body tb_pkg_bfm_pkg is

  function to_sl
    (constant b        : in    boolean
    ) return std_logic is
  begin
    if b
    then
      return '1';
    else
      return '0';
    end if;
  end function;

  function ref_count
    (constant x        : in    std_logic_vector
    ) return natural is
    variable n         : natural := 0;
  begin
    for i in x'range loop
      if x(i) = '1'
      then
        n := n + 1;
      end if;
    end loop;
    return n;
  end function;

end package body tb_pkg_bfm_pkg;
