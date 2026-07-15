-------------------------------------------------------------------------------
-- Title      : ft_dec
-- Project    :
-------------------------------------------------------------------------------
-- Description: Decoder for Fault Tolerance
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

entity ft_dec is
    generic 
    (
        FT_ALGO    : ft_algo_t := USE_NONE
    );
    port (
        data_in         : in  std_logic_vector
       ;data_out        : out std_logic_vector
       ;error_detected  : out std_logic
       ;error_corrected : out std_logic
    );
end entity ft_dec;

architecture rtl of ft_dec is
    signal dec_result : ft_dec_t(data_out'range);
begin

    
    gen_none: if FT_ALGO = USE_NONE 
    generate
        dec_result <= decode(data_in, FT_NONE);
    end generate;

    gen_parity: if FT_ALGO = USE_PARITY 
    generate
        dec_result <= decode(data_in, FT_PARITY);
    end generate;

    gen_ecc: if FT_ALGO = USE_ECC 
    generate
        dec_result <= decode(data_in, FT_ECC);
    end generate;

    gen_tmr: if FT_ALGO = USE_TMR 
    generate
        dec_result <= decode(data_in, FT_TMR);
    end generate;
    
    data_out        <= dec_result;
    error_detected  <= dec_result.status.error_detected;
    error_corrected <= dec_result.status.error_corrected;
end architecture rtl;