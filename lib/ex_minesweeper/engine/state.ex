defmodule ExMinesweeper.Engine.State do
  use ExMinesweeper.Engine.State.Access
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
    # instead of it it would probably be better to evaluate last changed field
    if MapSet.filter(state.board.upper_layer, fn {_, _, v} -> v === :explosion end) |> MapSet.size() != 0 do
      :lost
    end
  end

  @spec won?(t()) :: :won | false
  def won?(state) do
    upper_layer_flagged = MapSet.to_list(state.board.upper_layer) |> Enum.filter(fn {_, _, v} -> v === :flagged end)
    bottom_layer_flagged = MapSet.to_list(state.board.bottom_layer) |> Enum.filter(fn {_, _, v} -> v === :mine end)

    cond do
      length(upper_layer_flagged) != length(bottom_layer_flagged) ->
        false

      MapSet.equal?(
        Enum.map(upper_layer_flagged, fn {x, y, _} -> {x, y} end) |> MapSet.new(),
        Enum.map(bottom_layer_flagged, fn {x, y, _} -> {x, y} end) |> MapSet.new()
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
    upper_layer_diff = MapSet.difference(current_upper_layer, updated_upper_layer)

    cond do
      # too many changes at once
      MapSet.size(upper_layer_diff) > 1 ->
        illegal_state()

      # no changes
      MapSet.size(upper_layer_diff) === 0 ->
        illegal_state()

      # possibly new field added or removed
      MapSet.size(updated_upper_layer) != MapSet.size(current_upper_layer) ->
        illegal_state()

      true ->
        _illegal()
    end
  end

  # TODO
  def _illegal() do
    false
  end

  @spec sync_layers(t(), t()) :: t()
  def sync_layers(updated_state, current_state) do
    [{updated_upper_x, updated_upper_y, updated_upper_field}] =
      MapSet.difference(updated_state.board.upper_layer, current_state.board.upper_layer)
      |> MapSet.to_list()

    # get coordinate-matching current upper layer field
    # :explosion should no happen here
    {_current_upper_x, _current_upper_y, current_upper_field} =
      cond do
        MapSet.member?(current_state.board.upper_layer, {updated_upper_x, updated_upper_y, :covered}) ->
          {updated_upper_x, updated_upper_y, :covered}

        MapSet.member?(current_state.board.upper_layer, {updated_upper_x, updated_upper_y, :flagged}) ->
          {updated_upper_x, updated_upper_y, :flagged}

        MapSet.member?(current_state.board.upper_layer, {updated_upper_x, updated_upper_y, :clean}) ->
          {updated_upper_x, updated_upper_y, :clean}

        true ->
          raise("invalid state")
      end

    # get coordinate-matching current bottom layer field
    # :explosion should no happen here
    {_current_bottom_x, _current_bottom_y, current_bottom_field} =
      cond do
        MapSet.member?(current_state.board.bottom_layer, {updated_upper_x, updated_upper_y, :clean}) ->
          {updated_upper_x, updated_upper_y, :clean}

        MapSet.member?(current_state.board.bottom_layer, {updated_upper_x, updated_upper_y, :mine}) ->
          {updated_upper_x, updated_upper_y, :mine}

        true ->
          raise("invalid state")
      end

    _sync_layers(
      updated_upper_field,
      current_upper_field,
      current_bottom_field,
      updated_state,
      updated_upper_x,
      updated_upper_y
    )
  end

  def _sync_layers(updated_upper_field, current_upper_field, current_bottom_field, state, updated_upper_x, updated_upper_y)

  def _sync_layers(:flag, :covered, _, updated_state, x, y) do
    # set flag
    update_in(
      updated_state,
      [:board, :upper_layer],
      fn ms ->
        MapSet.delete(ms, {x, y, :flag})
        |> MapSet.put({x, y, :flagged})
      end
    )
  end

  def _sync_layers(:flag, :flagged, _, updated_state, x, y) do
    # unset flag
    update_in(
      updated_state,
      [:board, :upper_layer],
      fn ms ->
        MapSet.delete(ms, {x, y, :flag})
        |> MapSet.put({x, y, :covered})
      end
    )
  end

  def _sync_layers(:uncover, :covered, :clean, updated_state, x, y) do
    # uncover clean
    update_in(
      updated_state,
      [:board, :upper_layer],
      fn ms ->
        MapSet.delete(ms, {x, y, :uncover})
        |> MapSet.put({x, y, :clean})
      end
    )
    |> uncover_clean_neighbors({x, y, :clean})
  end

  def uncover_clean_neighbors(state, _field) do
    state
  end

  def _sync_layers(:uncover, :covered, :mine, updated_state, x, y) do
    # uncover mine
    update_in(
      updated_state,
      [:board, :upper_layer],
      fn ms ->
        MapSet.delete(ms, {x, y, :uncover})
        |> MapSet.put({x, y, :explosion})
      end
    )
  end

  def state(current_state, updated_state) do
    illegal?(current_state, updated_state) || sync_layers(updated_state, current_state) |> lost?() || won?(updated_state) ||
      game_on()
  end
end
