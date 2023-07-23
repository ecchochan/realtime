alias Realtime.{Api.Tenant, Repo}

tenant_name = System.get_env("DEFAULT_TENENT_NAME")

{:ok, _} =
  case Repo.get_by(Tenant, external_id: tenant_name) do
    %Tenant{} = tenant -> {:ok, nil}
    nil ->
      Repo.transaction(fn ->
        %Tenant{}
        |> Tenant.changeset(%{
          "name" => tenant_name,
          "external_id" => tenant_name,
          "jwt_signing_method" => System.get_env("API_JWT_SIGNING_METHOD", "HS256"),
          "jwt_secret" => System.get_env("API_JWT_SECRET"),
          "extensions" => [
            %{
              "type" => "postgres_cdc_rls",
              "settings" => %{
                "db_name" => System.get_env("DB_NAME"),
                "db_host" => System.get_env("DB_HOST"),
                "db_user" => System.get_env("DB_USER"),
                "db_password" => System.get_env("DB_PASSWORD"),
                "db_port" => System.get_env("DB_PORT"),
                "region" => "us-east-1",
                "poll_interval_ms" => 100,
                "poll_max_record_bytes" => 1_048_576,
                "ip_version" => 4
              }
            }
          ]
        })
        |> Repo.insert!()
      end)
  end
