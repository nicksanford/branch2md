defmodule Branch2Md.Repo do
  @cache_dir Application.get_env(:branch2md, :cache_dir)
  @github_clone_url Application.get_env(:branch2md, :github_clone_url)

  @spec extract_commit_shas(Branch2Md.t()) :: [String.t()]
  def extract_commit_shas(struct = %Branch2Md{}) do
    _ = File.mkdir(clone_path())

    _ = remove(struct)

    {_, 0} = clone(struct)
    {_, 0} = checkout(struct)
    shas = commit_shas(struct)

    _ = remove(struct)

    shas
  end

  @spec clone(Branch2Md.t()) :: {String.t(), 0}
  defp clone(struct) do
    url = github_repo_clone_url(struct)
    {_clone_output, 0} = System.cmd("git", ["clone", url], cd: clone_path())
  end

  @spec checkout(Branch2Md.t()) :: {String.t(), 0}
  defp checkout(struct = %Branch2Md{branch: branch}) do
    {_clone_output, 0} = System.cmd("git", ["checkout", branch], cd: clone_path(struct))
  end

  @spec remove(Branch2Md.t()) :: [String.t()]
  defp remove(struct) do
    struct
    |> clone_path()
    |> File.rm_rf!()
  end

  @spec commit_shas(Branch2Md.t()) :: [String.t()]
  defp commit_shas(struct) do
    {git_shas, 0} = System.cmd("git", ["log", "--format='%H'"], cd: clone_path(struct))

    git_shas
    |> String.replace("'", "")
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
  end

  @spec github_repo_clone_url(Branch2Md.t()) :: String.t()
  defp github_repo_clone_url(%Branch2Md{user: user, project: project}) do
    "#{@github_clone_url}:#{user}/#{project}.git"
  end

  @spec clone_path() :: String.t()
  defp clone_path() do
    Path.join([System.tmp_dir!(), @cache_dir])
  end

  @spec clone_path(Branch2Md.t()) :: String.t()
  defp clone_path(%Branch2Md{project: project}) do
    Path.join([System.tmp_dir!(), @cache_dir, project])
  end
end
