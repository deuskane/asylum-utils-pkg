-------------------------------------------------------------------------------
-- Title      : ft_dec_wrapper
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : ft_dec_wrapper.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Wrapper of ft_dec (lint_ghdl_synth_ft_dec_*, syn_ft_dec_*) :
--              ports constrained by the generics WIDTH (data width) and
--              FT_ALGO (ft_dec has unconstrained ports and cannot be a
--              synthesis top).
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (ft_dec part of ft_wrapper)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library asylum;
use     asylum.ft_pkg.all;

entity ft_dec_wrapper is
    generic (
        WIDTH                 : positive  := 32;
        FT_ALGO               : ft_algo_t := USE_NONE
    );
    port (
        data_i                : in  std_logic_vector(encoded_size(WIDTH, FT_ALGO) - 1 downto 0);
        data_o                : out std_logic_vector(WIDTH - 1 downto 0);
        error_detected_o      : out std_logic;
        error_corrected_o     : out std_logic
    );
end entity ft_dec_wrapper;

architecture rtl of ft_dec_wrapper is
begin

    ft_dec_inst : ft_dec
        generic map (
            FT_ALGO           => FT_ALGO
        )
        port map (
            data_i            => data_i
           ,data_o            => data_o
           ,error_detected_o  => error_detected_o
           ,error_corrected_o => error_corrected_o
        );

end architecture rtl;
