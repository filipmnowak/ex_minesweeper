defmodule ExMinesweeper.Engine.State.Board do
  use ExMinesweeper.Engine.State.Board.Access
  use ExMinesweeper.Types

  import ExMinesweeper.Engine.State.Board.Helpers, only: [_generate_fields: 2]

  alias __MODULE__

  defstruct(
    topology: nil,
    dimmensions: nil,
    upper_layer: nil,
    bottom_layer: nil
  )

  def new(x_max, y_max) when x_max == y_max do
    %Board{
      topology: MapSet.new(_generate_fields(x_max, y_max)),
      dimmensions: %{x: x_max, y: y_max}
    }
  end

  def new(_, _) do
    raise(ArgumentError, "x_max and y_max must be equal, non negative integers")
  end

  def mark(board, mark_or_flag, {x, y})
      when mark_or_flag in [:mark, :flag] and is_struct(board, __MODULE__) do
    Access.get_and_update(board, :topology, fn v ->
      {
        v,
        v
        |> MapSet.delete(%{{x, y} => :mark})
        |> MapSet.delete(%{{x, y} => :flag})
        |> MapSet.delete(%{{x, y} => nil})
        |> MapSet.put(%{{x, y} => mark_or_flag})
      }
    end)
    |> elem(1)
  end

  def mark(_, _, _) do
    raise(ArgumentError)
  end
end
