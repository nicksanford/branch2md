defmodule Branch2Md do
  @moduledoc """
  Documentation for Branch2Md.
  """

  alias Branch2Md.PullRequest
  alias Branch2Md.Repo

  @check_url_error "Project either doesn't exist or you don't have permission to access it with the authentication creds provided."
  @default_headers [{'User-Agent', 'curl/7.43.0'}]
  @httpc_options [{:timeout, 5000}, {:connect_timeout, 5000}]

  @enforce_keys [:user, :project, :auth, :branch]
  defstruct @enforce_keys

  @type t :: %Branch2Md{
          user: String.t(),
          project: String.t(),
          branch: String.t(),
          auth: nil | String.t()
        }

  @spec check_url(t()) :: :ok | {:error, String.t()}
  def check_url(struct = %Branch2Md{auth: auth}) do
    httpc_request = {'#{PullRequest.github_repo_url(struct)}', maybe_add_auth_headers(auth)}

    response = :httpc.request(:get, httpc_request, @httpc_options, [])

    case response do
      {:ok, {{_, 200, _}, _, _}} -> :ok
      _ -> {:error, @check_url_error}
    end
  end

  # TODO This could be optimized by chunking parallelized chunks (may result
  # in rate limiting)
  @spec render_prs(t(), :in | :out | :all) :: String.t()
  def render_prs(struct, filter_by \\ :in) do
    prs = get_and_filter_prs(struct, filter_by)

    PullRequest.render(struct, prs)
  end

  @spec get_and_filter_prs(t(), :in | :out | :all) :: [PullRequest.t()]
  def get_and_filter_prs(struct, filter_by) do
    commit_shas = Repo.extract_commit_shas(struct)

    f =
      case filter_by do
        :in ->
          fn %{base_sha: base_sha, head_sha: head_sha, merge_commit_sha: merge_commit_sha} ->
            Enum.any?([
              base_sha in commit_shas,
              head_sha in commit_shas,
              merge_commit_sha in commit_shas
            ])
          end

        :out ->
          fn %{base_sha: base_sha, head_sha: head_sha, merge_commit_sha: merge_commit_sha} ->
            not Enum.any?([
              base_sha in commit_shas,
              head_sha in commit_shas,
              merge_commit_sha in commit_shas
            ])
          end

        _ ->
          fn x -> x end
      end

    sort_mapper = fn pr ->
      {:ok, datetime, _} = DateTime.from_iso8601(pr.merged_at)
      datetime
    end

    sorter = &(DateTime.compare(&1, &2) != :lt)

    struct
    |> PullRequest.load()
    |> Enum.filter(& &1.merged_at)
    |> Enum.filter(f)
    |> Enum.sort_by(sort_mapper, sorter)
  end

  def httpc_options(), do: @httpc_options

  @spec maybe_add_auth_headers(String.t() | nil) :: [
          {charlist() | atom(), charlist() | integer()}
        ]
  def maybe_add_auth_headers(nil), do: @default_headers

  def maybe_add_auth_headers(auth) do
    auth_header = {'Authorization', 'Basic #{:base64.encode(auth)}'}
    [auth_header | @default_headers]
  end
end
