defmodule ExMinesweeper.Engine.State.Board.Helpers do
  use ExMinesweeper.Types

  import ExMinesweeper.Types.Guards

  @spec _generate_fields(field_x, field_y) :: [field]
  def _generate_fields(x_max, y_max)
      when is_non_neg_integer(x_max) and is_non_neg_integer(y_max) do
    for x <- 0..x_max, y <- 0..y_max, do: %{{x, y} => nil}
  end

end
