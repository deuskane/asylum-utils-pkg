-------------------------------------------------------------------------------
-- Title      : ft_enc
-- Project    :
-------------------------------------------------------------------------------
-- Description: Encoder for Fault Tolerance
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2026-07-15  1.0      mrosiere Created
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library asylum;
use     asylum.ft_pkg.all;

entity ft_enc is
    generic 
    (
        FT_ALGO    : ft_algo_t := USE_NONE
    );
    port (
        data_i     : in  std_logic_vector
       ;data_o     : out std_logic_vector
    );
end entity ft_enc;

architecture rtl of ft_enc is
begin

    gen_none: if FT_ALGO = USE_NONE 
    generate
        data_o <= encode(data_i, FT_NONE);
    end generate;

    gen_parity_odd: if FT_ALGO = USE_PARITY_ODD 
    generate
        data_o <= encode(data_i, FT_PARITY_ODD);
    end generate;

    gen_parity_even: if FT_ALGO = USE_PARITY_EVEN 
    generate
        data_o <= encode(data_i, FT_PARITY_EVEN);
    end generate;

    gen_ecc: if FT_ALGO = USE_ECC 
    generate
        data_o <= encode(data_i, FT_ECC);
    end generate;

    gen_tmr: if FT_ALGO = USE_TMR 
    generate
        data_o <= encode(data_i, FT_TMR);
    end generate;
    
end architecture rtl;