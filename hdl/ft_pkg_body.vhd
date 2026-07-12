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

    function encoded_size(data_len : natural; ft : ft_parity_t) return natural is
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
        variable pos      : natural;
    begin
        for i in 0 to protected_data'length - 1 loop
            pos := i + 1;
            if (not is_pow2(pos)) and (pos /= protected_data'length) then
                data_out(d_idx) := protected_data(i);
                d_idx := d_idx + 1;
            end if;
        end loop;
        return data_out;
    end function;

    ---------------------------------------------------------------------------
    -- ENCODE IMPLEMENTATION
    ---------------------------------------------------------------------------
    function encode(data : std_logic_vector; ft : ft_none_t) return std_logic_vector is
    begin
        return data;
    end function;

    function encode(data : std_logic_vector; ft : ft_parity_t; parity_type : std_logic := '0') return std_logic_vector is
        variable result : std_logic_vector(data'length downto 0);
        variable p      : std_logic := '0';
    begin
        p      := reduce_xor(data);
        result := (p xor parity_type) & data;
        return result;
    end function;

    function encode(data : std_logic_vector; ft : ft_tmr_t) return std_logic_vector is
    begin
        return data & data & data;
    end function;

    function encode(data : std_logic_vector; ft : ft_ecc_t) return std_logic_vector is
        variable total_bits : natural := encoded_size(data'length, FT_ECC);
        variable result     : std_logic_vector(total_bits - 1 downto 0) := (others => '0');
        variable d_idx      : integer := data'low;
        variable pos        : natural;
        variable parity_val : std_logic;
        variable overall    : std_logic;
    begin
        for i in 0 to total_bits - 1 loop
            pos := i + 1;
            if is_pow2(pos) and pos < total_bits then
                result(i) := '0';
            elsif i = result'high then
                result(i) := '0';
            else
                result(i) := data(d_idx);
                if d_idx < data'high then
                    d_idx := d_idx + 1;
                end if;
            end if;
        end loop;

        pos := 1;
        while pos < total_bits loop
            parity_val := '0';
            for i in 0 to total_bits - 1 loop
                if ((i + 1) mod (2 * pos)) >= pos then
                    parity_val := parity_val xor result(i);
                end if;
            end loop;
            result(pos - 1) := parity_val;
            pos := pos * 2;
        end loop;

        overall  := '0';
        for i in 0 to total_bits - 2 loop
            overall := overall xor result(i);
        end loop;
        result(result'high) := overall;

        return result;
    end function;

    ---------------------------------------------------------------------------
    -- DECODE IMPLEMENTATION 
    ---------------------------------------------------------------------------
    function decode(protected_data : std_logic_vector; ft : in ft_none_t) return std_logic_vector is
        variable status : ft_status_t;
    begin
        status.error_detected  := '0';
        status.error_corrected := '0';
        return status.error_corrected & status.error_detected & protected_data;
    end function;
    
    function decode(protected_data : std_logic_vector; ft : in ft_parity_t) return std_logic_vector is
        variable status         : ft_status_t;
        variable p              : std_logic := '0';
        variable extracted_data : std_logic_vector(protected_data'length - 2 downto 0);
    begin
        extracted_data := extract_parity_data(protected_data);
        p := reduce_xor(extracted_data);
        
        if p /= extract_parity_redundancy(protected_data) then
            status.error_detected  := '1';
            status.error_corrected := '0';
        else
            status.error_detected  := '0';
            status.error_corrected := '0';
        end if;

        return status.error_corrected & status.error_detected & extracted_data;
    end function;

    function decode(protected_data : std_logic_vector; ft : in ft_tmr_t) return std_logic_vector is
        variable status : ft_status_t;
        constant L      : natural := protected_data'length / 3;
        variable v_out  : std_logic_vector(L-1 downto 0);
        variable err    : std_logic := '0';
        variable c0     : std_logic_vector(L-1 downto 0);
        variable c1     : std_logic_vector(L-1 downto 0);
        variable c2     : std_logic_vector(L-1 downto 0);
    begin
        c2 := protected_data(3*L-1 downto 2*L);
        c1 := protected_data(2*L-1 downto L);
        c0 := protected_data(L-1   downto 0);

        for i in v_out'range loop
            v_out(i) := (c0(i) and c1(i)) or 
                        (c1(i) and c2(i)) or 
                        (c0(i) and c2(i));
                        
            if (c0(i) /= c1(i)) or (c1(i) /= c2(i)) then
                err := '1';
            end if;
        end loop;
        
        status.error_detected  := err;
        status.error_corrected := err;

        return status.error_corrected & status.error_detected & v_out;
    end function;

    function decode(protected_data : std_logic_vector; ft : in ft_ecc_t) return std_logic_vector is
        variable status         : ft_status_t;
        constant total_bits     : natural := protected_data'length;
        variable pos            : natural := 1;
        variable syndrome       : natural := 0;
        variable parity_val     : std_logic;
        variable overall_calc   : std_logic := '0';
        variable overall_stored : std_logic;
        variable temp           : std_logic_vector(total_bits - 1 downto 0);
        variable mask           : std_logic_vector(total_bits - 1 downto 0);
        variable err_idx        : integer;
        -- Declaration properly sized via custom helper
        variable data_out       : std_logic_vector(count_ecc_data_bits(total_bits) - 1 downto 0);
    begin
        while pos < total_bits loop
            parity_val := '0';
            for i in 0 to total_bits - 1 loop
                if (((i + 1) / pos) mod 2) /= 0 then
                    parity_val := parity_val xor protected_data(i);
                end if;
            end loop;
            if parity_val /= protected_data(pos - 1) then
                syndrome := syndrome + pos; 
            end if;
            pos := pos * 2;
        end loop;

        overall_calc := '0';
        for i in 0 to total_bits - 2 loop
            overall_calc := overall_calc xor protected_data(i);
        end loop;
        overall_stored := protected_data(total_bits - 1);

        if (syndrome = 0) and (overall_calc = overall_stored) then
            status.error_detected  := '0';
            status.error_corrected := '0';
            data_out := extract_ecc_data(protected_data);

        elsif (syndrome = 0) and (overall_calc /= overall_stored) then
            status.error_detected  := '1';
            status.error_corrected := '1';
            data_out := extract_ecc_data(protected_data);

        elsif (syndrome /= 0) and (overall_calc /= overall_stored) then
            status.error_detected  := '1';
            status.error_corrected := '1';
            err_idx := integer(syndrome) - 1;
            
            if err_idx >= 0 and err_idx < total_bits then
                mask := (others => '0');
                mask(err_idx) := '1';
                temp := protected_data xor mask;
                data_out := extract_ecc_data(temp);
            else
                status.error_detected  := '1';
                status.error_corrected := '0';
                data_out := extract_ecc_data(protected_data);
            end if;

        else
            status.error_detected  := '1';
            status.error_corrected := '0';
            data_out := extract_ecc_data(protected_data);
        end if;

        return status.error_corrected & status.error_detected & data_out;
    end function;

end package body ft_pkg;