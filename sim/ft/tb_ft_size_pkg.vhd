-------------------------------------------------------------------------------
-- Title      : tb_ft_size_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_size_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_ft on the size functions of ft_pkg :
--              sizes      : encoded_size / decoded_size of 1 to 502 data bits
--                           (up to 9 Hamming parity bits for USE_ECC), with
--                           the ft_algo_t value and with the overload type
--              empty_word : 0 data bit : sizes, encode / decode, and an
--                           ft_dff with WIDTH = 0 (no error flag)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_ft_<algo>)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.ft_pkg.all;

library work;
use     work.tb_ft_bfm_pkg.all;

package tb_ft_size_pkg is

  procedure test_sizes
    (constant algo     : in    ft_algo_t
    );

  procedure test_empty_word
    (constant algo     : in    ft_algo_t
    ;signal   null_det : in    std_logic
    ;signal   null_cor : in    std_logic
    );

end package tb_ft_size_pkg;

package body tb_ft_size_pkg is

  -- Sizes with the overload type of algo (FT_NONE, FT_PARITY_ODD, ...)
  function encoded_size_typed(n : natural; algo : ft_algo_t) return natural is
  begin
    case algo is
      when USE_NONE        => return encoded_size(n, FT_NONE       );
      when USE_PARITY_ODD  => return encoded_size(n, FT_PARITY_ODD );
      when USE_PARITY_EVEN => return encoded_size(n, FT_PARITY_EVEN);
      when USE_TMR         => return encoded_size(n, FT_TMR        );
      when USE_ECC         => return encoded_size(n, FT_ECC        );
    end case;
  end function;

  function decoded_size_typed(n : natural; algo : ft_algo_t) return natural is
  begin
    case algo is
      when USE_NONE        => return decoded_size(n, FT_NONE       );
      when USE_PARITY_ODD  => return decoded_size(n, FT_PARITY_ODD );
      when USE_PARITY_EVEN => return decoded_size(n, FT_PARITY_EVEN);
      when USE_TMR         => return decoded_size(n, FT_TMR        );
      when USE_ECC         => return decoded_size(n, FT_ECC        );
    end case;
  end function;

  procedure test_sizes
    (constant algo     : in    ft_algo_t
    ) is
    variable v_size    : natural;
  begin
    log(ID_SEQUENCER, "sizes : encoded_size / decoded_size of 1 to 502 data bits", C_TB_SCOPE);
    for n in 1 to 502 loop
      v_size := ref_size(n, algo);
      check_value(encoded_size      (n, algo), v_size, ERROR, "encoded_size("       & integer'image(n)      & ")", C_TB_SCOPE);
      check_value(decoded_size      (v_size, algo), n, ERROR, "decoded_size("       & integer'image(v_size) & ")", C_TB_SCOPE);
      check_value(encoded_size_typed(n, algo), v_size, ERROR, "encoded_size typed(" & integer'image(n)      & ")", C_TB_SCOPE);
      check_value(decoded_size_typed(v_size, algo), n, ERROR, "decoded_size typed(" & integer'image(v_size) & ")", C_TB_SCOPE);
    end loop;
  end procedure;

  procedure test_empty_word
    (constant algo     : in    ft_algo_t
    ;signal   null_det : in    std_logic
    ;signal   null_cor : in    std_logic
    ) is
    constant C_NULL    : std_logic_vector(-1 downto 0) := (others => '0');
    constant C_ENC     : std_logic_vector              := encode(C_NULL, algo);
    variable v_dec     : ft_dec_t(data(-1 downto 0));
  begin
    log(ID_SEQUENCER, "empty_word : 0 data bit", C_TB_SCOPE);
    check_value(encoded_size(0, algo), ref_size(0, algo), ERROR, "encoded_size(0)"         , C_TB_SCOPE);
    check_value(C_ENC'length         , ref_size(0, algo), ERROR, "encode(empty word) length", C_TB_SCOPE);
    v_dec := decode(C_ENC, algo);
    check_value(v_dec.status.error_detected , '0', ERROR, "decode(encode(empty word)) : error_detected" , C_TB_SCOPE);
    check_value(v_dec.status.error_corrected, '0', ERROR, "decode(encode(empty word)) : error_corrected", C_TB_SCOPE);
    check_value(null_det                    , '0', ERROR, "ft_dff WIDTH = 0 : error_detected"          , C_TB_SCOPE);
    check_value(null_cor                    , '0', ERROR, "ft_dff WIDTH = 0 : error_corrected"         , C_TB_SCOPE);
  end procedure;

end package body tb_ft_size_pkg;
