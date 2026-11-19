-------------------------------------------------------------------------------
-- Title      : tb_string_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_string_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking testbench of the list functions of string_pkg
--              (list_length, list_item, list_contains) : empty list, one item,
--              several items, empty items, trailing separator, other separator,
--              list given as a slice with another index range, item compared
--              with string_eq.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-19  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;

entity tb_string_pkg is
end entity tb_string_pkg;

architecture sim of tb_string_pkg is

  constant C_SCOPE : string := "TB_STRING_PKG";

  -- Check one item : value and length (an empty item has the length 0)
  procedure check_item(str : string; index : positive; exp : string; sep : character := ',') is
  begin
    check_value(list_item(str, index, sep)'length, exp'length, ERROR,
                "list_item(""" & str & """, " & integer'image(index) & ") length");
    check_value(string_eq(list_item(str, index, sep), exp), true, ERROR,
                "list_item(""" & str & """, " & integer'image(index) & ") = """ & exp & """");
  end procedure;

begin

  p_main : process
    -- List as a slice of a string indexed 5 to 15 (not 1 to length)
    variable v_slice : string(5 to 15) := "xxreset,ack";
  begin
    log(ID_LOG_HDR, "START: string_pkg list functions", C_SCOPE);

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "list_length", C_SCOPE);
    ---------------------------------------------------------------------------
    check_value(list_length(""               ), 0, ERROR, "list_length("""")");
    check_value(list_length("reset"          ), 1, ERROR, "list_length(""reset"")");
    check_value(list_length("reset,read"     ), 2, ERROR, "list_length(""reset,read"")");
    check_value(list_length("reset,read,read"), 3, ERROR, "list_length(""reset,read,read"")");
    check_value(list_length("a,"             ), 2, ERROR, "list_length(""a,"") : trailing separator");
    check_value(list_length(","              ), 2, ERROR, "list_length("","")");
    check_value(list_length("a,,b"           ), 3, ERROR, "list_length(""a,,b"") : empty item");
    check_value(list_length("a;b;c", ';'     ), 3, ERROR, "list_length(""a;b;c"", ';')");
    check_value(list_length("a,b"  , ';'     ), 1, ERROR, "list_length(""a,b"", ';') : other separator");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "list_item", C_SCOPE);
    ---------------------------------------------------------------------------
    check_item("reset"          , 1, "reset");
    check_item("reset,read,read", 1, "reset");
    check_item("reset,read,read", 2, "read" );
    check_item("reset,read,read", 3, "read" );
    check_item("a,,b"           , 1, "a"    );
    check_item("a,,b"           , 2, ""     );
    check_item("a,,b"           , 3, "b"    );
    check_item("a,"             , 2, ""     );
    check_item(","              , 1, ""     );
    check_item("a;bb;ccc"       , 2, "bb"   , ';');
    check_item("a;bb;ccc"       , 3, "ccc"  , ';');

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "list_contains", C_SCOPE);
    ---------------------------------------------------------------------------
    check_value(list_contains("reset,read,rw1c", "read" ), true , ERROR, "list_contains : middle item");
    check_value(list_contains("reset,read,rw1c", "rw1c" ), true , ERROR, "list_contains : last item");
    check_value(list_contains("reset,read,rw1c", "reset"), true , ERROR, "list_contains : first item");
    check_value(list_contains("reset,read,rw1c", "rea"  ), false, ERROR, "list_contains : prefix of an item");
    check_value(list_contains("reset,read,rw1c", "reads"), false, ERROR, "list_contains : longer than an item");
    check_value(list_contains("reset,read,rw1c", ""     ), false, ERROR, "list_contains : empty name, no empty item");
    check_value(list_contains("a,,b"           , ""     ), true , ERROR, "list_contains : empty item");
    check_value(list_contains(""               , "a"    ), false, ERROR, "list_contains : empty list");
    check_value(list_contains("a;b"            , "b", ';'), true, ERROR, "list_contains : other separator");

    ---------------------------------------------------------------------------
    log(ID_LOG_HDR, "List given as a slice (index range 7 to 15)", C_SCOPE);
    ---------------------------------------------------------------------------
    check_value(list_length(v_slice(7 to 15)), 2, ERROR, "list_length of a slice");
    check_item (v_slice(7 to 15), 1, "reset");
    check_item (v_slice(7 to 15), 2, "ack"  );
    check_value(list_contains(v_slice(7 to 15), "ack"), true, ERROR, "list_contains on a slice");

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end architecture sim;
