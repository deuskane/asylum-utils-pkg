-------------------------------------------------------------------------------
-- Title      : types_pkg
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : types_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Common types shared by several packages of the library.
--              sbi_pkg and pbi_pkg re-export these types with an alias, so a
--              design using both packages (or types_pkg directly) sees a
--              single type and no ambiguity.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created (naturals_t moved from sbi/pbi_pkg)
-------------------------------------------------------------------------------

package types_pkg is

  type naturals_t is array (natural range <>) of natural;

end package types_pkg;
