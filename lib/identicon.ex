defmodule Identicon do
  @moduledoc """
  Deterministically generate a simple "github-style" user icon using the hash
  of a given string
  """

  @image_size 420
  @pixels 9

  # use the first three bytes of the hash to determine foreground colour
  defp colour(hash) do
    hash
    |> Stream.take(3)
    |> Enum.map(&( rem(&1, 110) + 100 ))
    |> List.to_tuple
  end

  defp palindrome_me([], list) do
    list
  end

  defp palindrome_me([head | tail], []) do
    palindrome_me(tail, [head])
  end

  defp palindrome_me([head | tail], list) do
    palindrome_me(tail, [head] ++ list ++ [head])
  end

  # use the next 15 bytes to create a 5x5 symmetric pixel map
  defp pixels(hash) do
    chunk_every = div(@pixels, 2) + 1

    hash
    |> Stream.drop(3)
    |> Stream.take(chunk_every * @pixels)
    |> Stream.map(&(rem &1, 2))
    |> Stream.chunk_every(chunk_every)
    |> Stream.flat_map(fn input -> palindrome_me(input, []) end)
    # |> Stream.flat_map(fn [a, b, c] -> [a, b, c, b, a] end)
    |> Stream.with_index
  end

  # use the egd erlang library to draw the image
  defp img(fg, bg, pixels) do
    i = :egd.create @image_size, @image_size
    fg = :egd.color fg
    bg = :egd.color bg

    border = div(@image_size, (@pixels + 1) * 2)
    pixel_width = div(@image_size, @pixels + 1)

    :egd.filledRectangle(i, {0, 0}, {@image_size - 1, @image_size - 1}, bg)

    pixels
    |> Stream.filter(fn {v, _} -> v == 1 end)
    |> Stream.map(fn {_, i} -> {rem(i, @pixels) * pixel_width, div(i, @pixels) * pixel_width} end)
    |> Enum.each(fn {x, y} ->
      :egd.filledRectangle(i, {x+border, y+border}, {x+pixel_width+border, y+pixel_width+border}, fg) end)

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
    h = :crypto.hash(:sha512, string)
    |> :binary.bin_to_list

    # get draw components
    fg_colour = colour h
    p = pixels h

    # generate image
    img fg_colour, bg_colour, p
  end
end
