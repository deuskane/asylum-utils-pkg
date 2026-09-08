-------------------------------------------------------------------------------
-- Title      : tb_ft_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- Description: Stress test for fault-tolerant encoder/decoder blocks
--              over the 5 supported algorithms:
--              NONE, PARITY_ODD, PARITY_EVEN, ECC and TMR.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use asylum.ft_pkg.all;

entity tb_ft_pkg is
end entity tb_ft_pkg;

architecture tb of tb_ft_pkg is

  constant C_SCOPE              : string := "TB_FT";
  constant DATA_VAL             : std_logic_vector(3 downto 0) := "1010";

  signal data_none_i            : std_logic_vector(3 downto 0) := (others => '0');
  signal enc_none_o             : std_logic_vector(3 downto 0);
  signal dec_none_i             : std_logic_vector(3 downto 0);
  signal dec_none_o             : std_logic_vector(3 downto 0);
  signal det_none_o             : std_logic;
  signal corr_none_o            : std_logic;

  signal data_parity_odd_i      : std_logic_vector(3 downto 0) := (others => '0');
  signal enc_parity_odd_o       : std_logic_vector(4 downto 0);
  signal dec_parity_odd_i       : std_logic_vector(4 downto 0);
  signal dec_parity_odd_o       : std_logic_vector(3 downto 0);
  signal det_parity_odd_o       : std_logic;
  signal corr_parity_odd_o      : std_logic;

  signal data_parity_even_i     : std_logic_vector(3 downto 0) := (others => '0');
  signal enc_parity_even_o      : std_logic_vector(4 downto 0);
  signal dec_parity_even_i      : std_logic_vector(4 downto 0);
  signal dec_parity_even_o      : std_logic_vector(3 downto 0);
  signal det_parity_even_o      : std_logic;
  signal corr_parity_even_o     : std_logic;

  signal data_ecc_i             : std_logic_vector(3 downto 0) := (others => '0');
  signal enc_ecc_o              : std_logic_vector(7 downto 0);
  signal dec_ecc_i              : std_logic_vector(7 downto 0);
  signal dec_ecc_o              : std_logic_vector(3 downto 0);
  signal det_ecc_o              : std_logic;
  signal corr_ecc_o             : std_logic;

  signal data_tmr_i             : std_logic_vector(3 downto 0) := (others => '0');
  signal enc_tmr_o              : std_logic_vector(11 downto 0);
  signal dec_tmr_i              : std_logic_vector(11 downto 0);
  signal dec_tmr_o              : std_logic_vector(3 downto 0);
  signal det_tmr_o              : std_logic;
  signal corr_tmr_o             : std_logic;

  procedure check_status(
    constant msg              : in string;
    constant exp_detected     : in std_logic;
    constant exp_corrected    : in std_logic;
    constant actual_detected  : in std_logic;
    constant actual_corrected : in std_logic
  ) is
  begin
    log(ID_LOG_HDR, msg, C_SCOPE);
    check_value(actual_detected, exp_detected, ERROR, msg & " detect");
    check_value(actual_corrected, exp_corrected, ERROR, msg & " correct");
  end procedure check_status;

  procedure log_step(constant msg : in string) is
  begin
    log(ID_LOG_HDR, msg, C_SCOPE);
  end procedure log_step;

  procedure flip_bit(variable v : inout std_logic_vector; idx : in natural) is
  begin
    v(idx) := not v(idx);
  end procedure flip_bit;

begin

  enc_none : ft_enc
    generic map (FT_ALGO => USE_NONE)
    port map (
      data_in  => data_none_i,
      data_out => enc_none_o
    );

  dec_none : ft_dec
    generic map (FT_ALGO => USE_NONE)
    port map (
      data_in         => dec_none_i,
      data_out        => dec_none_o,
      error_detected  => det_none_o,
      error_corrected => corr_none_o
    );

  enc_parity_odd : ft_enc
    generic map (FT_ALGO => USE_PARITY_ODD)
    port map (
      data_in  => data_parity_odd_i,
      data_out => enc_parity_odd_o
    );

  dec_parity_odd : ft_dec
    generic map (FT_ALGO => USE_PARITY_ODD)
    port map (
      data_in         => dec_parity_odd_i,
      data_out        => dec_parity_odd_o,
      error_detected  => det_parity_odd_o,
      error_corrected => corr_parity_odd_o
    );

  enc_parity_even : ft_enc
    generic map (FT_ALGO => USE_PARITY_EVEN)
    port map (
      data_in  => data_parity_even_i,
      data_out => enc_parity_even_o
    );

  dec_parity_even : ft_dec
    generic map (FT_ALGO => USE_PARITY_EVEN)
    port map (
      data_in         => dec_parity_even_i,
      data_out        => dec_parity_even_o,
      error_detected  => det_parity_even_o,
      error_corrected => corr_parity_even_o
    );

  enc_ecc : ft_enc
    generic map (FT_ALGO => USE_ECC)
    port map (
      data_in  => data_ecc_i,
      data_out => enc_ecc_o
    );

  dec_ecc : ft_dec
    generic map (FT_ALGO => USE_ECC)
    port map (
      data_in         => dec_ecc_i,
      data_out        => dec_ecc_o,
      error_detected  => det_ecc_o,
      error_corrected => corr_ecc_o
    );

  enc_tmr : ft_enc
    generic map (FT_ALGO => USE_TMR)
    port map (
      data_in  => data_tmr_i,
      data_out => enc_tmr_o
    );

  dec_tmr : ft_dec
    generic map (FT_ALGO => USE_TMR)
    port map (
      data_in         => dec_tmr_i,
      data_out        => dec_tmr_o,
      error_detected  => det_tmr_o,
      error_corrected => corr_tmr_o
    );

  stim_proc : process is
    variable v_none        : std_logic_vector(3 downto 0) := DATA_VAL;
    variable v_parity_odd  : std_logic_vector(4 downto 0) := (others => '0');
    variable v_parity_even : std_logic_vector(4 downto 0) := (others => '0');
    variable v_ecc         : std_logic_vector(7 downto 0) := (others => '0');
    variable v_tmr         : std_logic_vector(11 downto 0) := (others => '0');
    variable v_res         : integer;

  begin

    log(ID_LOG_HDR, "START: fault injection tests over the 5 FT algorithms", C_SCOPE);
    log(ID_LOG_HDR, "Testbench initialisation", C_SCOPE);

    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- NONE
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    log_step("[ALGO NONE] start");
    data_none_i <= DATA_VAL;
    wait for 1 ns;
    dec_none_i <= enc_none_o;
    wait for 1 ns;
    check_status("[ALGO NONE] no error", '0', '0', det_none_o, corr_none_o);
    assert dec_none_o = DATA_VAL report "NONE output mismatch without error" severity failure;

    v_none := enc_none_o;
    flip_bit(v_none, 0);
    dec_none_i <= v_none;
    wait for 1 ns;
    check_status("[ALGO NONE] 1 error", '0', '0', det_none_o, corr_none_o);

    v_none := enc_none_o;
    flip_bit(v_none, 0);
    flip_bit(v_none, 2);
    dec_none_i <= v_none;
    wait for 1 ns;
    check_status("[ALGO NONE] 2 errors", '0', '0', det_none_o, corr_none_o);

    v_none := enc_none_o;
    flip_bit(v_none, 0);
    flip_bit(v_none, 2);
    flip_bit(v_none, 3);
    dec_none_i <= v_none;
    wait for 1 ns;
    check_status("[ALGO NONE] 3 errors", '0', '0', det_none_o, corr_none_o);

    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- PARITY ODD
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    log_step("[ALGO PARITY_ODD] start");
    data_parity_odd_i <= DATA_VAL;
    wait for 1 ns;
    dec_parity_odd_i <= enc_parity_odd_o;
    wait for 1 ns;
    check_status("[ALGO PARITY_ODD] no error", '0', '0', det_parity_odd_o, corr_parity_odd_o);
    assert dec_parity_odd_o = DATA_VAL report "PARITY_ODD output mismatch without error" severity failure;

    for i in 0 to 4 loop
      v_parity_odd := enc_parity_odd_o;
      flip_bit(v_parity_odd, i);
      dec_parity_odd_i <= v_parity_odd;
      wait for 1 ns;
      check_status("[ALGO PARITY_ODD] 1 error bit " & integer'image(i), '1', '0', det_parity_odd_o, corr_parity_odd_o);
    end loop;

    for i in 0 to 3 loop
      for j in i + 1 to 4 loop
        v_parity_odd := enc_parity_odd_o;
        flip_bit(v_parity_odd, i);
        flip_bit(v_parity_odd, j);
        dec_parity_odd_i <= v_parity_odd;
        wait for 1 ns;
        check_status("[ALGO PARITY_ODD] 2 errors bits " & integer'image(i) & "," & integer'image(j), '0', '0', det_parity_odd_o, corr_parity_odd_o);
      end loop;
    end loop;

    for i in 0 to 2 loop
      for j in i + 1 to 3 loop
        for k in j + 1 to 4 loop
          v_parity_odd := enc_parity_odd_o;
          flip_bit(v_parity_odd, i);
          flip_bit(v_parity_odd, j);
          flip_bit(v_parity_odd, k);
          dec_parity_odd_i <= v_parity_odd;
          wait for 1 ns;
          check_status("[ALGO PARITY_ODD] 3 errors bits " & integer'image(i) & "," & integer'image(j) & "," & integer'image(k), '1', '0', det_parity_odd_o, corr_parity_odd_o);
        end loop;
      end loop;
    end loop;

    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- PARITY EVEN
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    log_step("[ALGO PARITY_EVEN] start");
    data_parity_even_i <= DATA_VAL;
    wait for 1 ns;
    dec_parity_even_i <= enc_parity_even_o;
    wait for 1 ns;
    check_status("[ALGO PARITY_EVEN] no error", '0', '0', det_parity_even_o, corr_parity_even_o);
    assert dec_parity_even_o = DATA_VAL report "PARITY_EVEN output mismatch without error" severity failure;

    for i in 0 to 4 loop
      v_parity_even := enc_parity_even_o;
      flip_bit(v_parity_even, i);
      dec_parity_even_i <= v_parity_even;
      wait for 1 ns;
      check_status("[ALGO PARITY_EVEN] 1 error bit " & integer'image(i), '1', '0', det_parity_even_o, corr_parity_even_o);
    end loop;

    for i in 0 to 3 loop
      for j in i + 1 to 4 loop
        v_parity_even := enc_parity_even_o;
        flip_bit(v_parity_even, i);
        flip_bit(v_parity_even, j);
        dec_parity_even_i <= v_parity_even;
        wait for 1 ns;
        check_status("[ALGO PARITY_EVEN] 2 errors bits " & integer'image(i) & "," & integer'image(j), '0', '0', det_parity_even_o, corr_parity_even_o);
      end loop;
    end loop;

    for i in 0 to 2 loop
      for j in i + 1 to 3 loop
        for k in j + 1 to 4 loop
          v_parity_even := enc_parity_even_o;
          flip_bit(v_parity_even, i);
          flip_bit(v_parity_even, j);
          flip_bit(v_parity_even, k);
          dec_parity_even_i <= v_parity_even;
          wait for 1 ns;
          check_status("[ALGO PARITY_EVEN] 3 errors bits " & integer'image(i) & "," & integer'image(j) & "," & integer'image(k), '1', '0', det_parity_even_o, corr_parity_even_o);
        end loop;
      end loop;
    end loop;

    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- TMR
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    log_step("[ALGO TMR] start");
    data_tmr_i <= DATA_VAL;
    wait for 1 ns;
    dec_tmr_i <= enc_tmr_o;
    wait for 1 ns;
    check_status("[ALGO TMR] no error", '0', '0', det_tmr_o, corr_tmr_o);
    assert dec_tmr_o = DATA_VAL report "TMR output mismatch without error" severity failure;

    for i in 0 to 11 loop
      v_tmr := enc_tmr_o;
      flip_bit(v_tmr, i);
      dec_tmr_i <= v_tmr;
      wait for 1 ns;
      check_status("[ALGO TMR] 1 error bit " & integer'image(i), '1', '1', det_tmr_o, corr_tmr_o);
      assert dec_tmr_o = DATA_VAL report "TMR output mismatch after single-bit correction (bit " & integer'image(i) & ")" severity failure;
    end loop;

    for i in 0 to 1 loop
      for j in i +1 to 2 loop
        v_tmr := enc_tmr_o;
        flip_bit(v_tmr, i);
        flip_bit(v_tmr, j);
        dec_tmr_i <= v_tmr;
        wait for 1 ns;
        check_status("[ALGO TMR] 2 errors bits " & integer'image(i) & "," & integer'image(j), '1', '1', det_tmr_o, corr_tmr_o);
        assert dec_tmr_o = DATA_VAL report "TMR output mismatch after two-bit correction (bits " & integer'image(i) & "," & integer'image(j) & ")" severity failure;
      end loop;
    end loop;

    v_tmr := enc_tmr_o;
    flip_bit(v_tmr, 0);
    flip_bit(v_tmr, 1);
    flip_bit(v_tmr, 2);
    dec_tmr_i <= v_tmr;
    wait for 1 ns;
    check_status("[ALGO TMR] 3 errors bits 0,1,2", '1', '1', det_tmr_o, corr_tmr_o);
    assert dec_tmr_o = DATA_VAL report "TMR output mismatch after two-bit correction" severity failure;
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- ECC
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    log_step("[ALGO ECC] start");
    data_ecc_i <= DATA_VAL;
    wait for 1 ns;
    dec_ecc_i <= enc_ecc_o;
    wait for 1 ns;
    check_status("[ALGO ECC] no error", '0', '0', det_ecc_o, corr_ecc_o);
    assert dec_ecc_o = DATA_VAL report "ECC output mismatch without error" severity failure;

    for i in 0 to 7 loop
      v_ecc := enc_ecc_o;
      flip_bit(v_ecc, i);
      dec_ecc_i <= v_ecc;
      wait for 1 ns;
      check_status("[ALGO ECC] 1 error bit " & integer'image(i), '1', '1', det_ecc_o, corr_ecc_o);
      assert dec_ecc_o = DATA_VAL report "ECC output mismatch after single-bit correction (bit " & integer'image(i) & ")" severity failure;
    end loop;

    for i in 0 to 6 loop
      for j in i + 1 to 7 loop
        v_ecc := enc_ecc_o;
        flip_bit(v_ecc, i);
        flip_bit(v_ecc, j);
        dec_ecc_i <= v_ecc;
        wait for 1 ns;
        check_status("[ALGO ECC] 2 errors bits " & integer'image(i) & "," & integer'image(j), '1', '0', det_ecc_o, corr_ecc_o);
      end loop;
    end loop;

    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    -- Encoded Size
    --------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------
    log_step("[ALGO NONE] Size");
    for i in 1 to 100 loop
        v_res := i;
        assert encoded_size(i, FT_NONE) = v_res report "Size missmatch for FT_NONE and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_NONE) = i report "Decoded size missmatch for FT_NONE and len=" & integer'image(i) severity failure;
    end loop;

    log_step("[ALGO PARITY_ODD] Size");
    for i in 1 to 100 loop
        v_res := i + 1;
        assert encoded_size(i, FT_PARITY_ODD) = v_res report "Size missmatch for FT_PARITY_ODD and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_PARITY_ODD) = i report "Decoded size missmatch for FT_PARITY_ODD and len=" & integer'image(i) severity failure;
    end loop;

    log_step("[ALGO PARITY_EVEN] Size");
    for i in 1 to 100 loop
        v_res := i + 1;
        assert encoded_size(i, FT_PARITY_EVEN) = v_res report "Size missmatch for FT_PARITY_EVEN and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_PARITY_EVEN) = i report "Decoded size missmatch for FT_PARITY_EVEN and len=" & integer'image(i) severity failure;
    end loop;

    log_step("[ALGO TMR] Size");
    for i in 1 to 100 loop
        v_res := i * 3;
        assert encoded_size(i, FT_TMR) = v_res report "Size missmatch for FT_TMR and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_TMR) = i report "Decoded size missmatch for FT_TMR and len=" & integer'image(i) severity failure;
    end loop;

    log_step("[ALGO ECC] Size");
    v_res := 1 + 2 + 1;
    assert encoded_size(1, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(1) severity failure;
    assert decoded_size(v_res, FT_ECC) = 1 report "Decoded size missmatch for FT_ECC and len=" & integer'image(1) severity failure;
    for i in 2 to 4 loop
        v_res := i + 3 + 1;
        assert encoded_size(i, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_ECC) = i report "Decoded size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
    end loop;
    for i in 5 to 11 loop
        v_res := i + 4 + 1;
        assert encoded_size(i, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_ECC) = i report "Decoded size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
    end loop;
    for i in 12 to 26 loop
        v_res := i + 5 + 1;
        assert encoded_size(i, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_ECC) = i report "Decoded size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
    end loop;
    for i in 27 to 57 loop
        v_res := i + 6 + 1;
        assert encoded_size(i, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_ECC) = i report "Decoded size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
    end loop;
    for i in 58 to 120 loop
        v_res := i + 7 + 1;
        assert encoded_size(i, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_ECC) = i report "Decoded size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
    end loop;
    for i in 121 to 247 loop
        v_res := i + 8 + 1;
        assert encoded_size(i, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_ECC) = i report "Decoded size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
    end loop;
    for i in 248 to 502 loop
        v_res := i + 9 + 1;
        assert encoded_size(i, FT_ECC) = v_res report "Size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
        assert decoded_size(v_res, FT_ECC) = i report "Decoded size missmatch for FT_ECC and len=" & integer'image(i) severity failure;
    end loop;

    log_step("PASS: all algorithms validated");
    wait;
  end process stim_proc;

end architecture tb;
