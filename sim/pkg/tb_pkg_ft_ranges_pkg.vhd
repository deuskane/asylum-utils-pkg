-------------------------------------------------------------------------------
-- Title      : tb_pkg_ft_ranges_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_ft_ranges_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario ft_ranges of tb_pkg : encode / decode of ft_pkg on a
--              slice of a wider vector and on an ascending vector (ECC, TMR,
--              parity)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.ft_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_ft_ranges_pkg is

  -- ft_pkg functions on any index range
  procedure run;

end package tb_pkg_ft_ranges_pkg;

package body tb_pkg_ft_ranges_pkg is

  procedure run is
    variable v_word : std_logic_vector(127 downto 0);
    variable v_easc : std_logic_vector(0 to 38);
    variable v_dec  : ft_dec_t(data(31 downto 0));
  begin
    log(ID_SEQUENCER, "ECC word stored in the upper part of a wider vector, one bit flipped", C_TB_SCOPE);
    v_word := (others => '0');
    v_word(77 downto 39) := encode(std_logic_vector'(x"deadbeef"), USE_ECC);
    v_word(40) := not v_word(40);
    v_dec  := decode(v_word(77 downto 39), USE_ECC);
    check_value(v_dec.data, x"deadbeef", ERROR, "ECC decode(77 downto 39) data", C_TB_SCOPE);
    check_value(v_dec.status.error_corrected, '1', ERROR, "ECC decode(77 downto 39) corrected", C_TB_SCOPE);

    log(ID_SEQUENCER, "ECC word in an ascending vector (assignment by position)", C_TB_SCOPE);
    v_easc := encode(std_logic_vector'(x"deadbeef"), USE_ECC);
    v_dec  := decode(v_easc, USE_ECC);
    check_value(v_dec.data, x"deadbeef", ERROR, "ECC decode(0 to 38) data", C_TB_SCOPE);
    check_value(v_dec.status.error_detected, '0', ERROR, "ECC decode(0 to 38) no error", C_TB_SCOPE);
    v_easc := encode(v_dec.data(31 downto 0), USE_ECC);
    v_dec  := decode(v_easc, USE_ECC);
    check_value(v_dec.data, x"deadbeef", ERROR, "ECC encode/decode (0 to 38) round trip", C_TB_SCOPE);

    log(ID_SEQUENCER, "TMR word in the middle of a wider vector, one copy corrupted", C_TB_SCOPE);
    v_word := (others => '0');
    v_word(111 downto 16) := encode(std_logic_vector'(x"deadbeef"), USE_TMR);
    v_word(40) := not v_word(40);
    v_dec  := decode(v_word(111 downto 16), USE_TMR);
    check_value(v_dec.data, x"deadbeef", ERROR, "TMR decode(111 downto 16) data", C_TB_SCOPE);
    check_value(v_dec.status.error_corrected, '1', ERROR, "TMR decode(111 downto 16) corrected", C_TB_SCOPE);

    log(ID_SEQUENCER, "Parity word in an ascending vector", C_TB_SCOPE);
    v_easc(0 to 32) := encode(std_logic_vector'(x"deadbeef"), USE_PARITY_EVEN);
    v_dec  := decode(v_easc(0 to 32), USE_PARITY_EVEN);
    check_value(v_dec.data, x"deadbeef", ERROR, "PARITY_EVEN decode(0 to 32) data", C_TB_SCOPE);
    check_value(v_dec.status.error_detected, '0', ERROR, "PARITY_EVEN decode(0 to 32) no error", C_TB_SCOPE);
    v_easc(0 to 32) := encode(std_logic_vector'(x"deadbeef"), USE_PARITY_ODD);
    v_dec  := decode(v_easc(0 to 32), USE_PARITY_ODD);
    check_value(v_dec.data, x"deadbeef", ERROR, "PARITY_ODD decode(0 to 32) data", C_TB_SCOPE);
    check_value(v_dec.status.error_detected, '0', ERROR, "PARITY_ODD decode(0 to 32) no error", C_TB_SCOPE);
  end procedure;

end package body tb_pkg_ft_ranges_pkg;
