-------------------------------------------------------------------------------
-- Title      : tb_ft_bfm_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_ft_bfm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_ft scenarios : reference model of the
--              fault-tolerance codes (sizes, encoded word, decoder output
--              after bit flips), data patterns, checks, reset pulse.
--              The model is written from the definition of each code,
--              independently from ft_pkg.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_ft_* and tb_ft_dff)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.ft_pkg.all;

package tb_ft_bfm_pkg is

  constant C_TB_SCOPE : string := "TB_FT";
  constant C_PERIOD   : time   := 10 ns;

  -- SELF_REFRESH of the two ft_dff of the testbench
  constant C_REFRESH  : boolean_vector(0 to 1) := (false, true);

  -- Data word of the codec scenarios (bit i = bit i mod 32 of the seed) :
  -- "1010" with 4 bits, 0xC3A5965A with 32 bits
  constant C_SEED     : std_logic_vector(32-1 downto 0) := x"C3A5965A";

  -- Expected output of a decoder
  type expect_t is record
    det             : std_logic;          -- error_detected
    cor             : std_logic;          -- error_corrected
    data            : std_logic_vector;   -- decoded data
    chkdata         : boolean;            -- false : data not checked
  end record expect_t;

  -- Word of width bits : the seed repeated (bit i = seed(i mod seed'length))
  function pattern
    (constant seed     : in    std_logic_vector
    ;constant width    : in    natural
    ) return std_logic_vector;

  -- Number of bits at '1'
  function nb_ones
    (constant v        : in    std_logic_vector
    ) return natural;

  -- Size of the encoded word of n data bits :
  --   NONE n, PARITY_* n+1, TMR 3n, ECC n+r+1 (smallest r with 2**r >= n+r+1)
  function ref_size
    (constant n        : in    natural
    ;constant algo     : in    ft_algo_t
    ) return natural;

  -- Encoded word of d :
  --   NONE d, PARITY_* parity & d, TMR d & d & d, ECC extended Hamming :
  --   bit 0 = parity of the whole word, bit 2**k = Hamming parity k,
  --   data bits in order at the other positions
  function ref_encode
    (constant d        : in    std_logic_vector
    ;constant algo     : in    ft_algo_t
    ) return std_logic_vector;

  -- Decoder output for the encoded word of d with the bits of mask flipped
  impure function expect_flips
    (constant algo     : in    ft_algo_t
    ;constant d        : in    std_logic_vector
    ;constant mask     : in    std_logic_vector
    ) return expect_t;

  -- Expected output without error
  function expect_ok
    (constant d        : in    std_logic_vector
    ) return expect_t;

  -- Check of a decoder output
  procedure check_dec
    (constant msg      : in    string
    ;constant e        : in    expect_t
    ;constant data     : in    std_logic_vector
    ;constant det      : in    std_logic
    ;constant cor      : in    std_logic
    );

  -- Reset pulse, released on a falling edge
  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    );

end package tb_ft_bfm_pkg;

package body tb_ft_bfm_pkg is

  function pattern
    (constant seed     : in    std_logic_vector
    ;constant width    : in    natural
    ) return std_logic_vector is
    alias    s         : std_logic_vector(seed'length-1 downto 0) is seed;
    variable v         : std_logic_vector(width-1 downto 0);
  begin
    for i in v'range loop
      v(i) := s(i mod s'length);
    end loop;
    return v;
  end function;

  function nb_ones
    (constant v        : in    std_logic_vector
    ) return natural is
    variable n         : natural := 0;
  begin
    for i in v'range loop
      if v(i) = '1'
      then
        n := n + 1;
      end if;
    end loop;
    return n;
  end function;

  function ref_size
    (constant n        : in    natural
    ;constant algo     : in    ft_algo_t
    ) return natural is
    variable r         : natural := 0;
  begin
    case algo is
      when USE_NONE                         => return n;
      when USE_PARITY_ODD | USE_PARITY_EVEN => return n + 1;
      when USE_TMR                          => return 3 * n;
      when USE_ECC                          =>
        if n = 0
        then
          return 0;
        end if;
        while 2**r < n + r + 1 loop
          r := r + 1;
        end loop;
        return n + r + 1;
    end case;
  end function;

  function ref_encode
    (constant d        : in    std_logic_vector
    ;constant algo     : in    ft_algo_t
    ) return std_logic_vector is
    alias    dd        : std_logic_vector(d'length-1 downto 0) is d;
    constant N         : natural := ref_size(d'length, algo);
    variable e         : std_logic_vector(N-1 downto 0) := (others => '0');
    variable j         : natural := 0;
    variable p         : natural := 1;
  begin
    case algo is
      when USE_NONE        => e := dd;
      when USE_PARITY_ODD  => e := not (xor dd) & dd;
      when USE_PARITY_EVEN => e :=     (xor dd) & dd;
      when USE_TMR         => e := dd & dd & dd;
      when USE_ECC         =>
        -- Data bits at the positions that are not a power of 2
        for i in 3 to N-1 loop
          if nb_ones(std_logic_vector(to_unsigned(i, 32))) /= 1
          then
            e(i) := dd(j);
            j    := j + 1;
          end if;
        end loop;
        -- Hamming parity p : even parity of the positions i with (i and p) /= 0
        while p < N loop
          for i in p+1 to N-1 loop
            if (i / p) mod 2 = 1
            then
              e(p) := e(p) xor e(i);
            end if;
          end loop;
          p := 2 * p;
        end loop;
        -- Global parity : even parity of the whole word
        if N > 0
        then
          e(0) := xor e(N-1 downto 1);
        end if;
    end case;
    return e;
  end function;

  impure function expect_flips
    (constant algo     : in    ft_algo_t
    ;constant d        : in    std_logic_vector
    ;constant mask     : in    std_logic_vector
    ) return expect_t is
    constant W         : natural := d'length;
    alias    dd        : std_logic_vector(W-1 downto 0) is d;
    alias    m         : std_logic_vector(mask'length-1 downto 0) is mask;
    variable e         : expect_t(data(W-1 downto 0));
    variable c         : natural;
  begin
    e := (det => '0', cor => '0', data => dd, chkdata => true);
    case algo is
      when USE_NONE                         =>
        -- No redundancy : the flips reach the data, nothing detected
        e.data := dd xor m(W-1 downto 0);
      when USE_PARITY_ODD | USE_PARITY_EVEN =>
        -- An odd number of flips is detected, never corrected
        e.data := dd xor m(W-1 downto 0);
        if nb_ones(m) mod 2 = 1
        then
          e.det := '1';
        end if;
      when USE_TMR                          =>
        -- Bit i : majority of the 3 copies, wrong when 2 or 3 copies flipped,
        -- a difference between the copies (1 or 2 flipped) is detected
        for i in 0 to W-1 loop
          c := nb_ones(m(2*W+i) & m(W+i) & m(i));
          if c >= 2
          then
            e.data(i) := not dd(i);
          end if;
          if c = 1 or c = 2
          then
            e.det := '1';
            e.cor := '1';
          end if;
        end loop;
      when USE_ECC                          =>
        -- SEC-DED : one flip corrected, two flips detected (data not
        -- defined), more flips not modelled
        case nb_ones(m) is
          when 0      => null;
          when 1      => e.det := '1'; e.cor := '1';
          when 2      => e.det := '1'; e.chkdata := false;
          when others => alert(TB_ERROR, "expect_flips : more than 2 flips with USE_ECC", C_TB_SCOPE);
        end case;
    end case;
    return e;
  end function;

  function expect_ok
    (constant d        : in    std_logic_vector
    ) return expect_t is
  begin
    return (det => '0', cor => '0', data => d, chkdata => true);
  end function;

  procedure check_dec
    (constant msg      : in    string
    ;constant e        : in    expect_t
    ;constant data     : in    std_logic_vector
    ;constant det      : in    std_logic
    ;constant cor      : in    std_logic
    ) is
  begin
    if e.chkdata
    then
      check_value(data, e.data, ERROR, msg & " : data"           , C_TB_SCOPE);
    end if;
    check_value(det , e.det , ERROR, msg & " : error_detected" , C_TB_SCOPE);
    check_value(cor , e.cor , ERROR, msg & " : error_corrected", C_TB_SCOPE);
  end procedure;

  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ) is
  begin
    arst_b <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    arst_b <= '1';
  end procedure;

end package body tb_ft_bfm_pkg;
