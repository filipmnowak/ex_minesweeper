defmodule ExMinesweeper.Engine.State.Board.Helpers do
  use ExMinesweeper.Types

  import ExMinesweeper.Types.Guards

  @type roll :: 0..100
  @type mine_chance :: 0..100

  @spec clean_or_mine(mine_chance(), roll()) :: :clean | :mine
  def clean_or_mine(mine_chance, roll \\ Enum.random(0..100))

  def clean_or_mine(mine_chance, roll)
      when is_integer(mine_chance) and
             is_integer(roll) and
             mine_chance in 0..100 and
             roll in 0..100 and
             roll > mine_chance do
    :clean
  end

  def clean_or_mine(mine_chance, roll)
      when is_integer(mine_chance) and
             is_integer(roll) and
             mine_chance in 0..100 and
             roll in 0..100 and
             roll <= mine_chance do
    :mine
  end

  @spec generate_upper_layer_fields(field_x(), field_y()) :: [upper_layer_field()]
  def generate_upper_layer_fields(x_max, y_max)
      when is_non_neg_integer(x_max) and is_non_neg_integer(y_max) do
    for x <- 0..x_max, y <- 0..y_max, do: {x, y, :covered}
  end

  @spec generate_bottom_layer_fields(field_x, field_y, mine_chance()) :: [bottom_layer_field()]
  def generate_bottom_layer_fields(x_max, y_max, mine_chance)
      when is_non_neg_integer(x_max) and is_non_neg_integer(y_max) do
    for x <- 0..x_max, y <- 0..y_max, do: {x, y, clean_or_mine(mine_chance)}
  end
end
