defmodule Branch2Md.PullRequest do
  require EEx

  alias Branch2Md.PullRequest

  @github_api_url Application.get_env(:branch2md, :github_api_url)
  @github_url Application.get_env(:branch2md, :github_url)

  @enforce_keys [
    :number,
    :body,
    :title,
    :merge_commit_sha,
    :head_ref,
    :head_sha,
    :base_ref,
    :base_sha,
    :merged_at
  ]
  @derive Jason.Encoder
  defstruct @enforce_keys

  @type t :: %PullRequest{
          number: integer(),
          body: String.t(),
          title: String.t(),
          merge_commit_sha: String.t(),
          head_ref: String.t(),
          head_sha: String.t(),
          base_ref: String.t(),
          base_sha: String.t(),
          merged_at: String.t()
        }

  EEx.function_from_file(:def, :render, "lib/branch2md/pull_requests.eex", [
    :struct,
    :prs
  ])

  @spec github_repo_url(Branch2Md.t()) :: String.t()
  def github_repo_url(%Branch2Md{user: user, project: project}) do
    "#{@github_url}/#{user}/#{project}"
  end

  @spec pull_request_url(t(), Branch2Md.t()) :: String.t()
  def pull_request_url(%{number: number}, %Branch2Md{user: user, project: project}) do
    "#{@github_url}/#{user}/#{project}/pull/#{number}"
  end

  @spec collect_pull_requests(Branch2Md.t()) :: Stream.default()
  def collect_pull_requests(struct) do
    Stream.unfold(1, &download_pull_requests(struct, &1))
  end

  @spec load(Branch2Md.t()) :: [t()]
  def load(struct = %Branch2Md{}) do
    IO.puts(:stderr, "Loading pull requests, this may take some time.")

    # TODO consider changing this to flat map
    struct
    |> collect_pull_requests()
    |> Enum.to_list()
    |> Enum.concat()
    |> Enum.map(&parse/1)
  end

  @spec download_pull_requests(Branch2Md.t(), integer()) :: nil | {String.t(), integer()}
  defp download_pull_requests(struct = %Branch2Md{auth: auth}, number) do
    url = pull_request_index_url(struct, number)
    httpc_request = {'#{url}', Branch2Md.maybe_add_auth_headers(auth)}
    IO.puts(:stderr, "Downloading PR batch ##{number}")

    result = :httpc.request(:get, httpc_request, Branch2Md.httpc_options(), [])

    case result do
      {:ok, {{_, 200, _}, _, body}} ->
        case Jason.decode!(body) do
          [] -> nil
          json_body -> {json_body, number + 1}
        end

      {:ok, {{_, status_code, _}, _, body}} ->
        case Jason.decode(body) do
          {:ok, %{"message" => message, "documentation_url" => documentation_url}} ->
            IO.puts(
              :stderr,
              IO.ANSI.format(
                [:red, "ERROR: #{status_code} #{message} #{documentation_url}"],
                true
              )
            )

          _ ->
            IO.puts(:stderr, IO.ANSI.format([:red, "ERROR: #{status_code}"], true))
        end

        System.halt(1)

      {:error, :timeout} ->
        IO.puts(:stderr, IO.ANSI.format([:red, "ERROR: timeout"], true))
        System.halt(1)

      error ->
        IO.puts(:stderr, IO.ANSI.format([:red, "ERROR: Invalid url #{url}"], true))
        IO.puts(:stderr, IO.ANSI.format([:red, inspect(error)], true))
        System.halt(2)
    end
  end

  @spec pull_request_index_url(Branch2Md.t(), integer(), integer()) :: String.t()
  defp pull_request_index_url(%Branch2Md{user: user, project: project}, number, per_page \\ 100) do
    "#{@github_api_url}/repos/#{user}/#{project}/pulls?state=closed&page=#{number}&per_page=#{
      per_page
    }"
  end

  @spec parse(%{}) :: t()
  defp parse(%{
         "number" => number,
         "body" => body,
         "title" => title,
         "merge_commit_sha" => merge_commit_sha,
         "merged_at" => merged_at,
         "head" => %{"ref" => head_ref, "sha" => head_sha},
         "base" => %{"ref" => base_ref, "sha" => base_sha}
       }) do
    %PullRequest{
      number: number,
      body: body,
      title: title,
      merge_commit_sha: merge_commit_sha,
      head_ref: head_ref,
      head_sha: head_sha,
      base_ref: base_ref,
      base_sha: base_sha,
      merged_at: merged_at
    }
  end
end
