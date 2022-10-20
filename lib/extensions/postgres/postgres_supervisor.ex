defmodule Extensions.Postgres.Supervisor do
  use Supervisor

  alias Extensions.Postgres

  @spec start_link :: :ignore | {:error, any} | {:ok, pid}
  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    :syn.add_node_to_scopes([Postgres.Sup])

    children = [
      {
        PartitionSupervisor,
        partitions: 20,
        child_spec: DynamicSupervisor,
        strategy: :one_for_one,
        name: Postgres.DynamicSupervisor
      },
      Postgres.SubscriptionManagerTracker
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
