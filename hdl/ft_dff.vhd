-------------------------------------------------------------------------------
-- Title      : ft_dff
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- Description: Generic FT wrapper with ft_enc -> register -> ft_dec.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2026-09-10  1.0      mrosiere Created
-- 2026-10-05  1.1      mrosiere Reset value is the encoded zero word
--                               (valid code word for every algorithm)
--                               SELF_REFRESH re-encodes the corrected data
--                               (width mismatch for all algos except NONE)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library asylum;
use asylum.ft_pkg.all;

entity ft_dff is
    generic (
        WIDTH             : natural   := 32;
        FT_ALGO           : ft_algo_t := USE_NONE;
        SELF_REFRESH      : boolean   := false
    );
    port (
        clk_i             : in  std_logic;
        arst_b_i          : in  std_logic;
        we_i              : in  std_logic;

        data_i            : in  std_logic_vector(WIDTH - 1 downto 0);
        data_o            : out std_logic_vector(WIDTH - 1 downto 0);

        error_detected_o  : out std_logic;
        error_corrected_o : out std_logic
    );
end entity ft_dff;

architecture rtl of ft_dff is
    constant WIDTH_ENC       : natural := encoded_size(WIDTH,FT_ALGO);
    -- Reset value : encoded zero word, a valid code word for every algorithm
    -- (all zeros is not a valid code word for PARITY_ODD)
    constant DATA_ENC_RESET  : std_logic_vector(WIDTH_ENC-1 downto 0) := encode(std_logic_vector'(WIDTH-1 downto 0 => '0'),FT_ALGO);
    signal   data_enc        : std_logic_vector(WIDTH_ENC-1 downto 0);
    signal   data_dec        : std_logic_vector(WIDTH    -1 downto 0);
    signal   data_enc_r      : std_logic_vector(WIDTH_ENC-1 downto 0);
    signal   data_enc_r_next : std_logic_vector(WIDTH_ENC-1 downto 0);
    signal   error_detected  : std_logic;
    signal   error_corrected : std_logic;
    -- Prevent synthesis from simplifying/optimizing these signals away
    attribute syn_preserve   : boolean;
    attribute syn_preserve of data_enc_r      : signal is true;
begin

    enc_inst : ft_enc
        generic map (FT_ALGO => FT_ALGO)
        port map (
            data_i            => data_i
           ,data_o            => data_enc
        );

    -- Self refresh : when the decoder corrected an error, the corrected data
    -- is re-encoded and written back (scrubbing). Uncorrectable errors
    -- (parity, ECC double error) are kept so that error_detected_o stays set
    -- until the next write.
    gen_self_refresh   : if SELF_REFRESH = true
    generate
        signal data_dec_enc : std_logic_vector(WIDTH_ENC-1 downto 0);
    begin
        data_dec_enc    <= encode(data_dec,FT_ALGO);
        data_enc_r_next <= data_enc     when we_i            = '1' else
                           data_dec_enc when error_corrected = '1' else
                           data_enc_r;
    end generate;

    gen_self_refresh_b : if SELF_REFRESH = false
    generate
        data_enc_r_next <= data_enc when we_i = '1' else data_enc_r;
    end generate;

    process (clk_i, arst_b_i)
    begin
        if arst_b_i = '0'
        then
            data_enc_r <= DATA_ENC_RESET;
        elsif rising_edge(clk_i) 
        then
            data_enc_r <= data_enc_r_next;
        end if;
    end process;

    dec_inst : ft_dec
        generic map (FT_ALGO => FT_ALGO)
        port map (
            data_i            => data_enc_r
           ,data_o            => data_dec
           ,error_detected_o  => error_detected
           ,error_corrected_o => error_corrected
        );

    data_o            <= data_dec;
    error_detected_o  <= error_detected;
    error_corrected_o <= error_corrected;

end architecture rtl;
