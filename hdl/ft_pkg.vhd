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
-- 2026-06-26  1.0      mrosiere Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package ft_pkg is

    ---------------------------------------------------------------------------
    -- TYPE DEFINITIONS
    ---------------------------------------------------------------------------
    -- Enum for Parity Type: Even or Odd
    type parity_type_t    is (EVEN, ODD);

    -- Type for Parity: Data + 1 parity bit (the parity bit is the msb)
    subtype parity_vector is std_logic_vector;

    -- Type for ECC: Data + N Hamming bits
    subtype ecc_vector    is std_logic_vector;

    -- Type for TMR: Array of 3 vectors
    type    tmr_vector is array (0 to 2) of std_logic_vector;

    -- Record for Decoder return status
    type ft_status_t is record
        error_detected  : std_logic;
        error_corrected : std_logic;
    end record ft_status_t;

    ---------------------------------------------------------------------------
    -- UNIFIED API: ENCODE
    ---------------------------------------------------------------------------
    -- Parity Variant
    function encode(data : std_logic_vector; parity_type : std_logic := '0') return parity_vector;
    
    -- ECC Variant
    function encode(data : std_logic_vector) return ecc_vector;
    
    -- TMR Variant
    function encode(data : std_logic_vector) return tmr_vector;

    ---------------------------------------------------------------------------
    -- UNIFIED API: DECODE
    ---------------------------------------------------------------------------
    -- Parity Variant
    procedure decode(
        signal protected_data : in  parity_vector;
        signal data_out       : out std_logic_vector;
        signal status         : out ft_status_t
    );

    -- ECC Variant
    procedure decode(
        signal protected_data : in  ecc_vector;
        signal data_out       : out std_logic_vector;
        signal status         : out ft_status_t
    );

    -- TMR Variant
    procedure decode(
        signal protected_data : in  tmr_vector;
        signal data_out       : out std_logic_vector;
        signal status         : out ft_status_t
    );

end package ft_pkg;