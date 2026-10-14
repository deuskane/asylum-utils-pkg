-------------------------------------------------------------------------------
-- Title      : tb_ft_dff_inj_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_dff_inj_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Fault injection control of tb_ft_dff, shared by the testbench
--              (driver) and the injectors tb_ft_enc_inj (one per ft_dff).
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-14  1.0      mrosiere Created (fault injection of tb_ft_dff)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

package tb_ft_dff_inj_pkg is

  -- Fault injection patterns on the encoded register
  type inj_kind_t is (INJ_BIT0,     -- flip bit 0
                      INJ_BIT01,    -- flip bits 0 and 1
                      INJ_TOP);     -- flip the MSB of the encoded word

  signal inj_en       : std_logic  := '0';
  signal inj_kind     : inj_kind_t := INJ_BIT0;

end package tb_ft_dff_inj_pkg;
