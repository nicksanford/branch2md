defmodule Gitlog do
  @moduledoc """
  Documentation for Gitlog.
  """

  require EEx

  @cache_dir Application.get_env(:gitlog, :cache_dir)
  @clone_dir Application.get_env(:gitlog, :clone_dir)
  @default_headers [{'User-Agent', 'curl/7.43.0'}]
  @enforce_keys [:user, :project]
  @github_api_url Application.get_env(:gitlog, :github_api_url)
  @github_url Application.get_env(:gitlog, :github_url)
  # TODO Either learn what these timeouts are for or change the implementation
  # to use hackney
  @httpc_options [{:timeout, 5000}, {:connect_timeout, 5000}]

  @type gitlog_struct :: %Gitlog{
          user: String.t(),
          project: String.t(),
          auth: nil | String.t(),
          cache: boolean()
        }

  @type pull_request :: %{
          number: integer(),
          body: String.t(),
          merge_commit_sha: String.t(),
          head_ref: String.t(),
          head_sha: String.t(),
          base_ref: String.t(),
          base_sha: String.t(),
          merged_at: String.t()
        }

  defstruct [:user, :project, :auth, :cache]

  EEx.function_from_file(:def, :render_pull_requests, "pull_requests.eex", [
    :struct,
    :prs,
    :branch
  ])

  @spec pr_url(gitlog_struct, integer(), integer()) :: String.t()
  def pr_url(%Gitlog{user: user, project: project}, number, per_page \\ 100) do
    "#{@github_api_url}/repos/#{user}/#{project}/pulls?state=closed&page=#{number}&per_page=#{
      per_page
    }"
  end

  @spec github_repo_url(gitlog_struct) :: String.t()
  def github_repo_url(%Gitlog{user: user, project: project}) do
    "#{@github_url}/repos/#{user}/#{project}"
  end

  @spec clone_project_path(gitlog_struct) :: String.t()
  def clone_project_path(%Gitlog{project: project}) do
    Path.join(@clone_dir, project)
  end

  @spec cache_path(gitlog_struct) :: String.t()
  def cache_path(%Gitlog{user: user, project: project}) do
    Path.join(@cache_dir, "#{user}#{project}.json")
  end

  # TODO This could be optimized by chunking parallelized chunks (may result
  # in rate limiting)
  @spec collect_pull_requests(gitlog_struct) :: Stream.default()
  def collect_pull_requests(struct) do
    Stream.unfold(1, &download_pull_requests(struct, &1))
  end

  @spec get_and_filter_prs(gitlog_struct, :in | :out | :all) :: [pull_request]
  def get_and_filter_prs(struct, filter_by \\ :in) do
    {_, 0} = clone_project(struct)
    git_shas = get_git_shas(struct)
    _ = remove_project(struct)

    f =
      case filter_by do
        :in ->
          fn %{base_sha: base_sha} -> base_sha in git_shas end

        :out ->
          fn %{base_sha: base_sha} -> base_sha not in git_shas end

        _ ->
          fn x -> x end
      end

    struct
    |> collect_pull_requests()
    |> process_pull_request_stream()
    |> Enum.filter(& &1.merged_at)
    |> Enum.filter(f)
  end

  @spec cached?(gitlog_struct) :: boolean()
  def cached?(struct) do
    struct
    |> cache_path()
    |> File.exists?()
  end

  @spec cache_pr_data(gitlog_struct) :: String.t()
  def cache_pr_data(struct) do
    _ = File.mkdir(@cache_dir)

    data =
      collect_pull_requests(struct)
      |> Enum.to_list()
      |> Jason.encode!()

    :ok =
      cache_path(struct)
      |> File.write!(data)

    data
  end

  @spec load_pr_cache(gitlog_struct) :: String.t()
  def load_pr_cache(struct) do
    struct
    |> cache_path()
    |> File.read!()
  end

  # TODO Cache always, only use it if the flag is present, test this out
  @spec load_pr_data(gitlog_struct) :: String.t()
  def load_pr_data(struct = %Gitlog{cache: cache}) do
    case {cached?(struct), cache} do
      {true, true} ->
        load_pr_cache(struct)

      _ ->
        cache_pr_data(struct)
    end
  end

  # TODO consider having a full report be rendered including:
  # 1. The prs that were able to be tied back to the branch
  # 2. The prs that were not able to be tied back to the branch
  # 3. An index to see each of them
  # 4. A static site generator to create the site as a whole
  # 5. Maybe a page for each branch in the config file (with an option to do it for each branch in the repo now)?
  @spec pull_url(pull_request, gitlog_struct) :: String.t()
  def pull_url(%{number: number}, %Gitlog{user: user, project: project}) do
    "#{@github_url}/#{user}/#{project}/pull/#{number}"
  end

  @spec process_pull_request_stream(Stream.default()) :: [pull_request]
  def process_pull_request_stream(pull_request_stream) do
    pull_request_stream
    |> Enum.concat()
    |> Enum.map(&parse_pull_request/1)
  end

  @spec clone_project(gitlog_struct, String.t()) :: {String.t(), integer}
  def clone_project(struct, clone_dir \\ @clone_dir) do
    # url = "#{@github_url}/#{user}/#{project}.git"
    # TODO Consider changing this to use ssh
    url = github_repo_url(struct)
    {_clone_output, 0} = System.cmd("git", ["clone", url], cd: clone_dir)
  end

  @spec remove_project(gitlog_struct) :: [String.t()]
  def remove_project(struct) do
    struct
    |> clone_project_path()
    |> File.rm_rf!()
  end

  @spec get_git_shas(gitlog_struct) :: [String.t()]
  def get_git_shas(struct) do
    path = clone_project_path(struct)
    {git_shas, 0} = System.cmd("git", ["log", "--format='%H'"], cd: path)

    git_shas
    |> String.replace("'", "")
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
  end

  @spec check_url(gitlog_struct) :: :ok | :error
  def check_url(struct) do
    httpc_request = {'#{github_repo_url(struct)}', maybe_add_auth_headers(struct)}

    response = :httpc.request(:get, httpc_request, @httpc_options, [])

    case response do
      {:ok, {{_, 200, _}, _, _}} -> :ok
      _ -> :error
    end
  end

  @spec maybe_add_auth_headers(gitlog_struct) :: [{charlist(), charlist()}]
  defp maybe_add_auth_headers(%Gitlog{auth: nil}), do: @default_headers

  defp maybe_add_auth_headers(%Gitlog{auth: auth}) do
    auth_header = {'Authorization', 'Basic #{:base64.encode(auth)}'}
    [auth_header | @default_headers]
  end

  @spec download_pull_requests(gitlog_struct, integer()) :: nil | {String.t(), integer()}
  defp download_pull_requests(struct, number) do
    httpc_request = {'#{pr_url(struct, number)}', maybe_add_auth_headers(struct)}

    result = :httpc.request(:get, httpc_request, @httpc_options, [])

    case result do
      {:ok, {{_, 200, _}, _, body}} ->
        case Jason.decode!(body) do
          [] -> nil
          json_body -> {json_body, number + 1}
        end

      {:ok, {{_, 404, _}, _, _}} ->
        IO.puts(:stderr, IO.ANSI.format([:red, "ERROR: 404 not found"], true))
        nil

      _ ->
        IO.puts(:stderr, IO.ANSI.format([:red, "ERROR: Invalid url"], true))
        nil
    end
  end

  @spec parse_pull_request(%{}) :: pull_request
  defp parse_pull_request(%{
         "number" => number,
         "body" => body,
         "merge_commit_sha" => merge_commit_sha,
         "merged_at" => merged_at,
         "head" => %{"ref" => head_ref, "sha" => head_sha},
         "base" => %{"ref" => base_ref, "sha" => base_sha}
       }) do
    %{
      number: number,
      body: body,
      merge_commit_sha: merge_commit_sha,
      head_ref: head_ref,
      head_sha: head_sha,
      base_ref: base_ref,
      base_sha: base_sha,
      merged_at: merged_at
    }
  end

  # def load_merged_pr_data() do
  #   file = "full_elixir_lang_pull_data.json"

  #   file
  #   |> File.read!()
  #   |> Jason.decode!()
  #   |> Enum.map(&load_pull_requests/1)
  #   |> Enum.filter(&(&1.merged_at))
  #   # base_sha
  #   # head_sha
  #   # merge_commit_sha
  # end
  #
  # defp load_pull_requests(%{"number" => number,
  #                          "body" => body,
  #                          "merge_commit_sha" => merge_commit_sha,
  #                          "head_ref" => head_ref,
  #                          "head_sha" => head_sha,
  #                          "base_ref" => base_ref,
  #                          "base_sha" => base_sha,
  #                          "merged_at" => merged_at}) do
  #   %{number: number,
  #    body: body,
  #    merge_commit_sha: merge_commit_sha,
  #    head_ref: head_ref,
  #    head_sha: head_sha,
  #    base_ref: base_ref,
  #    base_sha: base_sha,
  #    merged_at: merged_at}
  # end

  # pull_head_shas |> MapSet.size => 3522
  # pull_merge_shas |> MapSet.size => 3523
  # pull_master_shas |> MapSet.size => 2746
  # MapSet.intersection(git_shas, pull_head_shas) |> MapSet.size => 1863
  # MapSet.intersection(git_shas, pull_master_shas) |> MapSet.size => 2746
  # MapSet.intersection(git_shas, pull_merge_shas) |> MapSet.size => 1725
  # matches = Gitlog.load_merged_pr_data |> Enum.filter(&(MapSet.intersection(MapSet.new([&1.base_sha, &1.head_sha, &1.merge_commit_sha]), git_shas) |> MapSet.size > 0))
  # no_matches = Gitlog.load_merged_pr_data |> Enum.filter(&(MapSet.intersection(MapSet.new([&1.base_sha, &1.head_sha, &1.merge_commit_sha]), git_shas) |> MapSet.size == 0))
  # Gitlog.load_merged_pr_data |> Enum.filter(&(MapSet.member?(MapSet.new(git_shas), &1.merge_commit_sha)) ) |> length # => 0 -- therefor, merge_commit_shas are never in the master branch (not sure why)
  # MapSet.difference(MapSet.new(base_sha_matches), MapSet.new(head_sha_matches)) #=> only a single difference between the two, from way back when in 2014
  #
  #
end
