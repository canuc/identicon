defmodule Identicon do
  @moduledoc """
  Deterministically generate a simple "github-style" user icon using the hash
  of a given string
  """

  # use the first three bytes of the hash to determine foreground colour
  defp colour(hash) do
    hash
    |> Stream.take(3)
    |> Enum.map(&( rem(&1, 110) + 100 ))
    |> List.to_tuple
  end

  # use the next 15 bytes to create a 5x5 symmetric pixel map
  defp pixels(hash) do
    hash
    |> Stream.drop(3)
    |> Stream.take(15)
    |> Stream.map(&(rem &1, 2))
    |> Stream.chunk_every(3)
    |> Stream.flat_map(fn [a, b, c] -> [a, b, c, b, a] end)
    |> Stream.with_index
  end

  # use the egd erlang library to draw the image
  defp img(fg, bg, pixels) do
    i = :egd.create 420, 420
    fg = :egd.color fg
    bg = :egd.color bg

    :egd.filledRectangle(i, {0, 0}, {419, 419}, bg)

    pixels
    |> Stream.filter(fn {v, _} -> v == 1 end)
    |> Stream.map(fn {_, i} -> {rem(i, 5) * 70, div(i, 5) * 70} end)
    |> Enum.each(fn {x, y} ->
      :egd.filledRectangle(i, {x+35, y+35}, {x+105, y+105}, fg) end)

    :egd.render i, :png
  end

  @doc """
  Takes the hash of `string` and returns a binary representing a
  deterministically generated icon.

  This icon will be an "identicon" à la github, a coloured, symmetric symbol in
  a 5x5 grid of logical pixels. This symbol will be drawn on a 420x420px canvas
  of colour `bg_colour`, where `bg_colour` is an rgb value, represented by a
  3-tuple of single byte integers.
  
  The returned icon will be a binary in png format, meaning it can be written
  directly to disk. If doing so, consider optimising it with the `optipng`
  command line tool or similar.

  ## Example

      iex> r1 = Identicon.gen "elixir"
      iex> r2 = Identicon.gen "elixir"
      iex> r1 === r2
      true

  """
  @spec gen(binary, {byte, byte, byte}) :: binary
  def gen(string, bg_colour \\ {0xf0, 0xf0, 0xf0}) do
    h = :crypto.hash(:ripemd160, string)
    |> :binary.bin_to_list

    # get draw components
    fg_colour = colour h
    p = pixels h

    # generate image
    img fg_colour, bg_colour, p
  end
end
