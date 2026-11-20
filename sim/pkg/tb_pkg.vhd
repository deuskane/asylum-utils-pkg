-------------------------------------------------------------------------------
-- Title      : tb_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking UVVM testbench of the functions of the
--              packages (logic_pkg, convert_pkg, math_pkg, string_pkg,
--              sbi_pkg, pbi_pkg, types_pkg, ft_pkg on any index range).
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_pkg_tests_pkg) ; "" : build and
--                           elaboration only
--              Functions only : no DUT, no clock and no reset, each scenario
--              uses its own variables.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (merge of tb_logic_pkg, tb_sbi_pkg
--                               and tb_string_pkg : TESTS_LIST, one package
--                               per scenario)
-------------------------------------------------------------------------------

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
-- Every package used together : no ambiguous name between them
use     asylum.convert_pkg.all;
use     asylum.logic_pkg.all;
use     asylum.types_pkg.all;
use     asylum.pbi_pkg.all;
use     asylum.sbi_pkg.all;
use     asylum.string_pkg.all;
use     asylum.ft_pkg.all;

library work;
use     work.tb_pkg_tests_pkg.all;

entity tb_pkg is
  generic (
    TESTS_LIST        : string    := ""        -- Scenarios, e.g. "logic,list"
  );
end entity tb_pkg;

architecture sim of tb_pkg is

  constant C_SCOPE    : string  := "TB_PKG";

begin  -- architecture sim

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
  begin
    log(ID_LOG_HDR, "TESTS_LIST : " & TESTS_LIST, C_SCOPE);

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
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST) loop
      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i));
      wait for 1 ns;
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
