defmodule ExMinesweeper.Engine.State do
  use ExMinesweeper.Types
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

  @spec lost?(t()) :: {:lost, t()} | false
  def lost?(state) do
    # instead of it it would probably be better to evaluate last changed field
    if MapSet.filter(state.board.upper_layer, fn {_, _, v} -> v === :explosion end) |> MapSet.size() != 0 do
      {:lost, state}
    end
  end

  @spec won?(t()) :: :won | false
  def won?(state) do
    upper_layer_clean = MapSet.to_list(state.board.upper_layer) |> Enum.filter(fn {_, _, v} -> v === :clean end)
    bottom_layer_clean = MapSet.to_list(state.board.bottom_layer) |> Enum.filter(fn {_, _, v} -> v === :clean end)
    upper_layer_flagged = MapSet.to_list(state.board.upper_layer) |> Enum.filter(fn {_, _, v} -> v === :flagged end)

    cond do
      MapSet.equal?(
        Enum.map(upper_layer_clean, fn {x, y, _} -> {x, y} end) |> MapSet.new(),
        Enum.map(bottom_layer_clean, fn {x, y, _} -> {x, y} end) |> MapSet.new()
      ) and
          MapSet.subset?(
            Enum.map(upper_layer_flagged, fn {x, y, _} -> {x, y, :mine} end) |> MapSet.new(),
            state.board.bottom_layer
          ) ->
        :won

      true ->
        false
    end
  end

  @spec illegal?(t(), t()) :: :illegal_state | false
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
        false
    end
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
    |> _uncover_clean_neighbors({x, y, :clean})
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

  def _uncover_clean_neighbors(state, field) do
    _clean_neighbors(field, state)
  end

  @spec _clean_neighbors(bottom_layer_field(), t()) :: [bottom_layer_field()]
  def _clean_neighbors({x, y, v}, state) do
    _clean_neighbors([{x, y, v}], state)
  end

  @spec _clean_neighbors(list(bottom_layer_field()), t()) :: [bottom_layer_field()]
  def _clean_neighbors([{x, y, _v}] = _acc, state) do
    bottom_layer_clean_neighbors =
      MapSet.intersection(
        MapSet.new([
          {x - 1, y, :clean},
          {x + 1, y, :clean},
          {x, y - 1, :clean},
          {x, y + 1, :clean}
        ]),
        state.board.bottom_layer
      )

    upper_layer_covered_or_flagged_neighbors =
      MapSet.intersection(
        MapSet.new(for v <- [:covered, :flagged], {x, y, _} <- bottom_layer_clean_neighbors |> MapSet.to_list(), do: {x, y, v}),
        state.board.upper_layer
      )

    # mark covered and flagged upper layer neighboring fields as clean if corresponding bottom layer fields are clean.
    new_upper_layer =
      MapSet.symmetric_difference(upper_layer_covered_or_flagged_neighbors, state.board.upper_layer)
      |> MapSet.union(
        Enum.map(
          upper_layer_covered_or_flagged_neighbors |> MapSet.to_list(),
          fn {x, y, _} -> {x, y, :clean} end
        )
        |> MapSet.new()
      )

    upper_layer_covered_or_flagged_neighbors
    |> MapSet.to_list()
    |> _clean_neighbors(update_in(state, [:board, :upper_layer], fn _ -> new_upper_layer end))
  end

  def _clean_neighbors([{x, y, _v} | t] = _acc, state) do
    bottom_layer_clean_neighbors =
      MapSet.intersection(
        MapSet.new([
          {x - 1, y, :clean},
          {x + 1, y, :clean},
          {x, y - 1, :clean},
          {x, y + 1, :clean}
        ]),
        state.board.bottom_layer
      )

    upper_layer_covered_or_flagged_neighbors =
      MapSet.intersection(
        MapSet.new(for v <- [:covered, :flagged], {x, y, _} <- bottom_layer_clean_neighbors |> MapSet.to_list(), do: {x, y, v}),
        state.board.upper_layer
      )

    # mark covered and flagged upper layer neighboring fields as clean if corresponding bottom layer fields are clean.
    new_upper_layer =
      MapSet.symmetric_difference(upper_layer_covered_or_flagged_neighbors, state.board.upper_layer)
      |> MapSet.union(
        Enum.map(
          upper_layer_covered_or_flagged_neighbors |> MapSet.to_list(),
          fn {x, y, _} -> {x, y, :clean} end
        )
        |> MapSet.new()
      )

    ((upper_layer_covered_or_flagged_neighbors
      |> MapSet.to_list()) ++ t)
    |> _clean_neighbors(update_in(state, [:board, :upper_layer], fn _ -> new_upper_layer end))
  end

  def _clean_neighbors([] = _acc, state) do
    state
  end

  def state(current_state, updated_state) do
    new_updated_state = sync_layers(updated_state, current_state)

    cond do
      illegal?(current_state, updated_state) ->
        illegal_state()

      lost?(new_updated_state) ->
        {lost(), new_updated_state}

      won?(new_updated_state) ->
        {won(), new_updated_state}

      true ->
        {game_on(), new_updated_state}
    end
  end
end
