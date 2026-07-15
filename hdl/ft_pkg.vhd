-------------------------------------------------------------------------------
-- Title      : ft_pkg
-- Project    :
-------------------------------------------------------------------------------
-- Description: Fault Tolerance Package
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2026-07-07  1.0      mrosiere Created
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

package ft_pkg is

    ---------------------------------------------------------------------------
    -- Fault Tolerance definitions for overloading
    ---------------------------------------------------------------------------
    type ft_none_t   is (FT_NONE  );
    type ft_parity_t is (FT_PARITY);
    type ft_ecc_t    is (FT_ECC   );
    type ft_tmr_t    is (FT_TMR   );

    type ft_algo_t   is (USE_NONE
                        ,USE_PARITY
                        ,USE_ECC
                        ,USE_TMR
                        );
    ---------------------------------------------------------------------------
    -- Type for returning status of the decoding operation
    ---------------------------------------------------------------------------

    type ft_status_t is record
        error_detected  : std_logic;
        error_corrected : std_logic;
    end record ft_status_t;

    type ft_dec_t is record
        status  : ft_status_t;
        data    : std_logic_vector;
    end record ft_dec_t;

    ---------------------------------------------------------------------------
    -- Size Functions
    ---------------------------------------------------------------------------
    function encoded_size(data_len : natural; ft : ft_none_t)   return natural;
    function encoded_size(data_len : natural; ft : ft_parity_t) return natural;
    function encoded_size(data_len : natural; ft : ft_ecc_t)    return natural;
    function encoded_size(data_len : natural; ft : ft_tmr_t)    return natural;

    ---------------------------------------------------------------------------
    -- Encode Functions
    ---------------------------------------------------------------------------
    function encode(data : std_logic_vector; ft : ft_none_t) return std_logic_vector;
    function encode(data : std_logic_vector; ft : ft_parity_t; parity_type : std_logic := '0') return std_logic_vector;
    function encode(data : std_logic_vector; ft : ft_ecc_t) return std_logic_vector;
    function encode(data : std_logic_vector; ft : ft_tmr_t) return std_logic_vector;

    ---------------------------------------------------------------------------
    -- Decode Functions
    -- Return : error_corrected & error_detected & decoded_data
    ---------------------------------------------------------------------------
    function decode(protected_data : std_logic_vector; ft : ft_none_t)   return ft_dec_t;
    function decode(protected_data : std_logic_vector; ft : ft_parity_t) return ft_dec_t;
    function decode(protected_data : std_logic_vector; ft : ft_ecc_t)    return ft_dec_t;
    function decode(protected_data : std_logic_vector; ft : ft_tmr_t)    return ft_dec_t;

end package ft_pkg;