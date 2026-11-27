-------------------------------------------------------------------------------
-- Title      : tb_pkg_tests_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_tests_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_pkg : names (valid items of TESTS_LIST) and
--              dispatch (run_test) to the package of each scenario
--              (tb_pkg_<name>_pkg)
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (split of tb_logic_pkg,
--                               tb_sbi_pkg and tb_string_pkg)
-------------------------------------------------------------------------------

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "logic,convert,math,string,list,sbi,pbi,ft_ranges,gray";

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    );

end package tb_pkg_tests_pkg;

package body tb_pkg_tests_pkg is

  procedure run_test
    (constant name     : in    string
    ) is
  begin
    if    string_eq(name, "logic")
    then
      work.tb_pkg_logic_pkg.run;
    elsif string_eq(name, "convert")
    then
      work.tb_pkg_convert_pkg.run;
    elsif string_eq(name, "math")
    then
      work.tb_pkg_math_pkg.run;
    elsif string_eq(name, "gray")
    then
      work.tb_pkg_gray_pkg.run;
    elsif string_eq(name, "string")
    then
      work.tb_pkg_string_pkg.run;
    elsif string_eq(name, "list")
    then
      work.tb_pkg_list_pkg.run;
    elsif string_eq(name, "sbi")
    then
      work.tb_pkg_sbi_pkg.run;
    elsif string_eq(name, "pbi")
    then
      work.tb_pkg_pbi_pkg.run;
    elsif string_eq(name, "ft_ranges")
    then
      work.tb_pkg_ft_ranges_pkg.run;
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_pkg_tests_pkg;
