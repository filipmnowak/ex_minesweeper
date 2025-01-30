defmodule ExMinesweeper do
  alias ExMinesweeper.Engine
  alias ExMinesweeper.Engine.State
  alias ExMinesweeper.Engine.State.Board.Helpers, as: BoardHelpers

  defdelegate init(x_max, y_max, mine_chance), to: Engine
  defdelegate phase(state), to: State
  defdelegate mark(state, uncover_or_flag, x_and_y), to: Engine
  defdelegate progress_game(state, updated_state), to: Engine
  defdelegate render_board(board, legend \\ false), to: BoardHelpers 
end
