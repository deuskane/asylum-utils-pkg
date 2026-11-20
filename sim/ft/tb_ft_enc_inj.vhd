-------------------------------------------------------------------------------
-- Title      : tb_ft_enc_inj
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_enc_inj.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: ft_enc + Single Event Upset injector.
--              Bound to the instance enc_inst of every ft_dff of tb_ft by the
--              configuration tb_ft_cfg. While inj_en = '1', the encoded
--              word is xored with the mask of inj_kind (tb_ft_inj_pkg) :
--              a write loads a faulty word in the encoded register.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-14  1.0      mrosiere Created (fault injection of tb_ft_dff)
-- 2026-11-20  1.1      mrosiere Mask from inj_mask (tb_ft_inj_pkg)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library asylum;
use     asylum.ft_pkg.all;

use     work.tb_ft_inj_pkg.all;

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
  signal data_enc     : std_logic_vector(data_o'length-1 downto 0);
begin

  enc : entity asylum.ft_enc
    generic map (
      FT_ALGO           => FT_ALGO
    )
    port map (
      data_i            => data_i
     ,data_o            => data_enc
    );

  data_o <= data_enc xor inj_mask(inj_kind, data_o'length) when inj_en = '1' else
            data_enc;

end architecture sim;
