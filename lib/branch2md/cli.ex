defmodule Branch2Md.CLI do
  @spec main([String.t()]) :: :ok
  def main(argv) do
    argv
    |> parse_args()
    |> process()
  end

  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples
      iex> Branch2Md.CLI.parse_args ["-b", "feature-branch", "https://github.com/octokit/octokit.rb"]
      {nil, "feature-branch", "https://github.com/octokit/octokit.rb"}

      iex> Branch2Md.CLI.parse_args ["-b", "feature-branch", "-a", "auth", "https://github.com/octokit/octokit.rb"]
      {"auth", "feature-branch", "https://github.com/octokit/octokit.rb"}

      iex> Branch2Md.CLI.parse_args ["https://github.com/octokit/octokit.rb"]
      :help

      iex> Branch2Md.CLI.parse_args ["-a", "auth", "https://github.com/octokit/octokit.rb"]
      :help

      iex> Branch2Md.CLI.parse_args ["-a", "auth", "https://github.com/octokit/octokit.rb", "something else"]
      :help

      iex> Branch2Md.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-a", "auth", "-h"]
      :help

      iex> Branch2Md.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-a", "auth", "--help"]
      :help

      iex> Branch2Md.CLI.parse_args ["--help", "https://github.com/octokit/octokit.rb", "-a", "auth"]
      :help

      iex> Branch2Md.CLI.parse_args ["https://github.com/octokit/octokit.rb", "-s", "something"]
      :help
  """
  @spec parse_args([String.t()]) ::
          {:default | :report, boolean(), String.t(), String.t() | nil} | :help
  def parse_args(argv) do
    {flags, params, invalid} =
      OptionParser.parse(
        argv,
        strict: [auth: :string, branch: :string],
        aliases: [a: :auth, b: :branch]
      )

    sorted_flags = Enum.sort(flags)

    case {sorted_flags, params, invalid} do
      {[auth: auth, branch: branch], [maybe_url], []} ->
        {auth, branch, maybe_url}

      {[branch: branch], [maybe_url], []} ->
        {nil, branch, maybe_url}

      _ ->
        :help
    end
  end

  @spec process(:help | {String.t() | nil, String.t() | nil, String.t()}) :: :ok
  defp process({auth, branch, maybe_url}) do
    case parse_user_project(maybe_url) do
      {:ok, {user, project}} ->
        struct = %Branch2Md{user: user, project: project, auth: auth, branch: branch}

        case Branch2Md.check_url(struct) do
          :ok ->
            run(struct)

          {:error, check_url_error} ->
            put_error(check_url_error)
        end

      {:error, message} ->
        put_error(message)
    end
  end

  defp process(:help) do
    IO.puts(:stderr, """
    usage: branch2md <github_url> < -b | branch > [ -a auth ]
    """)

    System.halt(2)
    :ok
  end

  @spec run(Branch2Md.t()) :: :ok
  defp run(struct) do
    struct
    |> Branch2Md.render_prs()
    |> IO.write()
  end

  @doc """
  Parses the given `string` into a {:ok, {username, project}} tuple.

  ## Examples:

      iex> Branch2Md.CLI.parse_user_project("https://github.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Branch2Md.CLI.parse_user_project("git@github.com:elixir-lang/elixir.git")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Branch2Md.CLI.parse_user_project("https://github.com/elixir-lang/elixir.git")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Branch2Md.CLI.parse_user_project("http://github.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Branch2Md.CLI.parse_user_project("github.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Branch2Md.CLI.parse_user_project("elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Branch2Md.CLI.parse_user_project("ithub.com/elixir-lang/elixir")
      {:ok, {"elixir-lang", "elixir"}}

      iex> Branch2Md.CLI.parse_user_project("ithub.com/elixir-lang/elixir.git")
      {:ok, {"elixir-lang", "elixir"}}

  Returns an error tupple if parsing fails:

      iex> Branch2Md.CLI.parse_user_project("https://github.com/elixir-lang-elixir.git")
      {:error, "Invalid github project string provided. Example: https://github.com/elixir-lang/elixir"}

      iex> Branch2Md.CLI.parse_user_project("elixirlang-elixir")
      {:error, "Invalid github project string provided. Example: https://github.com/elixir-lang/elixir"}

      iex> Branch2Md.CLI.parse_user_project("github/elixir-lang/elixir")
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

  @spec put_error(String.t()) :: no_return()
  defp put_error(error) do
    IO.puts(:stderr, IO.ANSI.format([:red, "ERROR: " <> error], true))
    System.halt(2)
  end
end
