-------------------------------------------------------------------------------
-- Title      : tb_ft_codec_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_codec_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_ft on the encoder ft_enc and the decoder
--              ft_dec (combinational, no clock) :
--              no_error : encoded word (reference model) and decoded word
--                         of 4 data words, no error flag
--              single   : every single bit flip of the encoded word
--              double   : every pair of flips
--              triple   : every triple of flips (not USE_ECC : SEC-DED
--                         gives no guarantee beyond 2 flips)
--              Faulty words built from the encoded word of the reference
--              model, expected decoder outputs from expect_flips
--              (tb_ft_bfm_pkg).
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

package tb_ft_codec_pkg is

  procedure test_no_error
    (constant algo     : in    ft_algo_t
    ;signal   enc_d    : out   std_logic_vector
    ;signal   enc_o    : in    std_logic_vector
    ;signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    );

  -- nb_flips flips (1 to 3) at every set of positions of the encoded word
  -- (reference model) of a data word of dec_o'length bits
  procedure test_flips
    (constant nb_flips : in    positive
    ;constant algo     : in    ft_algo_t
    ;signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    );

end package tb_ft_codec_pkg;

package body tb_ft_codec_pkg is

  -- Decode the encoded word enc with the bits of mask flipped, check the
  -- output against the model
  procedure flip_check
    (constant nb_flips : in    positive
    ;constant algo     : in    ft_algo_t
    ;constant d        : in    std_logic_vector
    ;constant enc      : in    std_logic_vector
    ;constant mask     : in    std_logic_vector
    ;signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    ) is
  begin
    dec_i <= enc xor mask;
    wait for 1 ns;
    check_dec(integer'image(nb_flips) & " flip(s), mask " & to_hstring(mask),
              expect_flips(algo, d, mask), dec_o, dec_det, dec_cor);
  end procedure;

  procedure test_no_error
    (constant algo     : in    ft_algo_t
    ;signal   enc_d    : out   std_logic_vector
    ;signal   enc_o    : in    std_logic_vector
    ;signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    ) is
    constant W         : natural := enc_d'length;
    type     datas_t   is array (0 to 3) of std_logic_vector(W-1 downto 0);
    -- Every bit at 0 and at 1
    constant C_DATAS   : datas_t := (pattern(C_SEED, W), not pattern(C_SEED, W),
                                     (others => '0'), (others => '1'));
  begin
    log(ID_SEQUENCER, "no_error : encoded word and decoded word without error", C_TB_SCOPE);
    for v in C_DATAS'range loop
      enc_d <= C_DATAS(v);
      wait for 1 ns;
      check_value(enc_o, ref_encode(C_DATAS(v), algo), ERROR, "ft_enc(" & to_hstring(C_DATAS(v)) & ") : encoded word", C_TB_SCOPE);
      dec_i <= enc_o;
      wait for 1 ns;
      check_dec("ft_dec(ft_enc(" & to_hstring(C_DATAS(v)) & "))", expect_ok(C_DATAS(v)), dec_o, dec_det, dec_cor);
    end loop;
  end procedure;

  procedure test_flips
    (constant nb_flips : in    positive
    ;constant algo     : in    ft_algo_t
    ;signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    ) is
    constant W         : natural := dec_o'length;
    constant N         : natural := dec_i'length;
    constant C_DATA    : std_logic_vector(W-1 downto 0) := pattern(C_SEED, W);
    variable v_enc     : std_logic_vector(N-1 downto 0);
    variable v_mask    : std_logic_vector(N-1 downto 0);
  begin
    log(ID_SEQUENCER, integer'image(nb_flips) & " flip(s) at every position of the encoded word of " & to_hstring(C_DATA), C_TB_SCOPE);
    v_enc := ref_encode(C_DATA, algo);
    for i in 0 to N-1 loop
      if nb_flips = 1
      then
        v_mask    := (others => '0');
        v_mask(i) := '1';
        flip_check(nb_flips, algo, C_DATA, v_enc, v_mask, dec_i, dec_o, dec_det, dec_cor);
      end if;
      for j in i+1 to N-1 loop
        if nb_flips = 2
        then
          v_mask    := (others => '0');
          v_mask(i) := '1';
          v_mask(j) := '1';
          flip_check(nb_flips, algo, C_DATA, v_enc, v_mask, dec_i, dec_o, dec_det, dec_cor);
        end if;
        for k in j+1 to N-1 loop
          if nb_flips = 3
          then
            v_mask    := (others => '0');
            v_mask(i) := '1';
            v_mask(j) := '1';
            v_mask(k) := '1';
            flip_check(nb_flips, algo, C_DATA, v_enc, v_mask, dec_i, dec_o, dec_det, dec_cor);
          end if;
        end loop;
      end loop;
    end loop;
  end procedure;

end package body tb_ft_codec_pkg;
