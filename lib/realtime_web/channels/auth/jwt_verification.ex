defmodule RealtimeWeb.JwtVerification do
  @moduledoc """
  Parse JWT and verify claims
  """
  defmodule JwtAuthToken do
    @moduledoc false
    use Joken.Config

    @impl true
    def token_config do
      Application.fetch_env!(:realtime, :jwt_claim_validators)
      |> Enum.reduce(%{}, fn {claim_key, expected_val}, claims ->
        add_claim_validator(claims, claim_key, expected_val)
      end)
      |> add_claim_validator("exp")
    end

    defp add_claim_validator(claims, "exp") do
      add_claim(claims, "exp", nil, &(&1 > current_time()))
    end

    defp add_claim_validator(claims, claim_key, expected_val) do
      add_claim(claims, claim_key, nil, &(&1 == expected_val))
    end
  end

  @hs_algorithms ["HS256", "HS384", "HS512"]
  @rs_algorithms ["RS256", "RS384", "RS512"]
  @es_algorithms ["ES256", "ES384", "ES512"]
  @ps_algorithms ["PS256", "PS384", "PS512"]
  @eddsa_algorithms ["Ed25519", "Ed25519ph", "Ed448", "Ed448ph", "EdDSA"]

  @map_key_algorithms @rs_algorithms ++ @es_algorithms ++ @ps_algorithms ++ @eddsa_algorithms


  def verify(token, secret, signing_method) when is_binary(token) do
    with {:ok, _claims} <- check_claims_format(token),
         {:ok, header} <- check_header_format(token),
         {:ok, signer} <- generate_signer(header, secret, signing_method) do
      JwtAuthToken.verify_and_validate(token, signer)
    else
      {:error, _e} = error -> error
    end
  end

  def verify(_token, _secret), do: {:error, :not_a_string}

  defp check_header_format(token) do
    case Joken.peek_header(token) do
      {:ok, header} when is_map(header) -> {:ok, header}
      _error -> {:error, :expected_header_map}
    end
  end

  defp check_claims_format(token) do
    case Joken.peek_claims(token) do
      {:ok, claims} when is_map(claims) -> {:ok, claims}
      _error -> {:error, :expected_claims_map}
    end
  end

  defp generate_signer(%{"typ" => "JWT"}, jwt_secret, signing_method) when signing_method in @hs_algorithms do
    {:ok, Joken.Signer.create(signing_method, jwt_secret)}
  end

  defp generate_signer(%{"typ" => "JWT"}, jwt_secret, signing_method) when signing_method in @map_key_algorithms do
    {:ok, Joken.Signer.create(signing_method, %{"pem" => jwt_secret})}
  end

  defp generate_signer(header, _secret, _alg) when not is_map_key(header, "alg") do
    {:error, :missing_alg_header}
  end

  defp generate_signer(_header, _secret, _alg), do: {:error, :error_generating_signer}
end
