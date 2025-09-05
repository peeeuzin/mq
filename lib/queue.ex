defmodule Queue do
  @moduledoc """
  Simple priority queue using Erlang's `:gb_trees`.

  - Mode: `:min` (default) returns smallest priority first.
  - Mode: `:max` returns largest priority first (numeric priorities only).
  - For equal priorities, FIFO-ish behavior is achieved by storing values in lists;
    items with the same priority are popped in LIFO order by this simple implementation.
    (If strict FIFO for equal priorities is required, we can add an incremental counter.)
  """

  defstruct tree: :gb_trees.empty(), size: 0, mode: :min

  @type t :: %__MODULE__{
          tree: :gb_trees.tree(),
          size: non_neg_integer(),
          mode: :min | :max
        }

  @doc "Create a new priority queue. Mode is :min (default) or :max."
  @spec new() :: t()
  @spec new(:min | :max) :: t()
  def new(mode \\ :min) when mode in [:min, :max] do
    %__MODULE__{tree: :gb_trees.empty(), size: 0, mode: mode}
  end

  @doc "Returns true if queue is empty."
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{size: 0}), do: true
  def empty?(_), do: false

  @doc "Return number of elements."
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{size: n}), do: n

  # internal: transform priority into tree key depending on mode
  defp key_for(%__MODULE__{mode: :min}, priority), do: priority
  defp key_for(%__MODULE__{mode: :max}, priority) when is_number(priority), do: -priority

  defp key_for(%__MODULE__{mode: :max}, priority) do
    raise ArgumentError,
          "Queue in :max mode requires numeric priorities. Got: #{inspect(priority)}"
  end

  @doc """
  Push `value` with `priority` into the queue.
  Returns the new queue.
  """
  @spec push(t(), any(), any()) :: t()
  def push(%__MODULE__{} = q, priority, value) do
    key = key_for(q, priority(priority))
    tree = q.tree

    new_tree =
      case :gb_trees.lookup(key, tree) do
        :none ->
          # store a list of {original_priority, value} so we can return original priority for :max
          :gb_trees.enter(key, [{priority, value}], tree)

        {:value, existing_list} ->
          :gb_trees.enter(key, [{priority, value} | existing_list], tree)
      end

    %__MODULE__{q | tree: new_tree, size: q.size + 1}
  end

  @doc """
  Peek at the next item without removing it.
  Returns `{:ok, {priority, value}}` or `:empty`.
  """
  @spec peek(t()) :: {:ok, {any(), any()}} | :empty
  def peek(%__MODULE__{size: 0}), do: :empty

  def peek(%__MODULE__{tree: tree, mode: _mode} = _q) do
    # always use smallest key in tree (we transformed keys for :max)
    case :gb_trees.smallest(tree) do
      {_k, list} ->
        # list stored as [{orig_priority, value} | ...], head is most recently inserted for that priority
        [{orig_p, v} | _] = list
        {:ok, {orig_p, v}}
    end
  end

  @doc """
  Pop the next item. Returns `{:ok, {priority, value}, new_queue}` or `:empty`.
  """
  @spec pop(t()) :: {:ok, {any(), any()}, t()} | :empty
  def pop(%__MODULE__{size: 0}), do: :empty

  def pop(%__MODULE__{tree: tree, size: size} = q) do
    case :gb_trees.smallest(tree) do
      {k, list} ->
        [{orig_p, v} | rest] = list

        new_tree =
          case rest do
            [] -> :gb_trees.delete(k, tree)
            _ -> :gb_trees.enter(k, rest, tree)
          end

        new_q = %__MODULE__{q | tree: new_tree, size: size - 1}
        {:ok, {orig_p, v}, new_q}
    end
  end

  @doc """
  Convert to list of `{priority, value}` in pop-order (head is next to be popped).
  """
  @spec to_list(t()) :: list({any(), any()})
  def to_list(%__MODULE__{tree: tree}) do
    # :gb_trees.to_list returns [{key, value_list}, ...] in key order
    # Expand each value_list (which is a list of {orig_priority, value}) into items in the correct popping order.
    :gb_trees.to_list(tree)
    |> Enum.flat_map(fn {_k, value_list} ->
      # value_list stored newest-first; popping returns newest-first, so keep as-is
      Enum.map(value_list, fn {p, v} -> {p, v} end)
    end)
  end

  defp priority(priority) when priority in [:low, :medium, :high] do
    case priority do
      :low -> 0
      :medium -> 1
      :high -> 2
    end
  end
end
