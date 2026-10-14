-------------------------------------------------------------------------------
-- Title      : tb_ft_dff
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_dff.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking testbench of ft_dff.
--              10 DUTs : every FT algorithm with SELF_REFRESH false and true.
--              Checks : reset value (valid code word, no error flag),
--              write / hold, and fault injection in the encoded register :
--              error flags, corrected output, and self refresh (scrubbing)
--              behaviour.
--              Fault injection : the configuration tb_ft_dff_cfg
--              (tb_ft_dff_cfg.vhd) binds the encoder instance (enc_inst) of
--              each ft_dff to tb_ft_enc_inj (tb_ft_enc_inj.vhd), which
--              corrupts the encoded word during a write, under the control
--              of tb_ft_dff_inj_pkg (tb_ft_dff_inj_pkg.vhd). No VHDL-2008
--              external name (not supported by the GHDL gcc / llvm backends).
--              Toplevel : tb_ft_dff_cfg.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created
-- 2026-10-13  1.1      mrosiere Fault injection through the configuration
--                               tb_ft_dff_cfg (tb_ft_enc_inj replaces
--                               enc_inst) instead of external name + force
--                               (GHDL gcc / llvm). Injector, package and
--                               configuration in separate files
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.ft_pkg.all;

use     work.tb_ft_dff_inj_pkg.all;

entity tb_ft_dff is
end entity tb_ft_dff;

architecture sim of tb_ft_dff is

  constant C_SCOPE    : string  := "TB_FT_DFF";
  constant C_PERIOD   : time    := 10 ns;
  constant WIDTH      : natural := 8;
  constant NB_DUT     : natural := 10;

  type algos_t    is array (natural range <>) of ft_algo_t;
  type booleans_t is array (natural range <>) of boolean;
  type datas_t    is array (natural range <>) of std_logic_vector(WIDTH-1 downto 0);

  constant C_ALGO     : algos_t   (0 to NB_DUT-1) := (USE_NONE, USE_PARITY_ODD, USE_PARITY_EVEN, USE_TMR, USE_ECC,
                                                       USE_NONE, USE_PARITY_ODD, USE_PARITY_EVEN, USE_TMR, USE_ECC);
  constant C_REFRESH  : booleans_t(0 to NB_DUT-1) := (false, false, false, false, false,
                                                       true , true , true , true , true );

  signal clk          : std_logic := '0';
  signal clk_ena      : boolean   := true;
  signal arst_b       : std_logic := '0';
  signal we           : std_logic := '0';
  signal data         : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

  signal data_o       : datas_t  (0 to NB_DUT-1);
  signal err_det      : std_logic_vector(0 to NB_DUT-1);
  signal err_cor      : std_logic_vector(0 to NB_DUT-1);

  function name(i : natural) return string is
  begin
    return "[" & ft_algo_t'image(C_ALGO(i)) & " SELF_REFRESH=" & boolean'image(C_REFRESH(i)) & "] ";
  end function;

  -- Expected output with the faulty word in the register, from the
  -- knowledge of the encoded layout of each algorithm (WIDTH = 8) :
  --   NONE        : 8 bits data
  --   PARITY_*    : parity(8) & data(7:0)
  --   TMR         : data & data & data (bits 0 and 1 belong to copy 0)
  --   ECC         : 13 bits, bit 0 = global parity, 1/2/4/8 Hamming parity
  type expect_t is record
    det     : std_logic;
    cor     : std_logic;
    data    : std_logic_vector(WIDTH-1 downto 0);
    chkdata : boolean;
  end record;

  function expect_inj(algo : ft_algo_t; kind : inj_kind_t; d : std_logic_vector(WIDTH-1 downto 0)) return expect_t is
    variable e : expect_t;
  begin
    e := (det => '0', cor => '0', data => d, chkdata => true);
    case algo is
      when USE_NONE =>
        case kind is
          when INJ_BIT0  => e.data(0)       := not d(0);
          when INJ_BIT01 => e.data(1 downto 0) := not d(1 downto 0);
          when INJ_TOP   => e.data(WIDTH-1) := not d(WIDTH-1);
        end case;
      when USE_PARITY_ODD | USE_PARITY_EVEN =>
        case kind is
          when INJ_BIT0  => e.det := '1'; e.data(0) := not d(0);
          when INJ_BIT01 => e.data(1 downto 0) := not d(1 downto 0); -- even number of flips : undetected
          when INJ_TOP   => e.det := '1';                            -- parity bit flipped, data intact
        end case;
      when USE_TMR =>
        e.det := '1'; e.cor := '1';                                  -- always corrected (different positions)
      when USE_ECC =>
        case kind is
          when INJ_BIT0 | INJ_TOP => e.det := '1'; e.cor := '1';     -- single error corrected
          when INJ_BIT01          => e.det := '1'; e.chkdata := false; -- double error : detected only
        end case;
    end case;
    return e;
  end function;

  -- Expected output once the faulty word has been through a clock edge
  function expect_after_edge(algo : ft_algo_t; refresh : boolean; kind : inj_kind_t; d : std_logic_vector(WIDTH-1 downto 0)) return expect_t is
    variable e : expect_t;
  begin
    e := expect_inj(algo, kind, d);
    -- A corrected error is scrubbed by the self refresh
    if refresh and e.cor = '1' then
      e := (det => '0', cor => '0', data => d, chkdata => true);
    end if;
    return e;
  end function;

begin

  clock_generator(clk, clk_ena, C_PERIOD, "TB Clock");

  gen_dut : for i in 0 to NB_DUT-1 generate
    dut : ft_dff
      generic map (
        WIDTH             => WIDTH
       ,FT_ALGO           => C_ALGO(i)
       ,SELF_REFRESH      => C_REFRESH(i)
      )
      port map (
        clk_i             => clk
       ,arst_b_i          => arst_b
       ,we_i              => we
       ,data_i            => data
       ,data_o            => data_o (i)
       ,error_detected_o  => err_det(i)
       ,error_corrected_o => err_cor(i)
      );
  end generate gen_dut;

  p_main : process

    procedure check_all(constant msg : in string; constant d : in std_logic_vector(WIDTH-1 downto 0)) is
    begin
      for i in 0 to NB_DUT-1 loop
        check_value(data_o (i), d  , ERROR, name(i) & msg & " : data_o"           , C_SCOPE);
        check_value(err_det(i), '0', ERROR, name(i) & msg & " : error_detected_o" , C_SCOPE);
        check_value(err_cor(i), '0', ERROR, name(i) & msg & " : error_corrected_o", C_SCOPE);
      end loop;
    end procedure;

    procedure check_expect(constant msg : in string; constant i : in natural; constant e : in expect_t) is
    begin
      if e.chkdata then
        check_value(data_o(i), e.data, ERROR, name(i) & msg & " : data_o", C_SCOPE);
      end if;
      check_value(err_det(i), e.det, ERROR, name(i) & msg & " : error_detected_o" , C_SCOPE);
      check_value(err_cor(i), e.cor, ERROR, name(i) & msg & " : error_corrected_o", C_SCOPE);
    end procedure;

    procedure write(constant d : in std_logic_vector(WIDTH-1 downto 0)) is
    begin
      wait until falling_edge(clk);
      data <= d;
      we   <= '1';
      wait until falling_edge(clk);
      we   <= '0';
      data <= not d;   -- data_i must be ignored when we_i = '0'
    end procedure;

    procedure inject(constant kind : in inj_kind_t; constant d : in std_logic_vector(WIDTH-1 downto 0)) is
      constant msg : string := "inject " & inj_kind_t'image(kind) & " on " & to_hstring(d);
    begin
      log(ID_LOG_HDR, msg, C_SCOPE);
      write(d);
      check_all("before " & msg, d);

      -- Write with a corrupted encoded word : the register loads a faulty
      -- word (write returns at the falling edge after the write edge,
      -- we_i is already '0')
      inj_kind <= kind;
      inj_en   <= '1';
      write(d);
      inj_en   <= '0';
      for i in 0 to NB_DUT-1 loop
        check_expect(msg, i, expect_inj(C_ALGO(i), kind, d));
      end loop;

      -- Clock edge : the register reloads (keep or refresh)
      wait until rising_edge(clk);
      wait for 1 ns;
      for i in 0 to NB_DUT-1 loop
        check_expect(msg & " after 1 edge", i, expect_after_edge(C_ALGO(i), C_REFRESH(i), kind, d));
      end loop;

      -- The state is stable on the following edges
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait for 1 ns;
      for i in 0 to NB_DUT-1 loop
        check_expect(msg & " after 3 edges", i, expect_after_edge(C_ALGO(i), C_REFRESH(i), kind, d));
      end loop;

      -- A write always restores a valid code word
      write(d);
      check_all("rewrite after " & msg, d);
    end procedure;

  begin
    log(ID_LOG_HDR, "START: ft_dff (all algorithms, SELF_REFRESH false/true)", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "Reset value : valid code word, no error flag", C_SCOPE);
    ---------------------------------------------------------------------------
    arst_b <= '0';
    data   <= x"A5";
    we     <= '1';                       -- ignored during reset
    wait for 3*C_PERIOD;
    check_all("during reset", x"00");
    we     <= '0';
    wait until falling_edge(clk);
    arst_b <= '1';
    for c in 1 to 4 loop
      wait until rising_edge(clk);
      wait for 1 ns;
      check_all("after reset, cycle " & integer'image(c), x"00");
    end loop;

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "Write / hold", C_SCOPE);
    ---------------------------------------------------------------------------
    for v in 0 to 3 loop
      write(std_logic_vector(to_unsigned(16#3C# + 16#41# * v, WIDTH)));
      for c in 1 to 3 loop
        wait until rising_edge(clk);
        wait for 1 ns;
        check_all("hold, cycle " & integer'image(c), std_logic_vector(to_unsigned(16#3C# + 16#41# * v, WIDTH)));
      end loop;
    end loop;
    write(x"FF");
    check_all("write FF", x"FF");
    write(x"00");
    check_all("write 00", x"00");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "Fault injection", C_SCOPE);
    ---------------------------------------------------------------------------
    inject(INJ_BIT0 , x"A5");
    inject(INJ_BIT0 , x"5A");
    inject(INJ_BIT01, x"C3");
    inject(INJ_BIT01, x"3C");
    inject(INJ_TOP  , x"96");
    inject(INJ_TOP  , x"69");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "Reset after a fault", C_SCOPE);
    ---------------------------------------------------------------------------
    inj_kind <= INJ_BIT0;
    inj_en   <= '1';
    write(x"A5");
    inj_en   <= '0';
    arst_b   <= '0';
    wait for 1 ns;
    check_all("reset after fault", x"00");
    arst_b   <= '1';

    clk_ena <= false;
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end architecture sim;
