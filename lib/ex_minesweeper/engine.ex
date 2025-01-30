defmodule ExMinesweeper.Engine do
  use ExMinesweeper.Types
  import ExMinesweeper.Types.Guards

  alias ExMinesweeper.Engine.State
  require State

  defdelegate mark(state, uncover_or_flag, field), to: State

  def init(x_max, y_max, mine_chance)

  def init(x_max, y_max, mine_chance)
      when is_pos_integer(x_max) and
             is_pos_integer(y_max) and
             x_max == y_max do
    State.new(x_max, y_max, mine_chance)
    |> Map.put(:turn, 1)
    |> Map.put(:phase, State.game_on())
  end

  def init(_x_max, _y_max, _mine_chance) do
    {:err, :bad_args}
  end

  def progress_game(%State{phase: phase} = state, _)
      when phase in [State.won(), State.lost()] do
    state
  end

  # reset state to eval next attemp
  def progress_game(%State{phase: phase} = state, updated_state)
      when phase == State.illegal_state() do
    progress_game(%State{state | phase: State.game_on()}, updated_state)
  end

  def progress_game(%State{phase: phase} = state, updated_state) when phase == State.game_on() do
    case State.state(state, updated_state) do
      {State.game_on(), reconciled_state} ->
        %State{reconciled_state | phase: State.game_on()}
        |> Map.get_and_update(:turn, &{&1, &1 + 1})
        |> elem(1)

      {State.won(), reconciled_state} ->
        %State{reconciled_state | phase: State.won()}

      State.illegal_state() ->
        %State{state | phase: State.illegal_state()}

      {State.lost(), reconciled_state} ->
        %State{reconciled_state | phase: State.lost()}
    end
  end
end
