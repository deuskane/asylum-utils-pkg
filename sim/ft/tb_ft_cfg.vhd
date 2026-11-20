-------------------------------------------------------------------------------
-- Title      : tb_ft_cfg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_cfg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Toplevel of the sim_ft_* targets : tb_ft where the encoder
--              (enc_inst) of the two ft_dff of gen_dff is replaced by the
--              injector tb_ft_enc_inj. No VHDL-2008 external name (not
--              supported by the GHDL gcc / llvm backends).
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-14  1.0      mrosiere Created (fault injection of tb_ft_dff)
-- 2026-11-20  1.1      mrosiere Configuration of tb_ft
-------------------------------------------------------------------------------

library asylum;
use     asylum.ft_pkg.all;

configuration tb_ft_cfg of tb_ft is
  for sim
    for gen_dff
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
end configuration tb_ft_cfg;
