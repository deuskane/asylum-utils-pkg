-------------------------------------------------------------------------------
-- Title      : tb_pkg_gray_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_gray_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario gray of tb_pkg : bin2gray / gray2bin of gray_pkg,
--              known values, every value of 1 to 8 bits (gray2bin of
--              bin2gray gives the value back, one bit changes from a value to
--              the next one, also from the largest back to 0, all codes
--              distinct), ascending range of the argument
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-27  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.gray_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_gray_pkg is

  procedure run;

end package tb_pkg_gray_pkg;

package body tb_pkg_gray_pkg is

  -- Number of bits at 1
  function ones(v : std_logic_vector) return natural is
    variable n : natural := 0;
  begin
    for i in v'range
    loop
      if v(i) = '1'
      then
        n := n + 1;
      end if;
    end loop;
    return n;
  end function ones;

  procedure run is
    variable v_asc  : std_logic_vector(0 to 3);
  begin
    log(ID_SEQUENCER, "Known values", C_TB_SCOPE);
    check_value(bin2gray("0000"), "0000", ERROR, "bin2gray(0)" , C_TB_SCOPE);
    check_value(bin2gray("0001"), "0001", ERROR, "bin2gray(1)" , C_TB_SCOPE);
    check_value(bin2gray("0010"), "0011", ERROR, "bin2gray(2)" , C_TB_SCOPE);
    check_value(bin2gray("0011"), "0010", ERROR, "bin2gray(3)" , C_TB_SCOPE);
    check_value(bin2gray("0110"), "0101", ERROR, "bin2gray(6)" , C_TB_SCOPE);
    check_value(bin2gray("1111"), "1000", ERROR, "bin2gray(15)", C_TB_SCOPE);
    check_value(gray2bin("1000"), "1111", ERROR, "gray2bin(8)" , C_TB_SCOPE);
    check_value(gray2bin("0101"), "0110", ERROR, "gray2bin(5)" , C_TB_SCOPE);
    check_value(bin2gray("1")   , "1"   , ERROR, "bin2gray, 1 bit", C_TB_SCOPE);
    check_value(gray2bin("1")   , "1"   , ERROR, "gray2bin, 1 bit", C_TB_SCOPE);

    log(ID_SEQUENCER, "Every value of 1 to 8 bits", C_TB_SCOPE);
    for w in 1 to 8
    loop
      for n in 0 to 2**w-1
      loop
        check_value(gray2bin(bin2gray(std_logic_vector(to_unsigned(n, w)))), std_logic_vector(to_unsigned(n, w)), ERROR,
                    "gray2bin(bin2gray(" & to_string(n) & ")), " & to_string(w) & " bits", C_TB_SCOPE);
        check_value(ones(bin2gray(std_logic_vector(to_unsigned(n, w))) xor bin2gray(std_logic_vector(to_unsigned((n+1) mod 2**w, w)))), 1, ERROR,
                    "one bit changes from " & to_string(n) & " to the next value, " & to_string(w) & " bits", C_TB_SCOPE);
        for m in 0 to n-1
        loop
          if bin2gray(std_logic_vector(to_unsigned(n, w))) = bin2gray(std_logic_vector(to_unsigned(m, w)))
          then
            alert(ERROR, "Same Gray code for " & to_string(m) & " and " & to_string(n) & ", " & to_string(w) & " bits", C_TB_SCOPE);
          end if;
        end loop;
      end loop;
    end loop;

    log(ID_SEQUENCER, "Ascending range of the argument", C_TB_SCOPE);
    v_asc := "0110";
    check_value(bin2gray(v_asc), "0101", ERROR, "bin2gray of a (0 to 3) vector", C_TB_SCOPE);
    v_asc := "0101";
    check_value(gray2bin(v_asc), "0110", ERROR, "gray2bin of a (0 to 3) vector", C_TB_SCOPE);
  end procedure;

end package body tb_pkg_gray_pkg;
