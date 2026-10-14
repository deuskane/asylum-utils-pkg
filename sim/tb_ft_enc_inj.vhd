-------------------------------------------------------------------------------
-- Title      : tb_ft_enc_inj
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_enc_inj.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: ft_enc + Single Event Upset injector.
--              Bound to the instance enc_inst of every ft_dff by the
--              configuration tb_ft_dff_cfg. While inj_en = '1', the encoded
--              word is xored with a mask (inj_kind : INJ_BIT0 = bit 0,
--              INJ_BIT01 = bits 0 and 1, INJ_TOP = MSB of the encoded word) :
--              a write loads a faulty word in the encoded register.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-14  1.0      mrosiere Created (fault injection of tb_ft_dff)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library asylum;
use     asylum.ft_pkg.all;

use     work.tb_ft_dff_inj_pkg.all;

entity tb_ft_enc_inj is
  generic (
    FT_ALGO           : ft_algo_t := USE_NONE
  );
  port (
    data_i            : in  std_logic_vector;
    data_o            : out std_logic_vector
  );
end entity tb_ft_enc_inj;

architecture sim of tb_ft_enc_inj is
  signal data_enc     : std_logic_vector(data_o'range);
begin

  enc : entity asylum.ft_enc
    generic map (
      FT_ALGO           => FT_ALGO
    )
    port map (
      data_i            => data_i
     ,data_o            => data_enc
    );

  p_inj : process (data_enc, inj_en, inj_kind)
    variable mask : std_logic_vector(data_o'range);
  begin
    mask := (others => '0');
    if inj_en = '1' then
      case inj_kind is
        when INJ_BIT0  => mask(0)           := '1';
        when INJ_BIT01 => mask(1 downto 0)  := "11";
        when INJ_TOP   => mask(data_o'high) := '1';
      end case;
    end if;
    data_o <= data_enc xor mask;
  end process p_inj;

end architecture sim;
