-------------------------------------------------------------------------------
-- Title      : tb_ft_ecc_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_ecc_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario ecc_syndrome of tb_ft (USE_ECC only), on the decoder
--              ft_dec : multiple flips the SEC-DED code cannot handle
--              - 3 flips (bits 0, 1, 2) of the zero word : syndrome 3 and a
--                global parity error, decoded as a single error on bit 3
--                (data bit 0) : a wrong correction, flagged as corrected
--              - with r Hamming parity bits, the syndromes from the size of
--                the encoded word to 2**r-1 point outside the word (shortened
--                code) : detected, never corrected, data unchanged
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_ft_ecc4 / tb_ft_ecc32)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.ft_pkg.all;

library work;
use     work.tb_ft_bfm_pkg.all;

package tb_ft_ecc_pkg is

  procedure test_ecc_syndrome
    (signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    );

end package tb_ft_ecc_pkg;

package body tb_ft_ecc_pkg is

  procedure test_ecc_syndrome
    (signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    ) is
    constant W         : natural := dec_o'length;
    constant N         : natural := dec_i'length;
    constant R         : natural := N - W - 1;   -- Hamming parity bits
    constant C_DATA    : std_logic_vector(W-1 downto 0) := pattern(C_SEED, W);
    variable v_enc     : std_logic_vector(N-1 downto 0);
    variable v_exp     : expect_t(data(W-1 downto 0));
    variable v_nb      : natural;
  begin
    log(ID_SEQUENCER, "ecc_syndrome : 3 flips of the zero word (bits 0, 1, 2) : wrong correction of data bit 0", C_TB_SCOPE);
    v_enc               := (others => '0');
    v_enc(2 downto 0)   := "111";
    dec_i               <= v_enc;
    wait for 1 ns;
    v_exp               := expect_ok((W-1 downto 0 => '0'));
    v_exp.data(0)       := '1';
    v_exp.det           := '1';
    v_exp.cor           := '1';
    check_dec("bits 0, 1, 2 flipped", v_exp, dec_o, dec_det, dec_cor);

    if N <= 2**R-1
    then
      log(ID_SEQUENCER, "ecc_syndrome : syndromes " & integer'image(N) & " to " & integer'image(2**R-1) & " (outside the word) : detected, not corrected", C_TB_SCOPE);
    end if;
    for s in N to 2**R-1 loop
      -- Flip the Hamming parity bits of the syndrome s, and bit 0 if needed
      -- to make the number of flips odd (global parity error)
      v_enc := ref_encode(C_DATA, USE_ECC);
      v_nb  := 0;
      for k in 0 to R-1 loop
        if (s / 2**k) mod 2 = 1
        then
          v_enc(2**k) := not v_enc(2**k);
          v_nb        := v_nb + 1;
        end if;
      end loop;
      if v_nb mod 2 = 0
      then
        v_enc(0) := not v_enc(0);
      end if;
      dec_i <= v_enc;
      wait for 1 ns;
      v_exp     := expect_ok(C_DATA);
      v_exp.det := '1';
      check_dec("syndrome " & integer'image(s), v_exp, dec_o, dec_det, dec_cor);
    end loop;
  end procedure;

end package body tb_ft_ecc_pkg;
