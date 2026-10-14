-------------------------------------------------------------------------------
-- Title      : tb_ft_dff_cfg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_dff_cfg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Toplevel of the ft_dff testbench : tb_ft_dff where the encoder
--              (enc_inst) of every ft_dff is replaced by the injector
--              tb_ft_enc_inj.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-14  1.0      mrosiere Created (fault injection of tb_ft_dff)
-------------------------------------------------------------------------------

library asylum;
use     asylum.ft_pkg.all;

configuration tb_ft_dff_cfg of tb_ft_dff is
  for sim
    for gen_dut
      for dut : ft_dff
        use entity asylum.ft_dff(rtl);
        for rtl
          for enc_inst : ft_enc
            use entity work.tb_ft_enc_inj;
          end for;
        end for;
      end for;
    end for;
  end for;
end configuration tb_ft_dff_cfg;
