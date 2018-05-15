defmodule Gitlog.CLI do
  @check_url_error "Project either doesn't exist or you don't have permission to access it with the authentication creds provided."

  @spec main([String.t()]) :: none() | :ok
  def main(argv) do
    :ok = :inets.start()

    argv
    |> parse_args()
    |> process()
  end

  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb"]
      { :default, false, "https://github.com/octokit/octokit.rb", nil }

      iex> Gitlog.CLI.parse_args ["-a", "auth", "https://github.com/octokit/octokit.rb"]
      { :default, false, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-a", "auth"]
      { :default, false, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["-c", "https://github.com/octokit/octokit.rb"]
      { :default, true, "https://github.com/octokit/octokit.rb", nil }

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-c"]
      { :default, true, "https://github.com/octokit/octokit.rb", nil }

      iex> Gitlog.CLI.parse_args ["-c", "https://github.com/octokit/octokit.rb", "-a", "auth"]
      { :default, true, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["-a", "auth", "-c", "https://github.com/octokit/octokit.rb"]
      { :default, true, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["-r", "https://github.com/octokit/octokit.rb"]
      {:report,  false, "https://github.com/octokit/octokit.rb", nil }

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-r"]
      {:report, false, "https://github.com/octokit/octokit.rb", nil }

      iex> Gitlog.CLI.parse_args ["-a", "auth", "https://github.com/octokit/octokit.rb", "-r"]
      {:report,  false, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-r", "-a", "auth" ]
      {:report,  false, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["-c", "-a", "auth", "https://github.com/octokit/octokit.rb", "-r"]
      {:report,  true, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-r", "-a", "auth", "-c"]
      {:report,  true, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-r", "-c", "-a", "auth"]
      {:report,  true, "https://github.com/octokit/octokit.rb", "auth" }

      iex> Gitlog.CLI.parse_args ["-a", "auth", "https://github.com/octokit/octokit.rb", "something else"]
      :help

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-a", "auth", "-h"]
      :help

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-a", "auth", "--help"]
      :help

      iex> Gitlog.CLI.parse_args ["--help", "https://github.com/octokit/octokit.rb", "-a", "auth"]
      :help

      iex> Gitlog.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-s", "something"]
      :help
  """
  # UX: By default, no cache, -c use cache create it if it doesn't exist

  # TODO I might need to be able to specify both wither the project is on github or local
  # TODO check whether displaying the list by merged_at as well as by the order in
  #     the sha length.
  @spec parse_args([String.t()]) ::
          {:default | :report, boolean(), String.t(), String.t() | nil} | :help
  def parse_args(argv) do
    {flags, params, invalid} =
      OptionParser.parse(
        argv,
        strict: [cache: :boolean, auth: :string, report: :boolean],
        aliases: [a: :auth, r: :report, c: :cache]
      )

    sorted_flags = Enum.sort(flags)

    case {sorted_flags, params, invalid} do
      {[auth: auth, cache: true, report: true], [maybe_url], []} ->
        {:report, true, maybe_url, auth}

      {[auth: auth, report: true], [maybe_url], []} ->
        {:report, false, maybe_url, auth}

      {[auth: auth, cache: true], [maybe_url], []} ->
        {:default, true, maybe_url, auth}

      {[cache: true, report: true], [maybe_url], []} ->
        {:report, true, maybe_url, nil}

      {[report: true], [maybe_url], []} ->
        {:report, false, maybe_url, nil}

      {[cache: true], [maybe_url], []} ->
        {:default, true, maybe_url, nil}

      {[auth: auth], [maybe_url], []} ->
        {:default, false, maybe_url, auth}

      {[], [maybe_url], []} ->
        {:default, false, maybe_url, nil}

      _ ->
        :help
    end
  end

  @spec process({:default | :report, boolean(), String.t(), String.t() | nil}) :: :ok
  def process({command, cache?, maybe_url, auth}) do
    case parse_user_project(maybe_url) do
      {:ok, {user, project}} ->
        struct = %Gitlog{user: user, project: project, auth: auth, cache: cache?}

        case Gitlog.check_url(struct) do
          :ok ->
            process(struct, command)

          :error ->
            put_error(@check_url_error)
        end

      {:error, message} ->
        put_error(message)
    end
  end

  def process(:help) do
    IO.puts(:stderr, """
    usage: gitlog <github_url> [ -a auth ] [ -r | --report ] [ -c | --cache ]
    """)
  end

  @spec process(Gitlog.gitlog_struct(), :default | :report) :: :ok
  def process(struct, :default) do
    struct
    |> Gitlog.collect_pull_requests()
    |> Enum.to_list()
    |> Enum.concat()
    |> Jason.encode!()
    |> IO.puts()
  end

  def process(struct, :report) do
    struct
    |> Gitlog.get_and_filter_prs()
    |> Jason.encode!()
    |> IO.puts()
  end

  @doc """
  Parses the given `string` into a {:ok, {username, project}} tuple.

  ## Examples:

      iex> Gitlog.CLI.parse_user_project("https://github.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Gitlog.CLI.parse_user_project("git@github.com:elixir-lang/elixir.git")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Gitlog.CLI.parse_user_project("https://github.com/elixir-lang/elixir.git")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Gitlog.CLI.parse_user_project("http://github.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Gitlog.CLI.parse_user_project("github.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Gitlog.CLI.parse_user_project("elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Gitlog.CLI.parse_user_project("ithub.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Gitlog.CLI.parse_user_project("ithub.com/elixir-lang/elixir.git")
      {:ok, {"elixir-lang", "elixir"}}

  Returns an error tupple if parsing fails:

      iex> Gitlog.CLI.parse_user_project("https://github.com/elixir-lang-elixir.git")
      {:error, "Invalid github project string provided. Example: https://github.com/elixir-lang/elixir"}

      iex> Gitlog.CLI.parse_user_project("elixirlang-elixir")
      {:error, "Invalid github project string provided. Example: https://github.com/elixir-lang/elixir"}

      iex> Gitlog.CLI.parse_user_project("github/elixir-lang/elixir")
      {:error, "Invalid github project string provided. Example: https://github.com/elixir-lang/elixir"}

  """
  @spec parse_user_project(String.t()) :: {:ok, {String.t(), String.t()}} | {:error, String.t()}
  def parse_user_project(string) do
    maybe_username_project_tuple =
      string
      |> String.split(".com/")
      |> List.last()
      |> String.split(".com:")
      |> List.last()
      |> String.split(".git")
      |> List.first()
      |> String.split("/")
      |> List.to_tuple()

    case maybe_username_project_tuple do
      {username, project} ->
        {:ok, {username, project}}

      _ ->
        {:error,
         "Invalid github project string provided. Example: https://github.com/elixir-lang/elixir"}
    end
  end

  @spec put_error(String.t()) :: :ok
  defp put_error(error) do
    IO.puts(:stderr, IO.ANSI.format([:red, "ERROR: " <> error], true))
  end
end
