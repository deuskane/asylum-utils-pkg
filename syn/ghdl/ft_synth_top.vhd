-------------------------------------------------------------------------------
-- Title      : ft_synth_top
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : ft_synth_top.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Synthesis check top (lint_ghdl, lint_ghdl_synth) : ft_dff,
--              ft_enc and ft_dec with flat and constrained ports (ft_enc and
--              ft_dec have unconstrained ports and cannot be a synthesis
--              top). The three instances are independent and share the
--              generics FT_ALGO (and WIDTH : data width). SELF_REFRESH is
--              forwarded to ft_dff.
--              Every package of the hdl fileset is used (context clause) so
--              that ghdl -m analyzes all of them with -Wall.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-20  1.0      mrosiere Created
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

entity ft_synth_top is
    generic (
        WIDTH                 : positive  := 32;
        FT_ALGO               : ft_algo_t := USE_NONE;
        SELF_REFRESH          : boolean   := false
    );
    port (
        -- ft_dff
        clk_i                 : in  std_logic;
        arst_b_i              : in  std_logic;
        we_i                  : in  std_logic;
        data_i                : in  std_logic_vector(WIDTH - 1 downto 0);
        data_o                : out std_logic_vector(WIDTH - 1 downto 0);
        error_detected_o      : out std_logic;
        error_corrected_o     : out std_logic;

        -- ft_enc
        enc_data_i            : in  std_logic_vector(WIDTH - 1 downto 0);
        enc_data_o            : out std_logic_vector(encoded_size(WIDTH, FT_ALGO) - 1 downto 0);

        -- ft_dec
        dec_data_i            : in  std_logic_vector(encoded_size(WIDTH, FT_ALGO) - 1 downto 0);
        dec_data_o            : out std_logic_vector(WIDTH - 1 downto 0);
        dec_error_detected_o  : out std_logic;
        dec_error_corrected_o : out std_logic
    );
end entity ft_synth_top;

architecture rtl of ft_synth_top is
begin

    ft_dff_inst : ft_dff
        generic map (
            WIDTH             => WIDTH
           ,FT_ALGO           => FT_ALGO
           ,SELF_REFRESH      => SELF_REFRESH
        )
        port map (
            clk_i             => clk_i
           ,arst_b_i          => arst_b_i
           ,we_i              => we_i
           ,data_i            => data_i
           ,data_o            => data_o
           ,error_detected_o  => error_detected_o
           ,error_corrected_o => error_corrected_o
        );

    ft_enc_inst : ft_enc
        generic map (
            FT_ALGO           => FT_ALGO
        )
        port map (
            data_i            => enc_data_i
           ,data_o            => enc_data_o
        );

    ft_dec_inst : ft_dec
        generic map (
            FT_ALGO           => FT_ALGO
        )
        port map (
            data_i            => dec_data_i
           ,data_o            => dec_data_o
           ,error_detected_o  => dec_error_detected_o
           ,error_corrected_o => dec_error_corrected_o
        );

end architecture rtl;
