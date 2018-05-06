# Branch2Md

Branch2Md is a tool that generates a rough draft of a `CHANGELOG`
for a continuous integration workflow.

It does this by creating a markdown description of pull requests
which have been merged into a given branch on a github repository derived from
messages that contributors are already writing in their pull requests.

## Quick Start
`branch2md -a GITHUB_USER_NAME:GITHUB_AUTH_TOKEN -b master https://github.com/whitfin/cachex > cachex.md`

An example of what cachex.md will look like can be found under [examples](https://github.com/nicksanford/branch2md/tree/master/examples/cachex.md)

## Installation
1. Ensure you have [git](https://git-scm.com/book/en/v2/Getti$g-Started-Installing-Git), [wget](https://www.gnu.org/software/wget/), and [erlang ~> 19](http://www.erlang.org/downloads) installed (the cli is an [elixir escript](https://hexdocs.pm/mix/master/Mix.Tasks.Escript.Build.html), hence the need for the erlang runtime).
2. Download the escript `wget https://raw.githubusercontent.com/nicksanford/branch2md/master/branch2md`
3. Make the escript executable `chmod +x branch2md`
4. Running it should output instructions for how to run it:
```
$ ./branch2md
usage: branch2md <github_url> <-b | branch>  [ -a | auth ]
```

## Description
branch2md can be used as a tool to minimize the manual work needed in a CI/CD workflow
for everyone in the team to keep track of changes happening in long lived branches.

The descriptions are generated from the title & body of all pull requests that
have been merged into the branch.

The descriptions are ordered by the date in which they are merged.

branch2md is a well behaved unix program (with user feedback output to stderr
and results output to stdout).

## Tips
1. If you are running this against large github projects
(like the elixir language in the [examples](https://github.com/nicksanford/branch2md/tree/master/examples)) you are probably going to want to use your
[github personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)
(as github's ratelimit for frequent un-authenticated calls to  their apis is 
much lower then their authenticated calls).

## Limitations / Future Improvements / TODOs
1. Currently only pull requests from the same repo are supported. In my testing
I found that pull requests from forks are not returned from the github api from
the non forked repository.
Given that this tool is mainly meant for small teams where everyone in the team
is making pull requests from branches in the same repo, adding support for pull
requests from forked repos is currently considered a nice to have.
If support were to be added the first place I would look would be either git or
github's commit api, and then make requests to all forked repos' pull request api
endpoints as well to gather their pull requests, and cross refference the commits
from those forked repos' PRs with the commits of the target repo's branches.

2.  Currently this project generates a markdown file description of a single branch,
however, frequently it is useful to get a snapshot of multiple branches w/o needing
to run the command multiple times. For that reason, a possible future improvement
is to allow multiple branches to be specified, and if they are, rather than
writing to stdout, a directlry will be creeated with an index.md which links
(relatively) to markdown files with the names of the branches.

3. Currently the calls to download requests occur sequentially because I haven't
found a way to find out how many pull reqests there are in a project without
iterating throught their
[entire paginated api](https://developer.github.com/v3/pulls/). This could
probaby be optimized by chunking the requests into batches of 10 pages run in
prallel, which would stop when one of the pages returned fewer than the expected
number of results. This would speed up the pull request fetching phase (currently
the main performance bottleneck for large projects).

4. Currently there are no end to end tests, I would like, in the future to add
some basic http mocking by swaping out a mock module & verifiy the resulting
markdown file.

5. Currently if failures are encountered during download of pull requests,
System.halt will be called. Ideally we would only like that to occur if this is
running as a cli. That could be achieved by having Branch2Md return a struct
that represents what side effects should occur (other than http requests) and
the cli.ex would parse that struct and perform the required actions.

## Development

### Building
```
mix deps.get
mix escript.build
```

### Running tests
```
mix test
```

### Running dialyzer
```
mix dialyzer
```
