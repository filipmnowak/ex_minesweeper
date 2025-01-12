defmodule ExMinesweeper.Engine.State do
  alias File.Stat
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

  @spec lost?(t()) :: :lost | false
  def lost?(state) do
    cond do
      true ->
        false
    end
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

  @spec illegal?(t(), t()) :: :illegal | false
  def illegal?(current_state, updated_state) do
    {current_board, updated_board} = {current_state.board, updated_state.board}
    {current_upper_layer, updated_upper_layer} = {current_board.upper_layer, updated_board.upper_layer}
    blank_board = current_state.blank_board
    upper_layer_diff = MapSet.difference(current_upper_layer, updated_upper_layer)

    cond do
      # too many changes at once
      MapSet.size(upper_layer_diff) > 1 ->
        illegal_state()

      # no changes
      MapSet.size(upper_layer_diff) === 0 ->
        illegal_state()

      # possibly new field added or removed
      MapSet.size(current_upper_layer) != MapSet.size(current_upper_layer) ->
        illegal_state()

      # set of all marked fields from the current board, needs to be a subset of all marked fields in
      # the updated board. marked fields can't be changed.
      MapSet.subset?(
        MapSet.difference(current_upper_layer, blank_board.upper_layer),
        MapSet.difference(updated_upper_layer, blank_board.upper_layer)
      ) === false ->
        illegal_state()

      true ->
        false
    end
  end

  @spec sync_layers(t()) :: t()
  def sync_layers(state) do
    state
  end

  def state(current_state, updated_state) do
    illegal?(current_state, updated_state) || sync_layers(updated_state) |> lost?() || won?(updated_state) || game_on()
  end
end
