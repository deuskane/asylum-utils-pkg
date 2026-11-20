-------------------------------------------------------------------------------
-- Title      : ft_enc_wrapper
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : ft_enc_wrapper.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Wrapper of ft_enc (lint_ghdl, lint_ghdl_synth_ft_enc_*,
--              syn_ft_enc_*) : ports constrained by the generics WIDTH (data
--              width) and FT_ALGO (ft_enc has unconstrained ports and cannot
--              be a synthesis top).
--              Every package of the hdl fileset is used (context clause) so
--              that ghdl -m analyzes all of them with -Wall (lint_ghdl).
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-20  1.0      mrosiere Created
-- 2026-10-24  1.1      mrosiere Was ft_synth_top, library asylum
-- 2026-11-20  1.2      mrosiere ft_enc only (was ft_wrapper : ft_dff, ft_enc
--                               and ft_dec), one wrapper per entity
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library asylum;
use     asylum.convert_pkg.all;
use     asylum.logic_pkg.all;
use     asylum.math_pkg.all;
use     asylum.types_pkg.all;
use     asylum.pbi_pkg.all;
use     asylum.sbi_pkg.all;
use     asylum.string_pkg.all;
use     asylum.ft_pkg.all;

entity ft_enc_wrapper is
    generic (
        WIDTH                 : positive  := 32;
        FT_ALGO               : ft_algo_t := USE_NONE
    );
    port (
        data_i                : in  std_logic_vector(WIDTH - 1 downto 0);
        data_o                : out std_logic_vector(encoded_size(WIDTH, FT_ALGO) - 1 downto 0)
    );
end entity ft_enc_wrapper;

architecture rtl of ft_enc_wrapper is
begin

    ft_enc_inst : ft_enc
        generic map (
            FT_ALGO           => FT_ALGO
        )
        port map (
            data_i            => data_i
           ,data_o            => data_o
        );

end architecture rtl;
