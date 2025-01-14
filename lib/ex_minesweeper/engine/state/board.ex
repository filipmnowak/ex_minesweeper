defmodule ExMinesweeper.Engine.State.Board do
  use ExMinesweeper.Engine.State.Board.Access
  use ExMinesweeper.Types

  import ExMinesweeper.Engine.State.Board.Helpers,
    only: [
      generate_upper_layer_fields: 2,
      generate_bottom_layer_fields: 3
    ]

  alias __MODULE__

  @type t() :: %__MODULE__{
          dimmensions: %{
            x: field_x(),
            y: field_y()
          },
          upper_layer: upper_layer(),
          bottom_layer: bottom_layer()
        }

  @enforce_keys [:dimmensions, :upper_layer, :bottom_layer]
  defstruct(
    dimmensions: nil,
    upper_layer: nil,
    bottom_layer: nil
  )

  def new(x_max, y_max, mine_chance) when x_max == y_max do
    %Board{
      upper_layer: MapSet.new(generate_upper_layer_fields(x_max, y_max)),
      bottom_layer: MapSet.new(generate_bottom_layer_fields(x_max, y_max, mine_chance)),
      dimmensions: %{x: x_max, y: y_max}
    }
  end

  def new(_, _) do
    raise(ArgumentError, "x_max and y_max must be equal, non negative integers")
  end

  @spec mark(Board.t(), :uncover | :flag, {field_x(), field_y()}) :: Board.t()
  def mark(board, uncover_or_flag, {x, y})
      when uncover_or_flag in [:uncover, :flag] and is_struct(board, __MODULE__) do
    Access.get_and_update(board, :upper_layer, fn v ->
      {
        v,
        v
        |> MapSet.delete({x, y, :covered})
        |> MapSet.delete({x, y, :flag})
        |> MapSet.delete({x, y, :flagged})
        |> MapSet.delete({x, y, :uncover})
        |> MapSet.delete({x, y, :clean})
        |> MapSet.delete({x, y, :mine})
        |> MapSet.delete({x, y, :explosion})
        |> MapSet.put({x, y, uncover_or_flag})
      }
    end)
    |> elem(1)
  end

  def mark(_, _, _) do
    raise(ArgumentError)
  end
end
