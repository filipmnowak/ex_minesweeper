defmodule ExMinesweeper.Types.Guards do
  defguard is_non_neg_integer(n) when is_integer(n) and n >= 0
  defguard is_pos_integer(n) when is_integer(n) and n > 0
end
