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
use     ieee.numeric_std.all;
library asylum;
use     asylum.logic_pkg.all;
use     asylum.math_pkg.all;

package body ft_pkg is

    ---------------------------------------------------------------------------
    -- UTILITY FUNCTIONS
    ---------------------------------------------------------------------------
    -- Count the number of data bits in an ECC encoded word
    -- Excludes parity bit positions (powers of 2) and the overall parity bit
    function size_ecc_data(total_bits : natural; ded : boolean := true) return natural is
        variable ded_bit : natural := 0;

    begin
        if total_bits <= 1 
        then
            return 0;
        end if;

        if ded 
        then
            ded_bit := 1;
        end if;

        return total_bits - clog2(total_bits) - ded_bit;

    end function;

    -- Calculate the number of ECC parity bits required for a given data size
    -- Implements Hamming code calculation with optional Double Error Detection (DED)
    function size_ecc_parity(data_bits : natural; ded : boolean := true) return natural is
        variable r       : natural;
        variable ded_bit : natural := 0;
    begin
        if data_bits = 0
        then
            return 0;
        end if;

        if ded 
        then
            ded_bit := 1;
        end if;

        -- First estimation
        r := clog2(data_bits + 1);

        -- Adjustment if condition is not reach
        if (2**r) < (data_bits + r + 1)
        then
            r := r + 1;
        end if;

        return r + ded_bit;
    end function;

    ---------------------------------------------------------------------------
    -- ENCODED SIZE IMPLEMENTATION
    ---------------------------------------------------------------------------
    function encoded_size(data_len : natural; ft : ft_none_t) return natural is
    begin
        return data_len;
    end function;

    function encoded_size(data_len : natural; ft : ft_parity_odd_t) return natural is
    begin
        return data_len + 1;
    end function;

    function encoded_size(data_len : natural; ft : ft_parity_even_t) return natural is
    begin
        return data_len + 1;
    end function;

    function encoded_size(data_len : natural; ft : ft_ecc_t) return natural is
    begin
        return data_len + size_ecc_parity(data_len, true);
    end function;

    function encoded_size(data_len : natural; ft : ft_tmr_t) return natural is
    begin
        return data_len * 3;
    end function;

    ---------------------------------------------------------------------------
    -- DECODED SIZE IMPLEMENTATION
    ---------------------------------------------------------------------------
    function decoded_size(data_len : natural; ft : ft_none_t) return natural is
    begin
        return data_len;
    end function;

    function decoded_size(data_len : natural; ft : ft_parity_odd_t) return natural is
    begin
        return data_len - 1;
    end function;

    function decoded_size(data_len : natural; ft : ft_parity_even_t) return natural is
    begin
        return data_len - 1;
    end function;

    function decoded_size(data_len : natural; ft : ft_ecc_t) return natural is
    begin
        return size_ecc_data(data_len);
    end function;

    function decoded_size(data_len : natural; ft : ft_tmr_t) return natural is
    begin
        return data_len / 3;
    end function;

    ---------------------------------------------------------------------------
    -- INTERNAL EXTRACT FUNCTIONS 
    ---------------------------------------------------------------------------
    function extract_parity_data(data_enc : std_logic_vector) return std_logic_vector is
    begin
        return data_enc(data_enc'high - 1 downto data_enc'low);
    end function;

    function extract_parity_redundancy(data_enc : std_logic_vector) return std_logic is
    begin
        return data_enc(data_enc'high);
    end function;

    function extract_ecc_data(data_enc : std_logic_vector) return std_logic_vector is
        constant data_len : natural := size_ecc_data(data_enc'length);
        variable data_out : std_logic_vector(data_len - 1 downto 0);
        variable d_idx    : integer := 0;
    begin
        for i in 1 to data_enc'length - 1 
        loop
            if (not is_pow2(i))
            then
                --report "ECC DATA "&integer'image(d_idx)&" <= "&integer'image(i);
                data_out(d_idx) := data_enc(i);
                d_idx           := d_idx + 1;
            end if;
        end loop;
        return data_out;
    end function;

    function extract_ecc_redundancy(data_enc : std_logic_vector) return std_logic_vector is
        constant data_len : natural := size_ecc_data(data_enc'length);
        variable red_out  : std_logic_vector(data_enc'length-data_len - 1 downto 0);
        variable d_idx    : integer := 1;
    begin
        red_out(0) := data_enc(0);
        for i in 1 to data_enc'length - 1 
        loop
            if (is_pow2(i))
            then
                --report "ECC RED  "&integer'image(d_idx)&" <= "&integer'image(i);
                red_out(d_idx)  := data_enc(i);
                d_idx           := d_idx + 1;
            end if;
        end loop;
        return red_out;
    end function;

    ---------------------------------------------------------------------------
    -- ENCODE IMPLEMENTATION
    ---------------------------------------------------------------------------
    function encode(data : std_logic_vector; ft : ft_none_t) return std_logic_vector is
    begin
        -- No redundancy
        return data;
    end function;

    function encode(data : std_logic_vector; ft : ft_parity_odd_t) return std_logic_vector is
        variable data_enc : std_logic_vector(data'length downto 0);
        variable p        : std_logic := '0';
    begin
        -- Compute parity bit
        p        := not (xor(data));
        data_enc := p & data;
        return data_enc;
    end function;

    function encode(data : std_logic_vector; ft : ft_parity_even_t) return std_logic_vector is
        variable data_enc : std_logic_vector(data'length downto 0);
        variable p      : std_logic := '0';
    begin
        -- Compute parity bit
        p        := xor(data);
        data_enc := p & data;
        return data_enc;
    end function;

    function encode(data : std_logic_vector; ft : ft_tmr_t) return std_logic_vector is
    begin
        -- TMR - encode meaning triplication of data
        return data & data & data;
    end function;

    function encode(data : std_logic_vector; ft : ft_ecc_t) return std_logic_vector is
        variable data_enc_size : natural := encoded_size(data'length, FT_ECC);
        variable data_enc      : std_logic_vector(data_enc_size - 1 downto 0);
        variable d_idx         : integer;
        variable parity_pos    : natural;
        variable parity_val    : std_logic;
    begin

        -- Data representation :
        -- Output bit :
        --    0  1  2  3  4  5  6  7
        --    P0 P1 P2 D0 P3 D1 D2 D3
        --
        -- P0 o  X  X  X  X  X  X  X <- must be compute last
        -- P1    o     X     X     X
        -- P2       o  X        X  X
        -- P3             o  X  X  X  

        -- Initialize the output vector
        -- Set parity bit to 0
        -- Set data bit
        --report "ENC.ECC Data IN  : " & to_hstring(data);
        data_enc := (others => '0');
        d_idx    := data'low;
        
        for i in 1 to data_enc_size - 1 
        loop
            if not is_pow2(i)
            then
                data_enc(i) := data(d_idx);
                d_idx       := d_idx + 1;
            end if;
        end loop;

        -- compute the parity for each parity bit
        parity_pos := 1;
        while parity_pos < data_enc_size 
        loop
            -- Initialize with parity even
            parity_val := '0';

            for i in parity_pos+1 to data_enc_size - 1 
            loop
                if (i mod (2 * parity_pos)) >= parity_pos
                then
                    --report "ENC PARITY("&integer'image(parity_pos)&") - "&integer'image(i);

                    -- Parity accumulation
                    parity_val := parity_val xor data_enc(i);
                end if;
            end loop;

            data_enc(parity_pos) := parity_val;
            parity_pos           := parity_pos * 2;
        end loop;

        -- Compute global parity bit
        data_enc(0) := xor (data_enc(data_enc_size-1 downto 1));

        --report "ENC.ECC Data OUT : " & to_hstring(data_enc);
        --report "ENC.ECC Sig      : " & to_hstring(extract_ecc_redundancy(data_enc));
        return data_enc;
    end function;

    ---------------------------------------------------------------------------
    -- DECODE Function IMPLEMENTATION 
    ---------------------------------------------------------------------------
    function decode(data_enc : std_logic_vector; ft : ft_none_t) return ft_dec_t is
        variable ret : ft_dec_t(data(data_enc'length - 1 downto 0));
    begin
        ret.status.error_detected  := '0';
        ret.status.error_corrected := '0';
        ret.data                   := data_enc;
        return ret;
    end function;
    
    function decode(data_enc : std_logic_vector; ft : ft_parity_odd_t) return ft_dec_t is
        variable ret     : ft_dec_t(data(data_enc'length - 2 downto 0));
        variable parity  : std_logic := '0';
    begin
        ret.data := extract_parity_data(data_enc);
        parity   := not (xor(ret.data));

        if parity /= extract_parity_redundancy(data_enc)
        then
            ret.status.error_detected  := '1';
            ret.status.error_corrected := '0';
        else
            ret.status.error_detected  := '0';
            ret.status.error_corrected := '0';
        end if;

        return ret;
    end function;

    function decode(data_enc : std_logic_vector; ft : ft_parity_even_t) return ft_dec_t is
        variable ret     : ft_dec_t(data(data_enc'length - 2 downto 0));
        variable parity  : std_logic := '0';
    begin
        ret.data := extract_parity_data(data_enc);
        parity   := xor(ret.data);

        if parity /= extract_parity_redundancy(data_enc) then
            ret.status.error_detected  := '1';
            ret.status.error_corrected := '0';
        else
            ret.status.error_detected  := '0';
            ret.status.error_corrected := '0';
        end if;

        return ret;
    end function;

    function decode(data_enc : std_logic_vector; ft : ft_tmr_t) return ft_dec_t is
        constant data_dec_size : natural := decoded_size(data_enc'length, ft);
        variable ret           : ft_dec_t(data(data_dec_size-1 downto 0));
        variable err           : std_logic := '0';
        variable c0            : std_logic_vector(data_dec_size-1 downto 0);
        variable c1            : std_logic_vector(data_dec_size-1 downto 0);
        variable c2            : std_logic_vector(data_dec_size-1 downto 0);
    begin
        c2 := data_enc(3*data_dec_size-1 downto 2*data_dec_size);
        c1 := data_enc(2*data_dec_size-1 downto   data_dec_size);
        c0 := data_enc(  data_dec_size-1 downto 0);

        for i in ret.data'range loop
            ret.data(i) := (c0(i) and c1(i)) or 
                           (c1(i) and c2(i)) or 
                           (c2(i) and c0(i));
                        
            if (c0(i) /= c1(i)) or 
               (c1(i) /= c2(i)) then
                err := '1';
            end if;
        end loop;
        
        ret.status.error_detected  := err;
        ret.status.error_corrected := err;

        return ret;
    end function;

    function decode(data_enc : std_logic_vector; ft : ft_ecc_t) return ft_dec_t is
        constant data_enc_size  : natural := data_enc'length;
        constant red_bits       : natural := data_enc'length - size_ecc_data(data_enc_size);
        variable ret            : ft_dec_t(data(size_ecc_data(data_enc_size) - 1 downto 0));
        variable reencode       : std_logic_vector(data_enc_size - 1 downto 0);
        variable reencode_red   : std_logic_vector(red_bits   - 1 downto 0);
        variable red_in         : std_logic_vector(red_bits   - 1 downto 0);
        variable err_idx        : std_logic_vector(red_bits   - 1 downto 0);
        variable CST_0          : std_logic_vector(red_bits   - 1 downto 0) := (others => '0');
        variable data_corrected : std_logic_vector(data_enc_size - 1 downto 0);
        variable data_mask      : std_logic_vector(data_enc_size - 1 downto 0);

    begin
        --report "DEC.ECC Data IN  : " & to_hstring(data_enc);

        ret.data     := extract_ecc_data      (data_enc);
        red_in       := extract_ecc_redundancy(data_enc);

        --report "DEC.ECC Data     : " & to_hstring(ret.data);
        --report "DEC.ECC Sig      : " & to_hstring(red_in);

        reencode     := encode(ret.data, FT_ECC);
        reencode_red := extract_ecc_redundancy(reencode);

        --report "DEC.ECC Data2    : " & to_hstring(reencode);
        --report "DEC.ECC Sig2     : " & to_hstring(reencode_red);

        err_idx(red_bits-1 downto 1)  := red_in(red_bits-1 downto 1) xor reencode_red(red_bits-1 downto 1);
        err_idx(0)                    := red_in(0) xor xor(data_enc(data_enc_size - 1 downto 1));
        --report "DEC.ECC IDX      : " & to_hstring(err_idx(red_bits-1 downto 1)) & " - " & to_hstring(err_idx(0 downto 0));

        if err_idx = CST_0
        then
            ret.status.error_detected  := '0';
            ret.status.error_corrected := '0';

        elsif err_idx(0) = '1'
        then
            ret.status.error_detected  := '1';
            ret.status.error_corrected := '1';

            -- 
            data_mask := (others => '0');
            data_mask(to_integer(unsigned(err_idx(red_bits-1 downto 1)))) := '1';

            --report "DEC.ECC MSK      : " & to_hstring(data_mask);

            data_corrected := data_enc xor data_mask;
            ret.data       := extract_ecc_data      (data_corrected);
        else
            ret.status.error_detected  := '1';
            ret.status.error_corrected := '0';
        end if;

        --report "DEC.ECC Data OUT : " & to_hstring(ret.data);

        return ret;
    end function;

    ---------------------------------------------------------------------------
    -- DECODE Procedure IMPLEMENTATION 
    ---------------------------------------------------------------------------
    procedure decode(data_enc : in std_logic_vector; ft : in ft_none_t; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic) is
        variable ret : ft_dec_t(data(data_enc'length - 1 downto 0));
    begin
        ret := decode(data_enc, ft);
        data_dec        := ret.data;
        error_detected  := ret.status.error_detected;
        error_corrected := ret.status.error_corrected;
    end procedure decode;

    procedure decode(data_enc : in std_logic_vector; ft : in ft_parity_odd_t; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic) is
        variable ret : ft_dec_t(data(data_enc'length - 2 downto 0));
    begin
        ret := decode(data_enc, ft);
        data_dec        := ret.data;
        error_detected  := ret.status.error_detected;
        error_corrected := ret.status.error_corrected;
    end procedure decode;

    procedure decode(data_enc : in std_logic_vector; ft : in ft_parity_even_t; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic) is
        variable ret : ft_dec_t(data(data_enc'length - 2 downto 0));
    begin
        ret := decode(data_enc, ft);
        data_dec        := ret.data;
        error_detected  := ret.status.error_detected;
        error_corrected := ret.status.error_corrected;
    end procedure decode;

    procedure decode(data_enc : in std_logic_vector; ft : in ft_ecc_t; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic) is
        variable ret : ft_dec_t(data(size_ecc_data(data_enc'length) - 1 downto 0));
    begin
        ret := decode(data_enc, ft);
        data_dec        := ret.data;
        error_detected  := ret.status.error_detected;
        error_corrected := ret.status.error_corrected;
    end procedure decode;

    procedure decode(data_enc : in std_logic_vector; ft : in ft_tmr_t; data_dec : out std_logic_vector; error_detected : out std_logic; error_corrected : out std_logic) is
        constant L    : natural := data_enc'length / 3;
        variable ret  : ft_dec_t(data(L - 1 downto 0));
    begin
        ret := decode(data_enc, ft);
        data_dec        := ret.data;
        error_detected  := ret.status.error_detected;
        error_corrected := ret.status.error_corrected;
    end procedure decode;

end package body ft_pkg;