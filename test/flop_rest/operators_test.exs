defmodule FlopRest.OperatorsTest do
  use ExUnit.Case, async: true

  alias FlopRest.Operators

  doctest Operators

  describe "to_flop/1" do
    test "converts comparison operators" do
      assert "==" = Operators.to_flop("eq")
      assert "!=" = Operators.to_flop("ne")
      assert "<" = Operators.to_flop("lt")
      assert "<=" = Operators.to_flop("lte")
      assert ">" = Operators.to_flop("gt")
      assert ">=" = Operators.to_flop("gte")
    end

    test "converts search operator" do
      assert "=~" = Operators.to_flop("search")
    end

    test "converts empty operators" do
      assert "empty" = Operators.to_flop("empty")
      assert "not_empty" = Operators.to_flop("not_empty")
    end

    test "converts in operators" do
      assert "in" = Operators.to_flop("in")
      assert "not_in" = Operators.to_flop("not_in")
    end

    test "converts contains operators" do
      assert "contains" = Operators.to_flop("contains")
      assert "not_contains" = Operators.to_flop("not_contains")
    end

    test "converts like operators" do
      assert "like" = Operators.to_flop("like")
      assert "not_like" = Operators.to_flop("not_like")
      assert "like_and" = Operators.to_flop("like_and")
      assert "like_or" = Operators.to_flop("like_or")
    end

    test "converts ilike operators" do
      assert "ilike" = Operators.to_flop("ilike")
      assert "not_ilike" = Operators.to_flop("not_ilike")
      assert "ilike_and" = Operators.to_flop("ilike_and")
      assert "ilike_or" = Operators.to_flop("ilike_or")
    end

    test "passes through unknown operators verbatim" do
      assert "unknown" = Operators.to_flop("unknown")
      assert "foo_bar" = Operators.to_flop("foo_bar")
    end
  end

  describe "to_rest/1" do
    test "returns nil for equality operator" do
      assert nil == Operators.to_rest(:==)
    end

    test "converts comparison operators" do
      assert "ne" = Operators.to_rest(:!=)
      assert "lt" = Operators.to_rest(:<)
      assert "lte" = Operators.to_rest(:<=)
      assert "gt" = Operators.to_rest(:>)
      assert "gte" = Operators.to_rest(:>=)
    end

    test "converts search operator" do
      assert "search" = Operators.to_rest(:=~)
    end

    test "converts empty operators" do
      assert "empty" = Operators.to_rest(:empty)
      assert "not_empty" = Operators.to_rest(:not_empty)
    end

    test "converts in operators" do
      assert "in" = Operators.to_rest(:in)
      assert "not_in" = Operators.to_rest(:not_in)
    end

    test "converts contains operators" do
      assert "contains" = Operators.to_rest(:contains)
      assert "not_contains" = Operators.to_rest(:not_contains)
    end

    test "converts like operators" do
      assert "like" = Operators.to_rest(:like)
      assert "not_like" = Operators.to_rest(:not_like)
      assert "like_and" = Operators.to_rest(:like_and)
      assert "like_or" = Operators.to_rest(:like_or)
    end

    test "converts ilike operators" do
      assert "ilike" = Operators.to_rest(:ilike)
      assert "not_ilike" = Operators.to_rest(:not_ilike)
      assert "ilike_and" = Operators.to_rest(:ilike_and)
      assert "ilike_or" = Operators.to_rest(:ilike_or)
    end

    test "passes through unknown operators as strings" do
      assert "unknown" = Operators.to_rest(:unknown)
      assert "foo_bar" = Operators.to_rest(:foo_bar)
    end
  end
end
