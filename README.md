# ExMinesweeper

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_minesweeper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_minesweeper, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_minesweeper>.


## Example session

Init new game:

```elixir
iex> ms = ExMinesweeper.init(5, 5, 40)
%ExMinesweeper.Engine.State{...}
iex> ms.board |> ExMinesweeper.Engine.State.Board.Helpers.render_board(true) |> IO.puts()

:covered -> #
   :flag -> f
:flagged -> F
:uncover -> u
  :clean -> C
   :mine -> m

upper layer:

# # # # # # 
# # # # # # 
# # # # # # 
# # # # # # 
# # # # # # 
# # # # # # 

bottom layer:

m C m C C C 
C C m C m C 
C C m m C C 
C C C C C m 
C C m C m C 
C C m C m C 

:ok
```

Mark field:

```elixir
iex> ms2 = ExMinesweeper.mark(ms, :uncover, {0, 1})
%ExMinesweeper.Engine.State{...}
iex> ms2.board |> ExMinesweeper.Engine.State.Board.Helpers.render_board(true) |> IO.puts()

:covered -> #
   :flag -> f
:flagged -> F
:uncover -> u
  :clean -> C
   :mine -> m

upper layer:

# u # # # # 
# # # # # # 
# # # # # # 
# # # # # # 
# # # # # # 
# # # # # # 

bottom layer:

m C m C C C 
C C m C m C 
C C m m C C 
C C C C C m 
C C m C m C 
C C m C m C 

:ok
```

Processing...

```elixir
iex> ms3 = ExMinesweeper.progress_game(ms, ms2)
%ExMinesweeper.Engine.State{...}
iex> ms3.board |> ExMinesweeper.Engine.State.Board.Helpers.render_board(true) |> IO.puts()

:covered -> #
   :flag -> f
:flagged -> F
:uncover -> u
  :clean -> C
   :mine -> m

upper layer:

# C # C C C 
C C # C # C 
C C # # C C 
C C C C C # 
C C # C # # 
C C # C # # 

bottom layer:

m C m C C C 
C C m C m C 
C C m m C C 
C C C C C m 
C C m C m C 
C C m C m C 

:ok
```

Mark another field...

```elixir
iex> ExMinesweeper.phase(ms3)
:game_on
iex> ms4 = ExMinesweeper.mark(ms3, :uncover, {5, 5})
%ExMinesweeper.Engine.State{...}
iex> ms4.board |> ExMinesweeper.Engine.State.Board.Helpers.render_board(true) |> IO.puts()

:covered -> #
   :flag -> f
:flagged -> F
:uncover -> u
  :clean -> C
   :mine -> m

upper layer:

# C # C C C 
C C # C # C 
C C # # C C 
C C C C C # 
C C # C # # 
C C # C # u 

bottom layer:

m C m C C C 
C C m C m C 
C C m m C C 
C C C C C m 
C C m C m C 
C C m C m C 

:ok
```

Progress game; game won:

```elixir
iex> ms5 = ExMinesweeper.progress_game(ms3, ms4)
%ExMinesweeper.Engine.State{...}
iex> ms5.board |> ExMinesweeper.Engine.State.Board.Helpers.render_board(true) |> IO.puts()

:covered -> #
   :flag -> f
:flagged -> F
:uncover -> u
  :clean -> C
   :mine -> m

upper layer:

# C # C C C 
C C # C # C 
C C # # C C 
C C C C C # 
C C # C # C 
C C # C # C 

bottom layer:

m C m C C C 
C C m C m C 
C C m m C C 
C C C C C m 
C C m C m C 
C C m C m C 

:ok
iex> ExMinesweeper.phase(ms5)
:won
```
