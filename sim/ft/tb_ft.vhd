-------------------------------------------------------------------------------
-- Title      : tb_ft
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking UVVM testbench of the fault-tolerance entities
--              for one algorithm : ft_enc + ft_dec (codec), two ft_dff
--              (SELF_REFRESH false and true) and one ft_dff of 0 bit.
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_ft_tests_pkg), each one after a reset
--                           pulse ; "" : build and elaboration only
--              FT_ALGO    : algorithm of every DUT
--              WIDTH      : data width of the codec and of the ft_dff
--              Toplevel : the configuration tb_ft_cfg (tb_ft_cfg.vhd) binds
--              the encoder of the two ft_dff to the injector tb_ft_enc_inj.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (merge of tb_ft_<algo> and
--                               tb_ft_dff : TESTS_LIST, FT_ALGO, WIDTH)
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
use     work.tb_ft_tests_pkg.all;

entity tb_ft is
  generic (
    TESTS_LIST        : string    := ""        -- Scenarios, e.g. "single,dff_inject"
   ;FT_ALGO           : ft_algo_t := USE_ECC   -- Algorithm of every DUT
   ;WIDTH             : positive  := 32        -- Data width
  );
end entity tb_ft;

architecture sim of tb_ft is

  constant C_SCOPE    : string  := "TB_FT";
  constant WIDTH_ENC  : natural := encoded_size(WIDTH, FT_ALGO);

  signal   clk        : std_logic := '0';
  signal   clk_ena    : boolean   := true;
  signal   arst_b     : std_logic := '0';

  -- ft_enc / ft_dec
  signal   enc_d      : std_logic_vector(WIDTH    -1 downto 0) := (others => '0');
  signal   enc_o      : std_logic_vector(WIDTH_ENC-1 downto 0);
  signal   dec_i      : std_logic_vector(WIDTH_ENC-1 downto 0) := (others => '0');
  signal   dec_o      : std_logic_vector(WIDTH    -1 downto 0);
  signal   dec_det    : std_logic;
  signal   dec_cor    : std_logic;

  -- ft_dff
  signal   dff_we     : std_logic := '0';
  signal   dff_d      : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal   dff_q      : slvs_t(C_REFRESH'range)(WIDTH-1 downto 0);
  signal   dff_det    : std_logic_vector(C_REFRESH'range);
  signal   dff_cor    : std_logic_vector(C_REFRESH'range);
  signal   null_d     : std_logic_vector(-1 downto 0);
  signal   null_q     : std_logic_vector(-1 downto 0);
  signal   null_det   : std_logic;
  signal   null_cor   : std_logic;

begin  -- architecture sim

  clock_generator(clk, clk_ena, C_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut_enc : ft_enc
    generic map (
      FT_ALGO           => FT_ALGO
    )
    port map (
      data_i            => enc_d
     ,data_o            => enc_o
    );

  dut_dec : ft_dec
    generic map (
      FT_ALGO           => FT_ALGO
    )
    port map (
      data_i            => dec_i
     ,data_o            => dec_o
     ,error_detected_o  => dec_det
     ,error_corrected_o => dec_cor
    );

  gen_dff : for i in C_REFRESH'range
  generate
    dut : ft_dff
      generic map (
        WIDTH             => WIDTH
       ,FT_ALGO           => FT_ALGO
       ,SELF_REFRESH      => C_REFRESH(i)
      )
      port map (
        clk_i             => clk
       ,arst_b_i          => arst_b
       ,we_i              => dff_we
       ,data_i            => dff_d
       ,data_o            => dff_q  (i)
       ,error_detected_o  => dff_det(i)
       ,error_corrected_o => dff_cor(i)
      );
  end generate gen_dff;

  -- ft_dff with WIDTH = 0 must elaborate, without error flag
  dut_null : ft_dff
    generic map (
      WIDTH             => 0
     ,FT_ALGO           => FT_ALGO
     ,SELF_REFRESH      => true
    )
    port map (
      clk_i             => clk
     ,arst_b_i          => arst_b
     ,we_i              => dff_we
     ,data_i            => null_d
     ,data_o            => null_q
     ,error_detected_o  => null_det
     ,error_corrected_o => null_cor
    );

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "FT_ALGO = " & ft_algo_t'image(FT_ALGO) & ", WIDTH = " & integer'image(WIDTH) & ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    -- A non-empty list has at least one scenario (list_length is under test
    -- too : a run of no scenario must not pass)
    if TESTS_LIST'length > 0 and list_length(TESTS_LIST) = 0
    then
      alert(TB_ERROR, "No scenario found in TESTS_LIST : " & TESTS_LIST, C_SCOPE);
    end if;

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST) loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      elsif not test_applies(list_item(TESTS_LIST, i), FT_ALGO)
      then
        alert(TB_ERROR, "Test """ & list_item(TESTS_LIST, i) & """ does not apply to " & ft_algo_t'image(FT_ALGO), C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      -- Inputs idle, reset pulse : each scenario starts from reset
      enc_d    <= (others => '0');
      dec_i    <= (others => '0');
      dff_we   <= '0';
      dff_d    <= (others => '0');
      inj_en   <= '0';
      do_reset(clk, arst_b);
      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), FT_ALGO, clk, arst_b,
               enc_d, enc_o, dec_i, dec_o, dec_det, dec_cor,
               dff_we, dff_d, dff_q, dff_det, dff_cor, null_det, null_cor,
               inj_en, inj_kind);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
