-------------------------------------------------------------------------------
-- Title      : tb_pkg_list_pkg
-- Project    : asylum-utils-pkg
-------------------------------------------------------------------------------
-- File       : tb_pkg_list_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario list of tb_pkg : list_length, list_item,
--              list_contains of string_pkg (the TESTS_LIST parser of every
--              Asylum testbench) : empty list, one item, several items, empty
--              items, trailing separator, other separator, list given as a
--              slice with another index range
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (from tb_string_pkg)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_pkg_bfm_pkg.all;

package tb_pkg_list_pkg is

  -- List functions of string_pkg
  procedure run;

end package tb_pkg_list_pkg;

package body tb_pkg_list_pkg is

  -- Check one item : value and length (an empty item has the length 0)
  procedure check_item(str : string; index : positive; exp : string; sep : character := ',') is
  begin
    check_value(list_item(str, index, sep)'length, exp'length, ERROR,
                "list_item(""" & str & """, " & integer'image(index) & ") length", C_TB_SCOPE);
    check_value(string_eq(list_item(str, index, sep), exp), true, ERROR,
                "list_item(""" & str & """, " & integer'image(index) & ") = """ & exp & """", C_TB_SCOPE);
  end procedure;

  procedure run is
    -- List as a slice of a string indexed 5 to 15 (not 1 to length)
    variable v_slice : string(5 to 15) := "xxreset,ack";
  begin
    log(ID_SEQUENCER, "list_length", C_TB_SCOPE);
    check_value(list_length(""               ), 0, ERROR, "list_length("""")"               , C_TB_SCOPE);
    check_value(list_length("reset"          ), 1, ERROR, "list_length(""reset"")"          , C_TB_SCOPE);
    check_value(list_length("reset,read"     ), 2, ERROR, "list_length(""reset,read"")"     , C_TB_SCOPE);
    check_value(list_length("reset,read,read"), 3, ERROR, "list_length(""reset,read,read"")", C_TB_SCOPE);
    check_value(list_length("a,"             ), 2, ERROR, "list_length(""a,"") : trailing separator", C_TB_SCOPE);
    check_value(list_length(","              ), 2, ERROR, "list_length("","")"              , C_TB_SCOPE);
    check_value(list_length("a,,b"           ), 3, ERROR, "list_length(""a,,b"") : empty item", C_TB_SCOPE);
    check_value(list_length("a;b;c", ';'     ), 3, ERROR, "list_length(""a;b;c"", ';')"     , C_TB_SCOPE);
    check_value(list_length("a,b"  , ';'     ), 1, ERROR, "list_length(""a,b"", ';') : other separator", C_TB_SCOPE);

    log(ID_SEQUENCER, "list_item", C_TB_SCOPE);
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

    log(ID_SEQUENCER, "list_contains", C_TB_SCOPE);
    check_value(list_contains("reset,read,rw1c", "read" ), true , ERROR, "list_contains : middle item"               , C_TB_SCOPE);
    check_value(list_contains("reset,read,rw1c", "rw1c" ), true , ERROR, "list_contains : last item"                 , C_TB_SCOPE);
    check_value(list_contains("reset,read,rw1c", "reset"), true , ERROR, "list_contains : first item"                , C_TB_SCOPE);
    check_value(list_contains("reset,read,rw1c", "rea"  ), false, ERROR, "list_contains : prefix of an item"         , C_TB_SCOPE);
    check_value(list_contains("reset,read,rw1c", "reads"), false, ERROR, "list_contains : longer than an item"       , C_TB_SCOPE);
    check_value(list_contains("reset,read,rw1c", ""     ), false, ERROR, "list_contains : empty name, no empty item" , C_TB_SCOPE);
    check_value(list_contains("a,,b"           , ""     ), true , ERROR, "list_contains : empty item"                , C_TB_SCOPE);
    check_value(list_contains(""               , "a"    ), false, ERROR, "list_contains : empty list"                , C_TB_SCOPE);
    check_value(list_contains("a;b"            , "b", ';'), true, ERROR, "list_contains : other separator"           , C_TB_SCOPE);

    log(ID_SEQUENCER, "List given as a slice (index range 7 to 15)", C_TB_SCOPE);
    check_value(list_length(v_slice(7 to 15)), 2, ERROR, "list_length of a slice", C_TB_SCOPE);
    check_item (v_slice(7 to 15), 1, "reset");
    check_item (v_slice(7 to 15), 2, "ack"  );
    check_value(list_contains(v_slice(7 to 15), "ack"), true, ERROR, "list_contains on a slice", C_TB_SCOPE);
  end procedure;

end package body tb_pkg_list_pkg;
