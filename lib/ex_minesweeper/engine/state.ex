defmodule ExMinesweeper.Engine.State do
  alias ExMinesweeper.Engine.State.Board

  defstruct(
    phase: nil,
    turn: nil,
    board: nil,
    blank_board: nil,
    time: nil
  )

  defmacro won(), do: :won
  defmacro lost(), do: :lost
  defmacro game_on(), do: {:game_on, nil}
  defmacro illegal_state(), do: {:illegal_state, nil}

  def repeat_turn(), do: :repeat_turn

  def new(x_max, y_max) do
    board = Board.new(x_max, y_max, 15)

    %__MODULE__{
      phase: :init,
      board: board
    }
  end

  def phase(state), do: state.phase

  def mark(state, uncover_or_flag, {x, y}) do
    %__MODULE__{state | board: Board.mark(state.board, uncover_or_flag, {x, y})}
  end

  def won?(state) do
    _won?(state)
  end

  defp _won?(_state) do
    # board = state.board

    # TODO: check for winning condition
    :won
  end

  def illegal?(current_state, updated_state) do
    {current_board, updated_board} = {current_state.board, updated_state.board}
    blank_board = current_state.blank_board
    diff = MapSet.difference(updated_board.topology, current_board.topology)

    cond do
      # too many changes at once
      MapSet.size(diff) > 1 ->
        illegal_state()

      # no changes
      MapSet.size(diff) == 0 ->
        illegal_state()

      # possibly new field added
      MapSet.size(current_board.topology) != MapSet.size(updated_board.topology) ->
        illegal_state()

      # set of all marked fields from the current board, needs to be a subset of all marked fields in
      # the updated board. marked fields can't be changed.
      MapSet.subset?(
        MapSet.difference(current_board.topology, blank_board.topology),
        MapSet.difference(updated_board.topology, blank_board.topology)
      ) === false ->
        illegal_state()

      diff ->
        false
    end
  end

  def state(current_state, updated_state) do
    illegal?(current_state, updated_state) || won?(updated_state) || game_on()
  end
end
