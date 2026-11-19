-------------------------------------------------------------------------------
-- Title      : string_pkg
-- Project    : 
-------------------------------------------------------------------------------
-- Description: Collection of string function
-------------------------------------------------------------------------------
-- Copyright (c) 2025 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-03-19  1.0      mrosiere Created
-- 2026-07-29  1.1      mrosiere Add function to_string for std_logic
-- 2026-11-19  1.2      mrosiere Add list_length, list_item and list_contains
--                              (list of items separated by a character, e.g.
--                              TESTS_LIST)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package string_pkg is

  function string_eq (str1 : string; str2 : string) return boolean; 
  function string_ne (str1 : string; str2 : string) return boolean; 
  -- In VHDL-2008, std_logic_1164 implicitly declares TO_STRING for
  -- std_ulogic and std_ulogic_vector. These explicit homographs hide them
  -- where string_pkg is used (LRM 2008 12.4, no ambiguity), so they return
  -- the same format : one character per bit, without quotes.
  -- They are kept for VHDL-93 users and backward compatibility.
  function to_string ( a: std_logic_vector) return string;
  function to_string ( a: std_logic       ) return string;  

  -- List of items separated by sep, e.g. "reset,read,read" (no space) :
  -- list_length returns the number of items ("" : 0, "a" : 1, "a,b" : 2, "a," : 2),
  -- list_item returns the item index (1 to list_length), an empty string for an
  -- empty item. An index out of the list is a failure.
  -- list_contains is true when one item of the list is item (compared with string_eq).
  function list_length   (str : string; sep : character := ','                    ) return natural;
  function list_item     (str : string; index : positive; sep : character := ',') return string;
  function list_contains (str : string; item : string; sep : character := ','   ) return boolean;
end string_pkg;

package body string_pkg is

  function string_eq(str1 : string; str2 : string) return boolean is
    -- Compare by position : the strings may have different index ranges
    alias s1 : string(1 to str1'length) is str1;
    alias s2 : string(1 to str2'length) is str2;
  begin
    if str1'length /= str2'length then
      return false;
    else
      for i in s1'range loop
        if s1(i) /= s2(i) then
          return false;
        end if;
      end loop;
      return true;
    end if;
  end function;

  function string_ne(str1 : string; str2 : string) return boolean is
    -- Compare by position : the strings may have different index ranges
    alias s1 : string(1 to str1'length) is str1;
    alias s2 : string(1 to str2'length) is str2;
  begin
    if str1'length /= str2'length then
      return true;
    else
      for i in s1'range loop
        if s1(i) /= s2(i) then
          return true;
        end if;
      end loop;
      return false;
    end if;
  end function;

  function to_string ( a: std_logic_vector) return string is
    variable b : string (1 to a'length) := (others => NUL);
    variable stri : integer := 1; 
  begin
    for i in a'range loop
      b(stri) := std_logic'image(a((i)))(2);
      stri := stri+1;
    end loop;
    return b;
  end function;

  function to_string ( a: std_logic) return string is
    variable b : string (1 to 1);
  begin
    -- std_logic'image returns the literal with its quotes ('1')
    b(1) := std_logic'image(a)(2);
    return b;
  end function;

  function list_length (str : string; sep : character := ',') return natural is
    variable n : natural := 1;
  begin
    if str'length = 0 then
      return 0;
    end if;
    for i in str'range loop
      if str(i) = sep then
        n := n+1;
      end if;
    end loop;
    return n;
  end function;

  function list_item (str : string; index : positive; sep : character := ',') return string is
    -- Work on 1 to length : str may be a slice with another index range
    alias    s     : string(1 to str'length) is str;
    variable item  : positive := 1; -- item of the current character
    variable first : positive := 1; -- first character of the current item
  begin
    assert index <= list_length(str, sep)
      report "list_item : item " & integer'image(index) & " of a list of " &
             integer'image(list_length(str, sep)) & " items : " & str
      severity failure;
    for i in s'range loop
      if s(i) = sep then
        if item = index then
          return s(first to i-1);
        end if;
        item  := item+1;
        first := i+1;
      end if;
    end loop;
    -- Last item (after the last separator)
    return s(first to s'length);
  end function;

  function list_contains (str : string; item : string; sep : character := ',') return boolean is
  begin
    for i in 1 to list_length(str, sep) loop
      if string_eq(list_item(str, i, sep), item) then
        return true;
      end if;
    end loop;
    return false;
  end function;
 
end string_pkg;
