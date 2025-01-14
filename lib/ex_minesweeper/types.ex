defmodule ExMinesweeper.Types do
  defmacro __using__(_opts) do
    quote do
      @type field_coord :: non_neg_integer()
      @type field_x :: field_coord()
      @type field_y :: field_coord()
      @type layer_field :: upper_layer_field() | bottom_layer_field()
      @type upper_layer_field :: {field_x(), field_y(), :covered | :flag | :flagged | :uncover | :clean | :explosion}
      @type bottom_layer_field :: {field_x(), field_y(), :clean | :mine}
      @type upper_layer :: MapSet.t(upper_layer_field())
      @type bottom_layer :: MapSet.t(bottom_layer_field())
    end
  end
end
