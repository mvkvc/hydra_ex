defmodule Hydra do
  # @config_folder "examples/hydra/conf"
  @config_folder "examples/dummy/conf"
  @config_name "config"

  def run() do
    load_config(@config_folder, @config_name)
  end

  def load_yaml(folder, filename, ext \\ ".yaml") do
    Application.start(:yamerl)
    path = folder <> "/" <> filename <> ext

    path
    |> :yamerl_constr.file()
    |> List.first()
  end

  def load_config(folder, filename, runtime \\ %{}) do
    base =
      load_yaml(folder, filename)
      |> convert()

    {defaults, overrides} = Map.pop(base, 'defaults')
    {runtime_defaults, runtime_overrides} = Map.pop(runtime, 'defaults')

    defaults =
      if runtime_defaults do
        recur_map_merge(defaults, runtime_defaults)
      else
        defaults
      end

    params =
      Enum.reduce(Map.to_list(defaults), %{}, fn x, acc ->
        key = elem(x, 0)
        value = elem(x, 1)

        result = base_builder(folder, key, value)
        Map.put(acc, key, result)
      end)

    params
    |> recur_map_merge(overrides)
    |> recur_map_merge(runtime_overrides)
  end

  def base_builder(root, folder, file, params \\ [])

  def base_builder(_root, _folder, nil, params) do
    Enum.reduce(params, %{}, fn x, acc ->
      recur_map_merge(acc, x)
    end)
  end

  def base_builder(root, folder, file, params) do
    contents =
      load_yaml(root <> "/" <> to_string(folder), to_string(file))
      |> convert()

    {new_file, contents} = Map.pop(contents, 'base')

    new_params = [contents] ++ params

    base_builder(root, folder, new_file, new_params)
  end

  def recur_map_merge(x, y) do
    Map.merge(x, y, fn _k, v1, v2 ->
      if is_map(v1) and is_map(v2) do
        recur_map_merge(v1, v2)
      else
        v2
      end
    end)
  end

  def convert(collection) do
    result =
      Enum.reduce(collection, %{}, fn x, acc ->
        case x do
          [a] when is_tuple(a) ->
            Map.put(acc, elem(a, 0), elem(a, 1))

          {a, b} when (is_list(b) and not is_binary(b)) or is_tuple(b) ->
            b = if is_charlist(b), do: b, else: convert(b)
            Map.put(acc, a, b)

          {a, b} ->
            Map.put(acc, a, b)

          [a] when is_list(a) and length(a) == 1 ->
            convert(a)

          _ ->
            acc
        end
      end)

    result
  end

  def is_charlist(list) do
    Enum.reduce_while(list, true, fn x, acc ->
      cond do
        is_integer(x) -> {:cont, acc}
        true -> {:halt, false}
      end
    end)
  end
end
