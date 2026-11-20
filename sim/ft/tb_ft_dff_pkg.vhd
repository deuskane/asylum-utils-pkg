-------------------------------------------------------------------------------
-- Title      : tb_ft_dff_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_dff_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_ft on the protected register ft_dff, two
--              instances : SELF_REFRESH false (index 0) and true (index 1)
--              dff_reset       : during and after the reset : zero, no error
--                                flag (the reset value is a valid code word)
--              dff_write       : write / hold, data_i ignored when we_i = 0
--              dff_inject      : faulty word loaded by a write (injector
--                                tb_ft_enc_inj) : error flags and output,
--                                scrubbing by the self refresh, a write
--                                restores a valid word, a write right
--                                after the fault wins over the refresh
--              dff_reset_fault : the asynchronous reset clears a fault
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_ft_dff)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.ft_pkg.all;
use     asylum.logic_pkg.all;

library work;
use     work.tb_ft_bfm_pkg.all;
use     work.tb_ft_inj_pkg.all;

package tb_ft_dff_pkg is

  procedure test_dff_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    );

  procedure test_dff_write
    (signal   clk      : in    std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    );

  procedure test_dff_inject
    (constant algo     : in    ft_algo_t
    ;signal   clk      : in    std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ;signal   en       : out   std_logic
    ;signal   kind     : out   inj_kind_t
    );

  procedure test_dff_reset_fault
    (constant algo     : in    ft_algo_t
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ;signal   en       : out   std_logic
    ;signal   kind     : out   inj_kind_t
    );

end package tb_ft_dff_pkg;

package body tb_ft_dff_pkg is

  -- Name of the instance i in the messages
  function name(i : natural) return string is
  begin
    return "[SELF_REFRESH=" & boolean'image(C_REFRESH(i)) & "] ";
  end function;

  -- Both instances : output v, no error flag
  procedure check_all
    (constant msg      : in    string
    ;constant v        : in    std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ) is
  begin
    for i in C_REFRESH'range loop
      check_dec(name(i) & msg, expect_ok(v), q(i), det(i), cor(i));
    end loop;
  end procedure;

  -- Write v (we_i high during one rising edge), then data_i = not v
  -- (ignored, we_i = 0) ; returns on the falling edge after the write
  procedure write
    (constant v        : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ) is
  begin
    wait until falling_edge(clk);
    d  <= v;
    we <= '1';
    wait until falling_edge(clk);
    we <= '0';
    d  <= not v;
  end procedure;

  procedure test_dff_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ) is
    constant C_ZERO    : std_logic_vector(d'length-1 downto 0) := (others => '0');
  begin
    log(ID_SEQUENCER, "dff_reset : zero and no error flag during and after the reset", C_TB_SCOPE);
    arst_b <= '0';
    d      <= pattern(x"A5", d'length);
    we     <= '1';                        -- ignored during reset
    wait for 3*C_PERIOD;
    check_all("during reset", C_ZERO, q, det, cor);
    we     <= '0';
    wait until falling_edge(clk);
    arst_b <= '1';
    for c in 1 to 4 loop
      wait until rising_edge(clk);
      wait for 1 ns;
      check_all("after reset, cycle " & integer'image(c), C_ZERO, q, det, cor);
    end loop;
  end procedure;

  procedure test_dff_write
    (signal   clk      : in    std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ) is
    constant W         : natural := d'length;
    type     bytes_t   is array (natural range <>) of std_logic_vector(8-1 downto 0);
    constant C_BYTES   : bytes_t := (x"3C", x"7D", x"BE", x"FF");
  begin
    log(ID_SEQUENCER, "dff_write : write, hold 3 cycles, data_i ignored when we_i = 0", C_TB_SCOPE);
    for v in C_BYTES'range loop
      write(pattern(C_BYTES(v), W), clk, we, d);
      for c in 1 to 3 loop
        wait until rising_edge(clk);
        wait for 1 ns;
        check_all("hold " & to_hstring(pattern(C_BYTES(v), W)) & ", cycle " & integer'image(c), pattern(C_BYTES(v), W), q, det, cor);
      end loop;
    end loop;
    write(pattern(x"00", W), clk, we, d);
    check_all("write all zeros", pattern(x"00", W), q, det, cor);
    write(pattern(x"FF", W), clk, we, d);
    check_all("write all ones" , pattern(x"FF", W), q, det, cor);
  end procedure;

  -- Write v with the fault kind injected, check the flags and the output :
  -- right after the write, after 1 edge (self refresh), after 3 edges
  -- (stable), then a clean write
  procedure inject
    (constant algo     : in    ft_algo_t
    ;constant kind_v   : in    inj_kind_t
    ;constant v        : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ;signal   en       : out   std_logic
    ;signal   kind     : out   inj_kind_t
    ) is
    constant msg       : string  := "inject " & inj_kind_t'image(kind_v) & " on " & to_hstring(v);
    constant C_EXP     : expect_t := expect_flips(algo, v, inj_mask(kind_v, encoded_size(v'length, algo)));
    variable v_exp     : expect_t(data(v'length-1 downto 0));
  begin
    log(ID_SEQUENCER, msg, C_TB_SCOPE);
    write(v, clk, we, d);
    check_all("before " & msg, v, q, det, cor);

    -- Write with a corrupted encoded word : the register loads a faulty word
    kind <= kind_v;
    en   <= '1';
    write(v, clk, we, d);
    en   <= '0';
    for i in C_REFRESH'range loop
      check_dec(name(i) & msg, C_EXP, q(i), det(i), cor(i));
    end loop;

    -- Expected after a clock edge : a corrected error is scrubbed by the
    -- self refresh, else the faulty word is kept
    for e in 1 to 2 loop
      if e = 1
      then
        wait until rising_edge(clk);
      else
        wait until rising_edge(clk);
        wait until rising_edge(clk);
      end if;
      wait for 1 ns;
      for i in C_REFRESH'range loop
        v_exp := C_EXP;
        if C_REFRESH(i) and C_EXP.cor = '1'
        then
          v_exp := expect_ok(v);
        end if;
        check_dec(name(i) & msg & " after " & integer'image(2*e-1) & " edge(s)", v_exp, q(i), det(i), cor(i));
      end loop;
    end loop;

    -- A write always restores a valid code word
    write(v, clk, we, d);
    check_all("rewrite after " & msg, v, q, det, cor);

    -- A write on the edge right after the faulty write wins over the self
    -- refresh of a corrected error
    kind <= kind_v;
    en   <= '1';
    write(v, clk, we, d);
    en   <= '0';
    d    <= not v;
    we   <= '1';
    wait until falling_edge(clk);
    we   <= '0';
    check_all("write right after " & msg, not v, q, det, cor);
  end procedure;

  procedure test_dff_inject
    (constant algo     : in    ft_algo_t
    ;signal   clk      : in    std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ;signal   en       : out   std_logic
    ;signal   kind     : out   inj_kind_t
    ) is
    constant W         : natural := d'length;
  begin
    log(ID_SEQUENCER, "dff_inject : faulty word loaded by a write", C_TB_SCOPE);
    inject(algo, INJ_BIT0 , pattern(x"A5", W), clk, we, d, q, det, cor, en, kind);
    inject(algo, INJ_BIT0 , pattern(x"5A", W), clk, we, d, q, det, cor, en, kind);
    inject(algo, INJ_BIT01, pattern(x"C3", W), clk, we, d, q, det, cor, en, kind);
    inject(algo, INJ_BIT01, pattern(x"3C", W), clk, we, d, q, det, cor, en, kind);
    inject(algo, INJ_TOP  , pattern(x"96", W), clk, we, d, q, det, cor, en, kind);
    inject(algo, INJ_TOP  , pattern(x"69", W), clk, we, d, q, det, cor, en, kind);
  end procedure;

  procedure test_dff_reset_fault
    (constant algo     : in    ft_algo_t
    ;signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ;signal   we       : out   std_logic
    ;signal   d        : out   std_logic_vector
    ;signal   q        : in    slvs_t
    ;signal   det      : in    std_logic_vector
    ;signal   cor      : in    std_logic_vector
    ;signal   en       : out   std_logic
    ;signal   kind     : out   inj_kind_t
    ) is
    constant C_ZERO    : std_logic_vector(d'length-1 downto 0) := (others => '0');
    constant C_DATA    : std_logic_vector(d'length-1 downto 0) := pattern(x"A5", d'length);
    constant C_EXP     : expect_t := expect_flips(algo, C_DATA, inj_mask(INJ_BIT0, encoded_size(d'length, algo)));
  begin
    log(ID_SEQUENCER, "dff_reset_fault : the asynchronous reset clears a fault", C_TB_SCOPE);
    kind   <= INJ_BIT0;
    en     <= '1';
    write(C_DATA, clk, we, d);
    en     <= '0';
    for i in C_REFRESH'range loop
      check_dec(name(i) & "fault loaded", C_EXP, q(i), det(i), cor(i));
    end loop;
    -- Between two rising edges : no clock edge before the check
    arst_b <= '0';
    wait for 1 ns;
    check_all("reset after a fault, without clock edge", C_ZERO, q, det, cor);
    wait until falling_edge(clk);
    arst_b <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    check_all("one clock edge after the reset", C_ZERO, q, det, cor);
  end procedure;

end package body tb_ft_dff_pkg;
