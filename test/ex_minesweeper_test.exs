defmodule ExMinesweeperTest do
  use ExUnit.Case
  doctest ExMinesweeper

  test "greets the world" do
    assert ExMinesweeper.hello() == :world
  end
end
