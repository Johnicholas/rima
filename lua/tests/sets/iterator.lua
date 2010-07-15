-- Copyright (c) 2009-2010 Incremental IP Limited
-- see LICENSE for license information

local iterator = require("rima.sets.iterator")

local series = require("test.series")
local object = require("rima.lib.object")
local lib = require("rima.lib")
local core = require("rima.core")
--local ref = require("rima.ref")
local scope = require("rima.scope")
require("rima.public")
local rima = rima

module(...)

-- Tests -----------------------------------------------------------------------

function test(options)
  local T = series:new(_M, options)
  
  local function N(...) return iterator:new(...) end
--  local B = core.bind
  local E = rima.E
  local D = lib.dump
  
  -- Constructors
  T:test(iterator:isa(N()), "iterator:isa(iterator:new())")
  T:check_equal(object.type(N()), "iterator", "type(iterator:new()) == 'iterator'")
  
  do
    local it
    T:expect_ok(function() it = N(nil, nil, "key", 13) end)
    T:check_equal(it + 17, 30)
    T:check_equal(7 * it, 91)
    T:check_equal(core.defined(it), true)
  end

  do
    local a = rima.R"a"
    local S = scope.new{ a = N(nil, nil, "key", 13) }
    T:check_equal(E(a + 19, S), 32)
    T:check_equal(D(E(a + 19, S)), 32)
  end
  return T:close()
end

-- EOF -------------------------------------------------------------------------
