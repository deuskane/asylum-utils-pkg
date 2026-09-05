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
    function count_ecc_data_bits(total_bits : natural) return natural is
        variable data_bits : natural := 0;
    begin
        -- Iterate through all bit positions
        for i in 1 to total_bits 
        loop
            -- Count positions that are not powers of 2 and not the last bit
            if (not is_pow2(i)) and (i /= total_bits) 
            then
                data_bits := data_bits + 1;
            end if;
        end loop;
        return data_bits;
    end function;

    -- Calculate the number of ECC parity bits required for a given data size
    -- Implements Hamming code calculation with optional Double Error Detection (DED)
    function size_ecc(data_bits : natural; ded : boolean := true) return natural is
        variable r        : natural := 1;
        variable required : natural := 0;
    begin
        -- Find minimum number of parity bits needed for Hamming code
        loop
            required := data_bits + r + 1;
            -- Check if 2^r can cover the required bits
            if (2 ** r) >= required 
            then
                exit;
            end if;
            r := r + 1;
        end loop;
        -- Add one more bit for DED (overall parity)
        if ded then return r + 1; else return r; end if;
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
        return data_len + size_ecc(data_len, true);
    end function;

    function encoded_size(data_len : natural; ft : ft_tmr_t) return natural is
    begin
        return data_len * 3;
    end function;

    ---------------------------------------------------------------------------
    -- INTERNAL EXTRACT FUNCTIONS 
    ---------------------------------------------------------------------------
    function extract_parity_data(protected_data : std_logic_vector) return std_logic_vector is
    begin
        return protected_data(protected_data'high - 1 downto protected_data'low);
    end function;

    function extract_parity_redundancy(protected_data : std_logic_vector) return std_logic is
    begin
        return protected_data(protected_data'high);
    end function;

    function extract_ecc_data(protected_data : std_logic_vector) return std_logic_vector is
        constant data_len : natural := count_ecc_data_bits(protected_data'length);
        variable data_out : std_logic_vector(data_len - 1 downto 0);
        variable d_idx    : integer := 0;
    begin
        for i in 1 to protected_data'length - 1 
        loop
            if (not is_pow2(i))
            then
                --report "ECC DATA "&integer'image(d_idx)&" <= "&integer'image(i);
                data_out(d_idx) := protected_data(i);
                d_idx           := d_idx + 1;
            end if;
        end loop;
        return data_out;
    end function;

    function extract_ecc_redundancy(protected_data : std_logic_vector) return std_logic_vector is
        constant data_len : natural := count_ecc_data_bits(protected_data'length);
        variable red_out  : std_logic_vector(protected_data'length-data_len - 1 downto 0);
        variable d_idx    : integer := 1;
    begin
        red_out(0) := protected_data(0);
        for i in 1 to protected_data'length - 1 
        loop
            if (is_pow2(i))
            then
                --report "ECC RED  "&integer'image(d_idx)&" <= "&integer'image(i);
                red_out(d_idx)  := protected_data(i);
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
        return data;
    end function;

    function encode(data : std_logic_vector; ft : ft_parity_odd_t) return std_logic_vector is
        variable result : std_logic_vector(data'length downto 0);
        variable p      : std_logic := '0';
    begin
        p      := not reduce_xor(data);
        result := p & data;
        return result;
    end function;

    function encode(data : std_logic_vector; ft : ft_parity_even_t) return std_logic_vector is
        variable result : std_logic_vector(data'length downto 0);
        variable p      : std_logic := '0';
    begin
        p      := reduce_xor(data);
        result := p & data;
        return result;
    end function;

    function encode(data : std_logic_vector; ft : ft_tmr_t) return std_logic_vector is
    begin
        return data & data & data;
    end function;

    function encode(data : std_logic_vector; ft : ft_ecc_t) return std_logic_vector is
        variable total_bits : natural := encoded_size(data'length, FT_ECC);
        variable result     : std_logic_vector(total_bits - 1 downto 0);
        variable d_idx      : integer;
        variable parity_pos : natural;
        variable parity_val : std_logic;
    begin

        -- Data representation :
        -- Output bit :
        --    0  1  2  3  4  5  6  7
        --    P0 P1 P2 D0 P3 D1 D2 D3
        --
        -- P0 x  X  X  X  X  X  X  X <- must be compute last
        -- P1    x     x     x     x
        -- P2       x  X        X  X
        -- P3             x  X  X  X  

        -- Initialize the output vector
        -- Set parity bit to 0
        -- Set data bit
        --report "ENC.ECC Data IN  : " & to_hstring(data);
        result := (others => '0');
        d_idx  := data'low;
        
        for i in 1 to total_bits - 1 
        loop
            if not is_pow2(i)
            then
                result(i) := data(d_idx);
                d_idx := d_idx + 1;
            end if;
        end loop;

        -- compute the parity for each parity bit
        parity_pos := 1;
        while parity_pos < total_bits 
        loop
            -- Initialize with parity even
            parity_val := '0';
            for i in parity_pos+1 to total_bits - 1 
            loop
                if (i mod (2 * parity_pos)) >= parity_pos
                then
                    --report "ENC PARITY("&integer'image(parity_pos)&") - "&integer'image(i);

                    parity_val := parity_val xor result(i);
                end if;
            end loop;
            result(parity_pos) := parity_val;
            parity_pos         := parity_pos * 2;
        end loop;

        -- Compute global parity bit
        result(0) := xor (result(total_bits-1 downto 1));

        --report "ENC.ECC Data OUT : " & to_hstring(result);
        --report "ENC.ECC Sig      : " & to_hstring(extract_ecc_redundancy(result));
        return result;
    end function;

    ---------------------------------------------------------------------------
    -- DECODE IMPLEMENTATION 
    ---------------------------------------------------------------------------
    function decode(protected_data : std_logic_vector; ft : in ft_none_t) return ft_dec_t is
        variable ret : ft_dec_t(data(protected_data'length - 1 downto 0));
    begin
        ret.status.error_detected  := '0';
        ret.status.error_corrected := '0';
        ret.data := protected_data;
        return ret;
    end function;
    
    function decode(protected_data : std_logic_vector; ft : in ft_parity_odd_t) return ft_dec_t is
        variable ret     : ft_dec_t(data(protected_data'length - 2 downto 0));
        variable parity  : std_logic := '0';
    begin
        ret.data := extract_parity_data(protected_data);
        parity   := not reduce_xor(ret.data);

        if parity /= extract_parity_redundancy(protected_data) then
            ret.status.error_detected  := '1';
            ret.status.error_corrected := '0';
        else
            ret.status.error_detected  := '0';
            ret.status.error_corrected := '0';
        end if;

        return ret;
    end function;

    function decode(protected_data : std_logic_vector; ft : in ft_parity_even_t) return ft_dec_t is
        variable ret     : ft_dec_t(data(protected_data'length - 2 downto 0));
        variable parity  : std_logic := '0';
    begin
        ret.data := extract_parity_data(protected_data);
        parity   := reduce_xor(ret.data);

        if parity /= extract_parity_redundancy(protected_data) then
            ret.status.error_detected  := '1';
            ret.status.error_corrected := '0';
        else
            ret.status.error_detected  := '0';
            ret.status.error_corrected := '0';
        end if;

        return ret;
    end function;

    function decode(protected_data : std_logic_vector; ft : in ft_tmr_t) return ft_dec_t is
        constant L      : natural := protected_data'length / 3;
        variable ret    : ft_dec_t(data(L-1 downto 0));
        variable err    : std_logic := '0';
        variable c0     : std_logic_vector(L-1 downto 0);
        variable c1     : std_logic_vector(L-1 downto 0);
        variable c2     : std_logic_vector(L-1 downto 0);
    begin
        c2 := protected_data(3*L-1 downto 2*L);
        c1 := protected_data(2*L-1 downto L);
        c0 := protected_data(L-1   downto 0);

        for i in ret.data'range loop
            ret.data(i) := (c0(i) and c1(i)) or 
                           (c1(i) and c2(i)) or 
                           (c0(i) and c2(i));
                        
            if (c0(i) /= c1(i)) or (c1(i) /= c2(i)) then
                err := '1';
            end if;
        end loop;
        
        ret.status.error_detected  := err;
        ret.status.error_corrected := err;

        return ret;
    end function;

    function decode(protected_data : std_logic_vector; ft : in ft_ecc_t) return ft_dec_t is
        constant total_bits     : natural := protected_data'length;
        constant red_bits       : natural := protected_data'length - count_ecc_data_bits(total_bits);
        variable ret            : ft_dec_t(data(count_ecc_data_bits(total_bits) - 1 downto 0));
        variable reencode       : std_logic_vector(total_bits - 1 downto 0);
        variable reencode_red   : std_logic_vector(red_bits   - 1 downto 0);
        variable red_in         : std_logic_vector(red_bits   - 1 downto 0);
        variable err_idx        : std_logic_vector(red_bits   - 1 downto 0);
        variable CST_0          : std_logic_vector(red_bits   - 1 downto 0) := (others => '0');
        variable data_corrected : std_logic_vector(total_bits - 1 downto 0);
        variable data_mask      : std_logic_vector(total_bits - 1 downto 0);

    begin
        --report "DEC.ECC Data IN  : " & to_hstring(protected_data);

        ret.data     := extract_ecc_data      (protected_data);
        red_in       := extract_ecc_redundancy(protected_data);

        --report "DEC.ECC Data     : " & to_hstring(ret.data);
        --report "DEC.ECC Sig      : " & to_hstring(red_in);

        reencode     := encode(ret.data, FT_ECC);
        reencode_red := extract_ecc_redundancy(reencode);

        --report "DEC.ECC Data2    : " & to_hstring(reencode);
        --report "DEC.ECC Sig2     : " & to_hstring(reencode_red);

        err_idx(red_bits-1 downto 1)  := red_in(red_bits-1 downto 1) xor reencode_red(red_bits-1 downto 1);
        err_idx(0)                    := red_in(0) xor xor(protected_data(total_bits - 1 downto 1));
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

            data_corrected := protected_data xor data_mask;
            ret.data       := extract_ecc_data      (data_corrected);
        else
            ret.status.error_detected  := '1';
            ret.status.error_corrected := '0';
        end if;

        --report "DEC.ECC Data OUT : " & to_hstring(ret.data);

        return ret;
    end function;

end package body ft_pkg;