defmodule ExMinesweeper.Engine.State.Board.Helpers do
  use ExMinesweeper.Types

  import ExMinesweeper.Types.Guards

  @type roll :: 0..100
  @type mine_chance :: 0..100

  defp random_between_0_and_100() do
    Enum.random(0..100)
  end

  def _clean_or_mine(mine_chance, roll \\ &random_between_0_and_100/0)

  def _clean_or_mine(mine_chance, roll)
      when is_integer(mine_chance) and
             is_integer(roll) and
             mine_chance in 0..100 and
             roll in 0..100 and
             mine_chance > roll do
    :clean
  end

  def _clean_or_mine(mine_chance, roll)
      when is_integer(mine_chance) and
             is_integer(roll) and
             mine_chance in 0..100 and
             roll in 0..100 and
             mine_chance <= roll do
    :mine
  end

  @spec _generate_upper_layer_fields(field_x(), field_y()) :: [upper_layer_field()]
  def _generate_upper_layer_fields(x_max, y_max)
      when is_non_neg_integer(x_max) and is_non_neg_integer(y_max) do
    for x <- 0..x_max, y <- 0..y_max, do: %{{x, y} => :covered}
  end

  @spec _generate_bottom_layer_fields(field_x, field_y, roll()) :: [bottom_layer_field()]
  def _generate_bottom_layer_fields(x_max, y_max, mine_chance)
      when is_non_neg_integer(x_max) and is_non_neg_integer(y_max) do
    for x <- 0..x_max, y <- 0..y_max, do: %{{x, y} => _clean_or_mine(mine_chance)}
  end
end
