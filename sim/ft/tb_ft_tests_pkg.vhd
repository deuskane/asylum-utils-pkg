-------------------------------------------------------------------------------
-- Title      : tb_ft_tests_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_tests_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_ft : names (valid items of TESTS_LIST),
--              algorithms they apply to, and dispatch (run_test) to the
--              packages tb_ft_codec_pkg, tb_ft_ecc_pkg, tb_ft_size_pkg and
--              tb_ft_dff_pkg
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_ft_<algo> and tb_ft_dff)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.ft_pkg.all;
use     asylum.logic_pkg.all;
use     asylum.string_pkg.all;

library work;
use     work.tb_ft_bfm_pkg.all;
use     work.tb_ft_inj_pkg.all;
use     work.tb_ft_codec_pkg.all;
use     work.tb_ft_ecc_pkg.all;
use     work.tb_ft_size_pkg.all;
use     work.tb_ft_dff_pkg.all;

package tb_ft_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "no_error,single,double,triple,ecc_syndrome,sizes,empty_word,dff_reset,dff_write,dff_inject,dff_reset_fault";

  -- The scenario name applies to the algorithm algo
  function test_applies
    (constant name     : in    string
    ;constant algo     : in    ft_algo_t
    ) return boolean;

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    ;constant algo     : in    ft_algo_t
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    -- ft_enc / ft_dec
    ;signal   enc_d    : out   std_logic_vector
    ;signal   enc_o    : in    std_logic_vector
    ;signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    -- ft_dff
    ;signal   dff_we   : out   std_logic
    ;signal   dff_d    : out   std_logic_vector
    ;signal   dff_q    : in    slvs_t
    ;signal   dff_det  : in    std_logic_vector
    ;signal   dff_cor  : in    std_logic_vector
    ;signal   null_det : in    std_logic
    ;signal   null_cor : in    std_logic
    -- Fault injection
    ;signal   inj_en   : out   std_logic
    ;signal   inj_kind : out   inj_kind_t
    );

end package tb_ft_tests_pkg;

package body tb_ft_tests_pkg is

  function test_applies
    (constant name     : in    string
    ;constant algo     : in    ft_algo_t
    ) return boolean is
  begin
    if    string_eq(name, "triple")
    then
      -- SEC-DED gives no guarantee beyond 2 flips
      return algo /= USE_ECC;
    elsif string_eq(name, "ecc_syndrome")
    then
      return algo  = USE_ECC;
    else
      return true;
    end if;
  end function;

  procedure run_test
    (constant name     : in    string
    ;constant algo     : in    ft_algo_t
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   enc_d    : out   std_logic_vector
    ;signal   enc_o    : in    std_logic_vector
    ;signal   dec_i    : out   std_logic_vector
    ;signal   dec_o    : in    std_logic_vector
    ;signal   dec_det  : in    std_logic
    ;signal   dec_cor  : in    std_logic
    ;signal   dff_we   : out   std_logic
    ;signal   dff_d    : out   std_logic_vector
    ;signal   dff_q    : in    slvs_t
    ;signal   dff_det  : in    std_logic_vector
    ;signal   dff_cor  : in    std_logic_vector
    ;signal   null_det : in    std_logic
    ;signal   null_cor : in    std_logic
    ;signal   inj_en   : out   std_logic
    ;signal   inj_kind : out   inj_kind_t
    ) is
  begin
    if    string_eq(name, "no_error")
    then
      test_no_error(algo, enc_d, enc_o, dec_i, dec_o, dec_det, dec_cor);
    elsif string_eq(name, "single")
    then
      test_flips(1, algo, dec_i, dec_o, dec_det, dec_cor);
    elsif string_eq(name, "double")
    then
      test_flips(2, algo, dec_i, dec_o, dec_det, dec_cor);
    elsif string_eq(name, "triple")
    then
      test_flips(3, algo, dec_i, dec_o, dec_det, dec_cor);
    elsif string_eq(name, "ecc_syndrome")
    then
      test_ecc_syndrome(dec_i, dec_o, dec_det, dec_cor);
    elsif string_eq(name, "sizes")
    then
      test_sizes(algo);
    elsif string_eq(name, "empty_word")
    then
      test_empty_word(algo, null_det, null_cor);
    elsif string_eq(name, "dff_reset")
    then
      test_dff_reset(clk, arst_b, dff_we, dff_d, dff_q, dff_det, dff_cor);
    elsif string_eq(name, "dff_write")
    then
      test_dff_write(clk, dff_we, dff_d, dff_q, dff_det, dff_cor);
    elsif string_eq(name, "dff_inject")
    then
      test_dff_inject(algo, clk, dff_we, dff_d, dff_q, dff_det, dff_cor, inj_en, inj_kind);
    elsif string_eq(name, "dff_reset_fault")
    then
      test_dff_reset_fault(algo, clk, arst_b, dff_we, dff_d, dff_q, dff_det, dff_cor, inj_en, inj_kind);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_ft_tests_pkg;
