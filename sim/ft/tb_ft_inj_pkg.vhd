-------------------------------------------------------------------------------
-- Title      : tb_ft_inj_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_inj_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Fault injection control of tb_ft, shared by the sequencer
--              (driver) and the injectors tb_ft_enc_inj (one per ft_dff).
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-14  1.0      mrosiere Created (fault injection of tb_ft_dff)
-- 2026-11-20  1.1      mrosiere Renamed tb_ft_inj_pkg (tb_ft)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

package tb_ft_inj_pkg is

  -- Fault injection patterns on the encoded register
  type inj_kind_t is (INJ_BIT0,     -- flip bit 0
                      INJ_BIT01,    -- flip bits 0 and 1
                      INJ_TOP);     -- flip the MSB of the encoded word

  signal inj_en       : std_logic  := '0';
  signal inj_kind     : inj_kind_t := INJ_BIT0;

  -- Mask of the pattern kind on an encoded word of width bits
  function inj_mask(kind : inj_kind_t; width : positive) return std_logic_vector;

end package tb_ft_inj_pkg;

package body tb_ft_inj_pkg is

  function inj_mask(kind : inj_kind_t; width : positive) return std_logic_vector is
    variable mask : std_logic_vector(width-1 downto 0) := (others => '0');
  begin
    case kind is
      when INJ_BIT0  => mask(0)          := '1';
      when INJ_BIT01 => mask(1 downto 0) := "11";
      when INJ_TOP   => mask(width-1)    := '1';
    end case;
    return mask;
  end function;

end package body tb_ft_inj_pkg;
