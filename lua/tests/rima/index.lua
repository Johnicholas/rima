-- Copyright (c) 2009-2012 Incremental IP Limited
-- see LICENSE for license information

local index = require("rima.index")

local object = require("rima.lib.object")
local interface = require("rima.interface")


------------------------------------------------------------------------------

return function(T)
  local N = interface.new_index
  local S = interface.set_index
  local R = interface.R
  local E = interface.eval

  -- constructors
  T:test(object.typeinfo(index:new()).index, "typeinfo(index:new()).index")
  T:test(object.typename(index:new(), "index"), "typename(index:new())=='index'")
--  T:expect_error(function() N(B, 1) end, "the first element of this index must be an identifier string")
  T:expect_ok(function() N({}, 1) end)

  -- identifiers
--  T:test(index.is_identifier(N(R, "a")))
--  T:test(not index.is_identifier(N(R, "a", "b")))
--  T:test(not index.is_identifier(N({}, "a")))

  -- indexing
  T:check_equal(N(nil, "a", "b"), "a.b")
  T:check_equal(N(nil, "a", 1), "a[1]")

  -- resolving
  T:check_equal(E(N({a=1}, "a")), 1)
  T:check_equal(E(N(nil, "a"), {a=3}), 3)

  -- setting
  do
    local S = {}
    local I = N(S)
    T:expect_ok(function() I.a = 1 end)
    T:check_equal(E(I.a), 1)
    T:check_equal(E(N(nil, "a"), S), 1)
    T:expect_ok(function() I.b.c.d = 3 end)
    T:check_equal(E(I.b.c.d), 3)
    T:check_equal(E(N().b.c.d, S), 3)
    T:check_equal(E(N().f.g.h, S), "f.g.h")

    local I2 = {a=5, b={c={d=7}}}
    T:check_equal(E(N(I2).a, S), 5)
    T:check_equal(E(N(I2).b.c.d, S), 7)

    T:expect_error(function() N().a.b = 1 end, "%L: error setting 'a.b' to '1': 'a.b' isn't bound to a table or scope")
  
    -- errors
    T:expect_error(function() local dummy = E(I.a.b) end, "%L: error indexing 'a' as 'a%.b': can't index a number")
    T:expect_error(function() I.a.b = 1 end, "%L: error indexing 'a' as 'a%.b': can't index a number")
    T:expect_error(function() I.a.b.c = 1 end, "%L: error indexing 'a%' as 'a%.b%': can't index a number")
  end

  -- variable indexes
  local I3 = { a={b=5} }
  local i = N().i
  T:check_equal(N().a, "a")
  T:check_equal(N().a.b, "a.b")
  T:check_equal(N().a[i], "a[i]")
  T:check_equal(E(N().a[i], I3), "a[i]")
  I3.i = "b"
  T:check_equal(E(N().a[i], I3), 5)

  -- table assign
  local t = {}
  local I = N(t)
  T:expect_ok(function() I.a = { x=1, y=2 } end)
  T:check_equal(t.a.x, 1)
  T:check_equal(t.a.y, 2)
  
  -- set
  local t = {}
  local I = N()
  T:expect_ok(function() S(I.b, t, 7) end)
  T:expect_ok(function() S(I.a, t, { x=1, y=2 }) end)
  T:check_equal(t.b, 7)
  T:check_equal(t.a.x, 1)
  T:check_equal(t.a.y, 2)

  -- references to indexes
  local t = { a={b=N().c.d}, c={d={e=N().f.g}}, f={g={h=N().i.j}} }
  T:check_equal(E(N().a.b.z, t), "c.d.z")
  T:check_equal(E(N().a.b.e.z, t), "f.g.z")
  T:check_equal(E(N().a.b.e.h, t), "i.j")
  T:check_equal(E(N().a.b.e.h.k, t), "i.j.k")
  t.i = {j={k=7}}
  T:check_equal(E(N().a.b.e.h.k, t), 7)

  -- index introspection
  local list = {}
  local i = N(nil, "a", 1, "b")
  index.__list_variables(i, {}, list)
  T:check_equal(list["a[1].b"].ref, "a[1].b")
end


------------------------------------------------------------------------------

