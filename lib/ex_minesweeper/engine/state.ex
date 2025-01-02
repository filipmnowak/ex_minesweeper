defmodule ExMinesweeper.Engine.State do
  alias ExMinesweeper.Engine.State.Board

  @type t :: %__MODULE__{phase: atom(), board: Board.t(), blank_board: Board.t()}
  defstruct(
    phase: nil,
    turn: nil,
    board: nil,
    blank_board: nil
  )

  defmacro won(), do: :won
  defmacro lost(), do: :lost
  defmacro game_on(), do: :game_on
  defmacro illegal_state(), do: :illegal_state

  def repeat_turn(), do: :repeat_turn

  def new(x_max, y_max, mine_chance) do
    board = Board.new(x_max, y_max, mine_chance)

    %__MODULE__{
      phase: :init,
      board: board,
      blank_board: board
    }
  end

  def phase(state), do: state.phase

  def mark(state, uncover_or_flag, {x, y}) do
    %__MODULE__{state | board: Board.mark(state.board, uncover_or_flag, {x, y})}
  end

  @spec won?(t()) :: :won | false
  def won?(state) do
    upper_layer_flagged = MapSet.to_list(state.board.upper_layer) |> Enum.filter(fn e -> Map.values(e) === [:flagged] end)
    bottom_layer_flagged = MapSet.to_list(state.board.bottom_layer) |> Enum.filter(fn e -> Map.values(e) === [:mine] end)

    cond do
      length(upper_layer_flagged) != length(bottom_layer_flagged) ->
        false

      MapSet.equal?(
        Enum.map(upper_layer_flagged, fn e -> Map.keys(e) |> List.first() end) |> MapSet.new(),
        Enum.map(bottom_layer_flagged, fn e -> Map.keys(e) |> List.first() end) |> MapSet.new()
      ) ->
        :won

      true ->
        false
    end
  end

  def illegal?(current_state, updated_state) do
    {current_board, updated_board} = {current_state.board, updated_state.board}
    {current_upper_layer, updated_upper_layer} = {current_board.upper_layer, updated_board.upper_layer}
    {current_bottom_layer, updated_bottom_layer} = {current_board.bottom_layer, updated_board.bottom_layer}
    blank_board = current_state.blank_board
    diff = MapSet.difference(updated_board.topology, current_board.topology)

    cond do
      # too many changes at once
      MapSet.size(diff) > 1 ->
        illegal_state()

      # no changes
      MapSet.size(diff) == 0 ->
        illegal_state()

      # possibly new field added or removed
      MapSet.size(current_board.topology) != MapSet.size(updated_board.topology) ->
        illegal_state()

      # set of all marked fields from the current board, needs to be a subset of all marked fields in
      # the updated board. marked fields can't be changed.
      MapSet.subset?(
        MapSet.difference(current_board.topology, blank_board.topology),
        MapSet.difference(updated_board.topology, blank_board.topology)
      ) === false ->
        illegal_state()

      true ->
        false
    end
  end

  def state(current_state, updated_state) do
    illegal?(current_state, updated_state) || won?(updated_state) || game_on()
  end
end
