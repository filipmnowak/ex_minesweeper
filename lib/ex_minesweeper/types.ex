defmodule ExMinesweeper.Types do
  defmacro __using__(_opts) do
    quote do
      @type covered_or_uncovered :: :covered | :uncovered
      @type flagged_or_not_flagged :: :flagged | :not_flagged
      @type mined_or_not_mined :: :mined | :not_mined
      @type field_attrs :: {covered_or_uncovered(), flagged_or_not_flagged(), mine_or_no_mine()}
      @type field_coord :: non_neg_integer()
      @type field_x :: field_coord()
      @type field_y :: field_coord()
      @type field :: %{{field_x(), field_y()} => nil | field_attrs()}
    end
  end
end
