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
-- 2026-07-09  1.2      mrosiere Merged size_ecc, removed size arg from extracts
-------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library asylum;
use     asylum.logic_pkg.all;

package body ft_pkg is

    ---------------------------------------------------------------------------
    -- UTILITY FUNCTIONS
    ---------------------------------------------------------------------------
    function is_power_of_two(n : natural) return boolean is
    begin
        if n = 0 then
            return false;
        end if;
        return (n and (n - 1)) = 0;
    end function;

    -- Helper to dynamically find the original data size from an ECC vector
    function count_ecc_data_bits(total_bits : natural) return natural is
        variable data_bits : natural := 0;
    begin
        for i in 1 to total_bits loop
            if (not is_power_of_two(i)) and (i /= total_bits) then
                data_bits := data_bits + 1;
            end if;
        end loop;
        return data_bits;
    end function;

    ---------------------------------------------------------------------------
    -- SIZE FUNCTIONS (Overhead computation)
    ---------------------------------------------------------------------------    
    -- Return overhead bits for Parity (Always 1)
    function size_parity(data_bits : natural) return natural is
    begin
        return 1;
    end function;

    -- Return overhead bits for TMR (2 additional copies)
    function size_tmr(data_bits : natural) return natural is
    begin
        return 2 * data_bits;
    end function;

    -- Return overhead bits for ECC (Calculates Hamming SEC/SECDED overhead directly)
    function size_ecc(data_bits : natural; ded : boolean := true) return natural is
        variable r        : natural := 1;
        variable required : natural := 0;
    begin
        loop
            required := data_bits + r + 1;
            if (2 ** r) >= required then
                exit;
            end if;
            r := r + 1;
        end loop;

        if ded then
            return r + 1; 
        else
            return r;     
        end if;
    end function;

    ---------------------------------------------------------------------------
    -- EXTRACT FUNCTIONS (Data & Redundancy)
    ---------------------------------------------------------------------------
    -- PARITY Extract
    function extract_data(protected_data : parity_vector) return std_logic_vector is
    begin
        -- The MSB ('high) is the parity bit, the rest is data
        return protected_data(protected_data'high - 1 downto protected_data'low);
    end function;

    function extract_redundancy(protected_data : parity_vector) return std_logic is
    begin
        return protected_data(protected_data'high);
    end function;

    -- TMR Extract
    function extract_data(protected_data : tmr_vector) return std_logic_vector is
    begin
        return protected_data(0); -- Main copy
    end function;

    -- ECC Extract Data
    function extract_data(protected_data : ecc_vector) return std_logic_vector is
        constant data_len : natural := count_ecc_data_bits(protected_data'length);
        variable data_out : std_logic_vector(data_len - 1 downto 0);
        variable d_idx    : integer := 0;
        variable pos      : natural;
    begin
        for i in 0 to protected_data'length - 1 loop
            pos := i + 1;
            if (not is_power_of_two(pos)) and (pos /= protected_data'length) then
                data_out(d_idx) := protected_data(i);
                d_idx := d_idx + 1;
            end if;
        end loop;
        return data_out;
    end function;

    
    ---------------------------------------------------------------------------
    -- ENCODE IMPLEMENTATION
    ---------------------------------------------------------------------------
    -- PARITY
    function encode 
        (data        : std_logic_vector
        ;parity_type : std_logic := '0'
        ) return parity_vector is
        variable result : std_logic_vector(data'length downto 0);
        variable p      : std_logic := '0';
    begin
        p      := reduce_xor(data);
        result := (p xor parity_type) & data;
        return result;
    end function;

    -- TMR
    function encode
        (data : std_logic_vector
        ) return tmr_vector is
        variable result : tmr_vector(0 to 2)(data'length-1 downto 0);
    begin
        result(0) := data;
        result(1) := data;
        result(2) := data;
        return result;
    end function;

    -- ECC
    function encode
        (data : std_logic_vector
        ) return ecc_vector is
        variable total_parity : natural := size_ecc(data'length, true);
        variable total_bits   : natural := data'length + total_parity;
        variable result       : std_logic_vector(total_bits - 1 downto 0) := (others => '0');
        variable d_idx        : integer := data'low;
        variable pos          : natural;
    begin
        -- Place data bits
        for i in 0 to total_bits - 1 loop
            pos := i + 1;
            if is_power_of_two(pos) and pos < total_bits then
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

        -- Compute parity bits
        pos := 1;
        while pos < total_bits loop
            variable parity_val : std_logic := '0';
            for i in 0 to total_bits - 1 loop
                if ((i + 1) and pos) /= 0 then
                    parity_val := parity_val xor result(i);
                end if;
            end loop;
            result(pos - 1) := parity_val;
            pos := pos * 2;
        end loop;

        -- Compute overall parity (SECDED)
        variable overall : std_logic := '0';
        for i in 0 to total_bits - 2 loop
            overall := overall xor result(i);
        end loop;
        result(result'high) := overall;

        return result;
    end function;

    ---------------------------------------------------------------------------
    -- DECODE IMPLEMENTATION (Procedures)
    ---------------------------------------------------------------------------
    -- PARITY
    procedure decode
        (signal protected_data : in  parity_vector
        ;signal data_out       : out std_logic_vector
        ;signal status         : out ft_status_t
        ) is
        variable p              : std_logic := '0';
        variable extracted_data : std_logic_vector(data_out'length-1 downto 0);
    begin
        extracted_data := extract_data(protected_data);
        data_out       <= extracted_data;
        
        -- Compute parity on extracted data
        p := reduce_xor(extracted_data);
        
        -- Compare with extracted redundancy
        if p /= extract_redundancy(protected_data) then
            status.error_detected  <= '1';
            status.error_corrected <= '0';
        else
            status.error_detected  <= '0';
            status.error_corrected <= '0';
        end if;
    end procedure;

    -- TMR (Majority Vote)
    procedure decode
        (signal protected_data : in  tmr_vector
        ;signal data_out       : out std_logic_vector
        ;signal status         : out ft_status_t
        ) is
        variable v_out : std_logic_vector(data_out'length-1 downto 0);
        variable err   : std_logic := '0';
    begin
        for i in v_out'range loop
            v_out(i) := (protected_data(0)(i) and protected_data(1)(i)) or 
                        (protected_data(1)(i) and protected_data(2)(i)) or 
                        (protected_data(0)(i) and protected_data(2)(i));
                        
            if (protected_data(0)(i) /= protected_data(1)(i)) or 
               (protected_data(1)(i) /= protected_data(2)(i)) then
                err := '1';
            end if;
        end loop;
        
        data_out               <= v_out;
        status.error_detected  <= '0'; 
        status.error_corrected <= err;
    end procedure;

    -- ECC
    procedure decode
        (signal protected_data : in  ecc_vector
        ;signal data_out       : out std_logic_vector
        ;signal status         : out ft_status_t
        ) is
        constant total_bits     : natural := protected_data'length;
        variable pos            : natural := 1;
        variable syndrome       : natural := 0;
        variable parity_val     : std_logic;
        variable overall_calc   : std_logic := '0';
        variable overall_stored : std_logic;
        variable temp           : std_logic_vector(total_bits - 1 downto 0);
        variable mask           : std_logic_vector(total_bits - 1 downto 0);
        variable err_idx        : integer;
    begin
        -- compute syndrome
        while pos < total_bits loop
            parity_val := '0';
            for i in 0 to total_bits - 1 loop
                if (((i + 1) and pos) /= 0) then
                    parity_val := parity_val xor protected_data(i);
                end if;
            end loop;
            if parity_val /= protected_data(pos - 1) then
                syndrome := syndrome + pos; 
            end if;
            pos := pos * 2;
        end loop;

        -- compute overall parity
        for i in 0 to total_bits - 2 loop
            overall_calc := overall_calc xor protected_data(i);
        end loop;
        overall_stored := protected_data(total_bits - 1);

        -- decide action
        if (syndrome = 0) and (overall_calc = overall_stored) then
            status.error_detected  <= '0';
            status.error_corrected <= '0';
            data_out <= extract_data(protected_data);

        elsif (syndrome = 0) and (overall_calc /= overall_stored) then
            status.error_detected  <= '1';
            status.error_corrected <= '1';
            data_out <= extract_data(protected_data);

        elsif (syndrome /= 0) and (overall_calc /= overall_stored) then
            status.error_detected  <= '1';
            status.error_corrected <= '1';
            err_idx := integer(syndrome) - 1;
            
            if err_idx >= 0 and err_idx < total_bits then
                mask := (others => '0');
                mask(err_idx) := '1';
                temp := protected_data xor mask;
                -- Extract data from the corrected temp array
                data_out <= extract_data(temp);
            else
                status.error_detected  <= '1';
                status.error_corrected <= '0';
                data_out <= extract_data(protected_data);
            end if;

        else
            status.error_detected  <= '1';
            status.error_corrected <= '0';
            data_out <= extract_data(protected_data);
        end if;

    end procedure;

end package body ft_pkg;