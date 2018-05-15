# GithubRender

**TODO: Add description**

#TODO
1. Make elixir tool useful i.e. give it a cli with the commands
  - Extract all pull requests (raw dump)
  - Extract all pull requests (processed)
2. Figure out how to get ALL commits in the repo
3. Confirm
3. Be able to output all the shas of PR messages that can't be matched up
4. Be able to produce, for any github repo, a check that by following the
base_url of every PR, one is able to map each PR (or the vast majority of them)
to the master branch. Basically reproduce what you have in the jupyter notebook
in elixir.
6. Speed up pull request pull

## Description
This project takes the PR history of a github project and outputs a markdown
file that describes the PR history of a given branch.

The usecase this is primarily meant to solve is to allow the main PR comment
history to be brought in to the github project and rendered into a markdown
format changelog of what has gone into each branch. 

This can be used as a tool to minimize the manual work needed in a CI/CD workflow
for everyone to keep track of what is in the develop & master branches.


1. Bring data from github api for PR mergers into git history (in a datastructure).
2. Be able to render said datastructure for any github project (that you can auth with).


# Notes (work in progress):
## Objective:
1. Bring data from github api for PR mergers into git history (in a datastructure).
2. Be able to render said datastructure for any github project (that you can auth with).

This should be useful for any github project.

Question:
Is this a renderer i.e. representation of current state, or a log / ledger i.e.
an immutable historical record or past events.

Idea:
I don't think that it can be a log / ledger b/c git history can be rewritten.
I am pretty sure this is a renderer, a way to allow others to visualize the
content of every branch in it's current state.

For that reason, maybe to start, we define the branches that we want to know
about, & then render this for that branch.

Maybe we keep an index file, that links to the state of each branch. That seems
simple.

Or maybe we keep a single file, that has subsections for each branch (maybe kept
in the order present in the config).

TODO: Learn more about how git works under the hood as I think that my ability
to build this project is somewhat limited by my understanding of how git works
under the hood.

Question:
Should one go from:
1. branches -> pull PRs for each branch.
2. pull PRs -> figure out branch history

2 is probably easier, so I will try that one first.

I am now able to download closed pull requests & pull out data that looks like:
```
{
  "number": 7478,
    "body": "Related to #7474.",
    "merge_commit_sha": "c2e92c28477a4e4f708a5683941671c3656aedc7",
    "head_ref": "al/logger-bad-data",
    "merged_at": "2018-03-24T13:08:20Z",
    "head_sha": "92162f5738763654187151d4ddfed316f18c1ebc",
    "base_ref": "master",
    "base_sha": "5947ed751eb0276cb7fda666c319dba451a5e9e7"
}
```

```
# Forthe URL, cut everything left of github.com including "/" or ":", cut everything including & to the right of '.'
cli --auth --username --project --url(default) https://github.com/elixir-lang/elixir
```

```
"curl -u USERNAME:KEY https://api.github.com/repos/USERNAME/PROJECT/pulls?state=closed" | jq 'map({body: .body, merge_commit_sha: .merge_commit_sha, head_ref: .head.ref, merged_at: .merged_at, head_sha: .head.sha, base_ref: .base.ref, base_sha: .base.sha})'

# You will need to make one request after the other, stopping only when you get
# back a list that is less than the per_page number.
curl "https://api.github.com/repos/elixir-lang/elixir/pulls?state=closed&page=1&per_page=100" | jq 'map({number: .number, body: .body, merge_commit_sha: .merge_commit_sha, head_ref: .head.ref, merged_at: .merged_at, head_sha: .head.sha, base_ref: .base.ref, base_sha: .base.sha})' > elixir_merge_data.json

git log --all --format="%H" > ../gitlog/all_shas
```


## Objective:
Changelog for continuous integration workflow.

I want a human readable, textual representation of what features are present
in the github repo (mainly master & develop).

In the future I would like to be able to designate, certain branches as
`code branches` (initially `master` & `develop`). I would like for if any of
those branches change, for the code to be deployed to the environment it is 
configured to deploy to (master would deploy to prod, develop & any other
`code branches` would most likely deploy to dev enviornments.

Develop deployed to an environment where it can be used.

And ideally, any feature branch deployed to an environment where it can be used.

I want to be able to cross refference what is running in the environment, with 
a textual description of what is in it.

Ideally, as soon as a PR is opened against develop or master, it is tested, 
built & run in a docker container.

As soon as the PR is closed (for any reason), the docker image is torn down.

If the PR changes, the entire suite should be rerun


## Notes:

What I have found so far:

The way you can determine if a pull request is being merged into master is by
listning for an object that matches

```{"action": "closed", "pull_request": {"base": {"ref": "master"}}}```

Once that is found, you can grab the sha of the merge commit.

Another option is to just listen for all merges into develop and just append
the message from each PR merged into develop to a file.

```{"action": "closed", "pull_request": {"base": {"ref": "develop"}}}```

That way you have an always up to date record of `what is in develop`, which
is probably more useful than having an up to date report on master, which you 
only get to see after you have already deployed it.

Maybe when the merge into master happens, all that is done is stamp the develop
commits as now having latest master.

TODO Maybe we will need to consider hotfixes i.e. merges directly into master
that did not make their way into develop. How can we handle those?

Also, when a tag is created, we should stamp the log with that, if it is a
release tag.

https://stackoverflow.com/questions/26914819/create-a-github-webhook-for-when-a-pull-request-is-accepted-merged-to-master
cat gitlog.json | jq 'map(select(.action == "closed")) | .[] | select(.pull_request.base.ref == "master")'

## Ways of doing this

1. Event sourcing
  - be able to generate datastructure describing the log messages from any git repo.
  - be able to then render said datastructure.

  You could actually use both of these in the same implementation & see which
  one is better. 1 is (probably) going to be more expensive, but will probably
  be more consistent.

  2 is probably going to be more fragile, but more efficient.
2. Event based
  - assumes that the application receives every webhook, if the
  application is ever down, it means that the log is inaccurate & can't get
  back into a correct state.
  - more efficient that recomputing the world every time
  - already made some progress with this
  - doesn't need to be a webserver, could just be a cli application,
    maybe run via cron or with it's own timer

## Rendering options:
1. Definitly want to produce markdown
2. Not sure if I want to publish this via github pages or github wiki wiki

## Config options:
1. Define a config:

```
config = {
  "branches": ["master", "develop"] #maybe tags could also exist.
}

state = {
  "release_branches": ["master": {"sha": "72fcf9ed19e0fd99de9443d993c29d457d189a63"}, "other_master"]
}
```

```
1. Get hook, determine if it is for a PR merge
2. If it is, then determine if it is into the develop or master branches
3. If it is into the develop branch, collect the message from the merge, and add it datastructure
4. If it is into the master branch, collect 
5. Create a rendering engine to generate 
```
