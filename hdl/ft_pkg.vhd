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
-- 2026-09-08  1.1      mrosiere Add decoded_size function
--                               Add decode procedure
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;

package ft_pkg is

    ---------------------------------------------------------------------------
    -- Fault Tolerance definitions for overloading
    ---------------------------------------------------------------------------
    type ft_none_t        is (FT_NONE       );
    type ft_parity_odd_t  is (FT_PARITY_ODD );
    type ft_parity_even_t is (FT_PARITY_EVEN);
    type ft_ecc_t         is (FT_ECC        );
    type ft_tmr_t         is (FT_TMR        );

    type ft_algo_t        is (USE_NONE
                             ,USE_PARITY_ODD
                             ,USE_PARITY_EVEN
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

    type ft_dec_t    is record
        status          : ft_status_t;
        data            : std_logic_vector;
    end record ft_dec_t;

    ---------------------------------------------------------------------------
    -- Size Functions
    ---------------------------------------------------------------------------
    function encoded_size(data_len : natural; ft : ft_algo_t       ) return natural;
    function decoded_size(data_len : natural; ft : ft_algo_t       ) return natural;

    function encoded_size(data_len : natural; ft : ft_none_t       ) return natural;
    function encoded_size(data_len : natural; ft : ft_parity_odd_t ) return natural;
    function encoded_size(data_len : natural; ft : ft_parity_even_t) return natural;
    function encoded_size(data_len : natural; ft : ft_ecc_t        ) return natural;
    function encoded_size(data_len : natural; ft : ft_tmr_t        ) return natural;

    function decoded_size(data_len : natural; ft : ft_none_t       ) return natural;
    function decoded_size(data_len : natural; ft : ft_parity_odd_t ) return natural;
    function decoded_size(data_len : natural; ft : ft_parity_even_t) return natural;
    function decoded_size(data_len : natural; ft : ft_ecc_t        ) return natural;
    function decoded_size(data_len : natural; ft : ft_tmr_t        ) return natural;

    ---------------------------------------------------------------------------
    -- Encode Functions
    ---------------------------------------------------------------------------
    function encode(data : std_logic_vector; ft : ft_none_t       ) return std_logic_vector;
    function encode(data : std_logic_vector; ft : ft_parity_odd_t ) return std_logic_vector;
    function encode(data : std_logic_vector; ft : ft_parity_even_t) return std_logic_vector;
    function encode(data : std_logic_vector; ft : ft_ecc_t        ) return std_logic_vector;
    function encode(data : std_logic_vector; ft : ft_tmr_t        ) return std_logic_vector;

    ---------------------------------------------------------------------------
    -- Decode Functions
    -- Return : error_corrected & error_detected & decoded_data
    ---------------------------------------------------------------------------
    function decode(data_enc : std_logic_vector; ft : ft_none_t       ) return ft_dec_t;
    function decode(data_enc : std_logic_vector; ft : ft_parity_odd_t ) return ft_dec_t;
    function decode(data_enc : std_logic_vector; ft : ft_parity_even_t) return ft_dec_t;
    function decode(data_enc : std_logic_vector; ft : ft_ecc_t        ) return ft_dec_t;
    function decode(data_enc : std_logic_vector; ft : ft_tmr_t        ) return ft_dec_t;

    procedure decode(data_enc : in std_logic_vector; ft : in ft_none_t       ; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic);
    procedure decode(data_enc : in std_logic_vector; ft : in ft_parity_odd_t ; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic);
    procedure decode(data_enc : in std_logic_vector; ft : in ft_parity_even_t; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic);
    procedure decode(data_enc : in std_logic_vector; ft : in ft_ecc_t        ; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic);
    procedure decode(data_enc : in std_logic_vector; ft : in ft_tmr_t        ; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic);

    ---------------------------------------------------------------------------
    -- Component Declarations
    ---------------------------------------------------------------------------
    -- [COMPONENT_INSERT][BEGIN]
component ft_dec is
    generic 
    (
        FT_ALGO           : ft_algo_t := USE_NONE
    );
    port (
        data_i            : in  std_logic_vector
       ;data_o            : out std_logic_vector
       ;error_detected_o  : out std_logic
       ;error_corrected_o : out std_logic
    );
end component ft_dec;

component ft_dff is
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
end component ft_dff;

component ft_enc is
    generic 
    (
        FT_ALGO    : ft_algo_t := USE_NONE
    );
    port (
        data_i     : in  std_logic_vector
       ;data_o     : out std_logic_vector
    );
end component ft_enc;

-- [COMPONENT_INSERT][END]
end package ft_pkg;