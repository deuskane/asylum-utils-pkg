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
package body ft_pkg is

    ---------------------------------------------------------------------------
    -- ENCODE IMPLEMENTATION
    ---------------------------------------------------------------------------
    -- PARITY : Adds a bit at the end
    function encode 
        (data        : std_logic_vector
        ;parity_type : std_logic := '0'
        ) return parity_vector is

        variable result : std_logic_vector(data'length downto 0);
        variable p      : std_logic := '0';

    begin
        for i in data'range loop
            p := p xor data(i);
        end loop;
        result := (p xor parity_type) & data;
        return result;
    end function;

    -- TMR : Pure triplication
    function encode(data : std_logic_vector) return tmr_vector is
        variable result : tmr_vector(0 to 2)(data'length-1 downto 0);
    begin
        result(0) := data;
        result(1) := data;
        result(2) := data;
        return result;
    end function;

    -- ECC : Hamming code (Conceptual, size depends on the matrix)
    function encode(data : std_logic_vector) return ecc_vector is
        -- Replace with Hamming parity bit calculation
        variable result : std_logic_vector(data'length + 4 downto 0) := (others => '0'); 
    begin
        return result;
    end function;

    ---------------------------------------------------------------------------
    -- DECODE IMPLEMENTATION (Procedures to manipulate signals)
    ---------------------------------------------------------------------------
    -- PARITY
    procedure decode(
        signal protected_data : in  parity_vector;
        signal data_out       : out std_logic_vector;
        signal status         : out ft_status_t
    ) is
        variable p : std_logic := '0';
    begin
        data_out <= protected_data(data_out'length-1 downto 0);
        for i in 0 to data_out'length-1 loop
            p := p xor protected_data(i);
        end loop;
        
        if p /= protected_data(protected_data'high) then
            status.error_detected  <= '1';
            status.error_corrected <= '0';
        else
            status.status.error_detected  <= '0';
            status.status.error_corrected <= '0';
        end if;
    end procedure;

    -- TMR (Majority Vote)
    procedure decode(
        signal protected_data : in  tmr_vector;
        signal data_out       : out std_logic_vector;
        signal status         : out ft_status_t
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
        status.error_detected  <= '0'; -- Non-blocking in TMR
        status.error_corrected <= err;
    end procedure;

    -- ECC
    procedure decode(
        signal protected_data : in  ecc_vector;
        signal data_out       : out std_logic_vector;
        signal status         : out ft_status_t
    ) is
    begin
        -- Hamming correction logic here
    end procedure;

end package body ft_pkg;