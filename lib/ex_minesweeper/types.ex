defmodule ExMinesweeper.Types do
  defmacro __using__(_opts) do
    quote do
      @type layer_field :: upper_layer_field() | bottom_layer_field()
      @type upper_layer_field :: :covered | :flagged | :clean | :mine | :explosion
      @type bottom_layer_field :: :clean | :mine | :explosion
      @type upper_layer :: MapSet.t(layer_field())
      @type field_coord :: non_neg_integer()
      @type field_x :: field_coord()
      @type field_y :: field_coord()
    end
  end
end
