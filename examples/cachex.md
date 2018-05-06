# [Cachex](https://github.com/whitfin/cachex)

## Branch Timeline:

### master


#### [#184] - (2018-05-19T22:41:16Z) - [Enum.find_value instead of Enum.find](https://github.com/whitfin/cachex/pull/184)

I believe according to the @spec, the method should use Enum.find_value instead of Enum.find in order to return the pid and not the whole tuple.

#### [#183] - (2018-05-14T20:22:37Z) - [get_and_update/4 typespec is incorrect #182](https://github.com/whitfin/cachex/pull/183)

The typespec indicates that this function returns a tuple of :ok or :error,
but in fact it returns :commit or :ignore tuples.

Updates the typespec return.

#### [#180] - (2018-04-23T17:00:31Z) - [Typo in TTL Implementation documentation.](https://github.com/whitfin/cachex/pull/180)

Better meaning for describing the TTL implementation of Cachex.

`realiability` to `reliability`

#### [#173] - (2018-02-20T01:50:36Z) - [Migrate from Benchfella to Benchee](https://github.com/whitfin/cachex/pull/173)

Benchee appears to be the more popular library recently, so this PR will just migrate the existing benchmarks over. It adds an alias to still provide `mix bench`.

#### [#172] - (2018-02-19T23:56:04Z) - [Update documentation to align with latest features](https://github.com/whitfin/cachex/pull/172)

This fixes #145.

Mainly just a bunch of documentation updates in the guides to make sure they're still in sync with the library after all of the churn in the v3 cycle.

#### [#171] - (2018-02-19T06:07:12Z) - [Refactor streaming to allow for match queries](https://github.com/whitfin/cachex/pull/171)

This fixes #137 and fixes #152.

This will refactor the streaming API into a more appropriate ETS matching style in order to allow for filtering to be handled by ETS rather than in the Elixir layer. It also now respects the expiration times of entries by default (and thus does not return them). 

This is also the final piece in removing `Cachex.Util` as all query matching has been moved to `Cachex.Query`.

#### [#170] - (2018-02-18T20:41:13Z) - [Minor sweep of documentation updates](https://github.com/whitfin/cachex/pull/170)

This fixes #168. Just a minor sweep of the main interface documentation, along with suppressing generation of the action docs.

#### [#169] - (2018-02-18T19:35:47Z) - [Normalize stats and remove :missing tags](https://github.com/whitfin/cachex/pull/169)

This fixes #128 and fixes #151. 

This will normalize statistics to be a lot clearer and follow a simple (and faster) approach to modifications. It's a lot easier to work with, and makes a lot more sense given why people track cache state in the first place. Due to this, the `:missing` tag has been removed in favour of just treating `nil` as a missing value. This has almost no impact, except there's a rare edge case with false positives on `incr` counting as a fresh write when it's actually an update; but I believe this is a fair trade-off for the simplification on everything else.

This will also (finally) make the stats tests use actual actions, rather than mocking directly to the GenServer calls. 

#### [#167] - (2018-02-12T03:09:42Z) - [Introduce cache warming functionality](https://github.com/whitfin/cachex/pull/167)

This fixes #97 (finally!).

This PR will add `Cachex.Warmer` which provides a behaviour for cache warming. Warmers can be attached to a cache to populate the backing tables on interval, and can populate many keys at once (making them a better fit in a few situations).

#### [#165] - (2018-02-09T21:06:54Z) - [Split out module based properties from hook records](https://github.com/whitfin/cachex/pull/165)

This fixes #150.

This will remove a lot of the extra fields in the `hook` record with a module behaviour that hooks should implement. It's a little more restrictive in that you can't override the same hook with different options, but that should have been rare anyway.

This should be no slower than previously, and likely faster in a lot of cases due to compiling into constants on the module and the lower amounts of copies happening.

It also enables timeouts on asynchronous hooks too, as this was previously missing (which I consider a bug to be honest).

#### [#164] - (2018-02-01T21:00:19Z) - [Migate Cachex.set/4 to Cachex.put/4](https://github.com/whitfin/cachex/pull/164)

This fixes #160.

All calls to `set/4` or `set_many/3` are now `put/4` or `put_many/3`. The old `set` and `set_many` signatures are left around for backwards compatibility, because I'm a nice guy. They're just delegates which are deliberately hidden from the documentation. It could be that we want to add them to the docs to discuss deprecation... but I can do that later. 

No plans on actually removing the delegates at this point; they're very little code noise so it is what it is.

#### [#163] - (2018-01-28T18:02:27Z) - [Refactor various utility functions out of Cachex.Util](https://github.com/whitfin/cachex/pull/163)

This fixes #153.

This moves utility functions closer to the places they're relevant. The intent is to fully remove `Cachex.Util` and this will likely happen when queries are cleaned up for ETS. 

#### [#161] - (2018-01-18T17:39:26Z) - [Add an initial implementation of set_many/3](https://github.com/whitfin/cachex/pull/161)

This will fix #157.

This adds a new implementation for `set_many/3`, which allows an atomic insertion of a batch of values. The second argument must be a list of key/value pairs to insert, and will error if this isn't correct. 

All behaviour is the same as `set/4`, except for multiple items at once (so TTLs stay the same).

#### [#159] - (2018-01-16T16:13:56Z) - [Remember to import Cachex.Spec when using limit record](https://github.com/whitfin/cachex/pull/159)

Hi, great lib. Took me a moment to realize where is that limit() coming from so I wanted to save that moment for other people.

I also needed to use github version in my mix.env, I'm assuming it's just that the mix version is out of date? Would be nice to bump a version and push since most people will use doc pages linked in README.

Keep up the great work.

#### [#156] - (2017-12-12T06:00:09Z) - [Add the ability to whitelist hook actions](https://github.com/whitfin/cachex/pull/156)

This fixes #146.

This adds a new `:actions` field to the Hook record to allow whitelisting actions to be sent to the hook. This can be used (and is in the LRW hook) to reduce the number of messages sent to a hook in the case they're not needed.

The actions field can be `nil`, in which case all actions will notify the hook.

#### [#155] - (2017-12-07T07:35:55Z) - [Introduce the notion of synchronized fallbacks](https://github.com/whitfin/cachex/pull/155)

This fixes #96. 

This will introduce a new courier service which will only execute a single fallback for a given key at once, rather than running multiple on top of each other. If a fallback executes whilst one is in progress, it will simply await the result of the existing task.

This does not allow the case where multiple fetches on the same key execute at the same time but with different fallback functions, but this is such an anti-pattern that I doubt it'll ever be an issue. There's a way to solve this by re-queuing tasks that have a different function (which also means we need to move to `apply()`), but it's more complicated and less performant... so we'll only do as necessary (i.e. if people request it often enough). 

#### [#147] - (2017-11-30T03:22:24Z) - [Replace structs with records and simplify state interactions](https://github.com/whitfin/cachex/pull/147)

This turned into a monster and I hate myself. It will replace structs internally with records, seeing as really don't need the advantages of structs. It nerfs a bunch of existing stuff in favour of new stuff which need documenting in #145.

It improves the interface for policies and limits, allowing you to start external services as required rather than just assume that everything can operate as a hook. 

It removes all constants in favour of a single `Spec` module which provides macros to define constants, which appears to be a less horrible pattern. 

Other than that, a bunch of options changes, dropped support for things that make this difficult (where appropriate) and just general refactoring as I went. This is basically a dev branch rather than a feature branch at this point.

This fixes #144 and #143.

#### [#142] - (2017-11-17T01:15:33Z) - [Add options to the Limit structures](https://github.com/whitfin/cachex/pull/142)

This fixes #141.

This PR will add support for arbitrary options being passed to Limit structures; this is done to allow the `batch_size` option being passed through to the LRW policy to control the size of batches being deleted. It will now default to 100, but can be configured manually if needed. Options are specific to each policy, to avoid coupling them all together.

#### [#140] - (2017-11-15T23:09:22Z) - [Enable default fetch functions on a cache](https://github.com/whitfin/cachex/pull/140)

This fixes #129.

We're keeping the default fallback behaviour to ease migration, and it operates on `fetch/2` only. This will just use an explicit function, or the one from the cache state if missing. If both are missing, an error will be returned. 

#### [#139] - (2017-11-15T19:00:58Z) - [Migrate Cachex.State into Cachex.Cache/Overseer](https://github.com/whitfin/cachex/pull/139)

This fixes #134.

This will split `Cachex.State` into the `Overseer` service which deals with the tables and transactions, and `Cachex.Cache` which just holds the struct models. This makes it easier to understand and also aligns with the services model the repository has been moving to.

#### [#135] - (2017-11-14T21:01:08Z) - [Create a common services layer for app/cache level](https://github.com/whitfin/cachex/pull/135)

This fixes #125.

This begins to refactor the various process around a cache into a more predictable structure. It's still not quite there but it's a start. All services are now controlled via `Cachex.Services`. It also refactors the `LockManager` stuff into less bloat and makes it more obvious for what should live where.  

#### [#133] - (2017-11-09T19:47:39Z) - [Replace the internal defwrap macro with @unsafe](https://github.com/whitfin/cachex/pull/133)

This fixes #132.

This will replace `defwrap` with the `@unsafe` library in order to make it easier to define unsafe definitions. It also removes the internal mess for the `defwrap` definition and makes it easier to define multiple function definitions in the main API.

#### [#130] - (2017-11-07T01:22:36Z) - [Add a new fetch/4 signature to handle fallbacks](https://github.com/whitfin/cachex/pull/130)

This fixes #126.

This will add a new `fetch/4` function which has an explicit fallback argument, rather than dealing with options in the `get/3` signature. This will temporarily remove default fallbacks on a cache state until they can be re-introduced after #132 is concluded.

 

#### [#123] - (2017-10-30T03:58:04Z) - [Remove requestCount from the stats plugin](https://github.com/whitfin/cachex/pull/123)

This fixes #117 by removing the `requestCount` from the stats hook. It can be filled in easily by the consumer if needed, but is just wasted space for the time being. `opCount` serves a much more generic purpose and makes much more sense.

#### [#121] - (2017-10-05T13:09:20Z) - [Typo in docs example](https://github.com/whitfin/cachex/pull/121)

This PR is a mere typo correction.

#### [#118] - (2017-07-06T21:04:13Z) - [Enable Janitor processes by default](https://github.com/whitfin/cachex/pull/118)

This fixes #108.

This PR changes the Janitor to run by default, as it was previously misleading to have a Janitor not running whilst supporting arbitrary TTLs being set. It can be disabled by setting the `:ttl_interval` option to `-1` (the same as before).

#### [#114] - (2017-04-23T23:09:34Z) - [Error when invalid fallbacks are provided](https://github.com/whitfin/cachex/pull/114)

This fixes #101.

Previously we would silently allow fallbacks with bad arity, but this could lead to subtle bugs. It's better if we just crash on the invalid arity to force the user to notice quickly and address sooner. 

#### [#110] - (2017-03-14T07:23:12Z) - [Replace :disable_ode with :ode in cache options](https://github.com/whitfin/cachex/pull/110)

This fixes #107.

Previously we had `:disable_ode` set to `true` to disable ODE, but it's better to have it just `:ode` set to `false` to be more intuitive. This will still default to having it enabled, it just feels a little more natural. 

Any value passed to `:ode` must be a boolean or it will just default to `true`.

#### [#105] - (2017-03-13T14:35:34Z) - [Improve documentation and refactor into docs directory](https://github.com/whitfin/cachex/pull/105)

Fixes #95.
Fixes #104.

This PR moves most of the documentation from inside README.md and migrates it over to the `docs/` directory to make it easier to read and also reduce the load time for the main repo page. The other advantage here is that GitHub pages can deploy directly from this folder rather than from a static definition.

It also includes these files into the documentation generation when using `mix docs` to ensure they'll be loaded onto Hexdocs correctly.

#### [#100] - (2017-03-03T08:06:06Z) - [Implement dump/load for cache disk backups](https://github.com/whitfin/cachex/pull/100)

This fixes #92.

This PR will allow the user to manually dump/load a cache to/from disk in order to persist data between instances of a cache. In future this might be baked in as a scheduled process, but for now it seems that manual should be sufficient. 

#### [#91] - (2016-11-16T22:29:21Z) - [Add commit return syntax to get_and_update/4](https://github.com/whitfin/cachex/pull/91)

This fixes #90.

This PR allows you to use `{ :ignore, value }` to ignore writes from `get_and_update/4` calls if you decide against writing. 

There might be a way to neaten this interface up in future, but for now the functionality is more important than the prettiness.

#### [#89] - (2016-10-10T21:40:46Z) - [Ensure all tests pass on Windows](https://github.com/whitfin/cachex/pull/89)

This fixes #88.

Introduced AppVeyor CI for Windows builds on the latest Elixir/Erlang. This is just as piece of mind to ensure that we're not missing test issues on Windows.

Incidentally, fixes a couple of things causes tests to fail due to the BEAM impl on Windows - nothing serious.

#### [#87] - (2016-10-09T23:42:00Z) - [Begin to implement custom command support](https://github.com/whitfin/cachex/pull/87)

This fixes #80.

Rather than implement specific List/Set operations, there is now a new `invoke/4` command which allows the invocation of custom commands to carry out custom actions on a value inside the cache. This currently has limited support (by design), but it may be expanded in future.

As it stands, you can add custom commands to the cache and manually implement any List/Set operations you might want (and anything else).

#### [#85] - (2016-10-04T05:37:26Z) - [Restructure the syntax required for providing fallbacks](https://github.com/whitfin/cachex/pull/85)

This fixes #84.

Changes involved:

This removes `:default_fallback` and `:fallback_args` completely. Going forward you should use a Keyword list with the `:fallback` option, which can contain the keys `:state` and `:action`. The `state` is provided as the second argument in your fallback, thus removing the `apply` overhead. If `state` is `nil`, it will not be provided. The `action` is a typical fallback functions as we know them in the 1.x line. Internally we now have a `Cachex.Fallback` struct used to store these values just to begin to future-proof a little bit.

You can still provide just a function rather than a list; internally this will become `[ action: function ]` before being parsed. This is to ease migration a little bit, but also just because it's nice to be able to inline functions.

Documentation has been updated, as well as migration, so this should be good to go pending CI.

#### [#83] - (2016-09-26T13:19:42Z) - [Introduce the ability to ignore fallback values](https://github.com/whitfin/cachex/pull/83)

This fixes #82.

This PR introduces the concept of tagged fallback values, in order to better determine when a user wishes to commit the value to the cache. It's possible that something unexpected happens in a fallback (network timeout, etc), and the user may wish to skip persisting the value. In this scenario the user can simply use `{ :ignore, value }` to return `value` back from the call, but without committing `value` into the cache. This is a great benefit as errors can be returned without being committed.

To commit your changes, you simply need to return `{ :commit, value }` and it will be written. If neither of these flags are provided, we'll assume that you're committing (this is for backwards compatibility).

This also fixes a quick bug in the stats calculations which was doubling up counts in the case of value loading.

#### [#81] - (2016-09-22T19:08:02Z) - [Add a Gitter chat badge to README.md](https://github.com/whitfin/cachex/pull/81)

### zackehh/cachex now has a Chat Room on Gitter

@zackehh has just created a chat room. You can visit it here: [https://gitter.im/cachex/Lobby](https://gitter.im/cachex/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&content=body_link).

This pull-request adds this badge to your README.md:

[![Gitter](https://badges.gitter.im/cachex/Lobby.svg)](https://gitter.im/cachex/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=body_badge)

If my aim is a little off, please [let me know](https://github.com/gitterHQ/readme-badger/issues).

Happy chatting.

PS: [Click here](https://gitter.im/settings/badger/opt-out) if you would prefer not to receive automatic pull-requests from Gitter in future.

#### [#77] - (2016-09-19T19:22:09Z) - [Migrate from GenEvent -> GenServer](https://github.com/whitfin/cachex/pull/77)

The implementation with GenEvent was clunky because Hooks would not shut down when the cache did. Moving to GenServer lets us just put Hooks directly into the same supervision tree, which is neat.

There are a few breaking changes here, but only if someone is using `handle_notify` and `handle_call` from `GenEvent`. Going forward they simply have to migrate to `GenServer` usage and return `{ :noreply, state }` rather than `{ :ok, state }` etc. 

The other thing to note is that timeouts in synchronous hooks are now finally handled on the server side rather than the client (so the server will never hang on a long timeout).

This will fix #71 and #74.

#### [#76] - (2016-09-14T22:26:40Z) - [Allow inspect to retrieve raw records](https://github.com/whitfin/cachex/pull/76)

This fixes #61.

This PR simply introduces the option to pass `{ :record, key }` to an inspect call in order to retrieve the raw record associated with a given key. I also did a little refactoring (but not much) on the memory inspection.

#### [#75] - (2016-09-14T05:21:54Z) - [Add a new touch/3 function](https://github.com/whitfin/cachex/pull/75)

This fixes #73.

Quite a simple solution; we just update the TTL time using the last known TTL coming back from `ttl/2`. If it's missing, we exit. If it's nil, we just update the touch time as-is, and if it's anything else, we touch the time and put the value in as the new TTL. It lives in a transaction for good measure.

You _could_ implement all of this using a combination of `ttl/2`, `refresh/2` and `expire/3` instead of rolling it this way (the below shows a working example):

``` elixir
case ttl(state, key) do
  { :missing, nil } ->
    { :missing, false }
  { :ok, val } ->
    refresh(state, key)
    val && expire(state, key, val)
    { :ok, true }
end
```

but there's a potential annoying condition between the refresh and expire calls. E.g. what should we do if one of them fails? Probably never going to happen, but regardless.

Anyway, rolling it like this lets it execute a tiny bit quicker.

#### [#72] - (2016-09-14T03:51:50Z) - [Rewrite test suites for better structure](https://github.com/whitfin/cachex/pull/72)

This fixes #69. 

This also fixes #67.

I took a first pass through the tests and reimplemented them to be faster, clearer, and more reliable.

There are also several places I refactored along the way (as tests showed up bugs), but there's still a long way to go before v2. 

One change worth noting is there there is a now a `Cachex.Errors` module which provides shorthand to error constants, and provides a description for atom errors so you no longer have to match on strings.

E.g. if you do `{ :error, :non_numeric_value } = incr(cache, key)` you can lookup the error using `Cachex.Errors.long_form(:non_numeric_value)`. This just means error tuples more concise instead of returning arbitrary strings.

#### [#70] - (2016-09-09T23:22:05Z) - [Stripped out Mnesia, implemented local transactions](https://github.com/whitfin/cachex/pull/70)

This fixes #64 and #66 when merged.

It should be noted that there is a lot of room for improvement here but I'm going to do it in follow-up commits due to this PR already being far too big and snowballing still.

There's a lot of documentation change that needs to happen as a result of this - and it'll happen :)

#### [#63] - (2016-09-03T01:39:05Z) - [Migrate to using { action, [args] } hook messages](https://github.com/whitfin/cachex/pull/63)

This fixes #59.

There were many places it would be convenient to match on the action taken when working from inside a hook. This was not possible to do in a function head, which made it kinda awkward. It's now possible to do so with the new format of `{ action, args_list }`. This change also guarantees that hook messages are two-element tuples, which is handy. 

In addition, this fixes #60 by tweaking the default hook type to being `:post`. This is reflected in the documentation for the time being, but I'll make it more clear by v2.x release.

#### [#62] - (2016-09-03T00:50:47Z) - [Add the initial implementation of LRW evictions](https://github.com/whitfin/cachex/pull/62)

This PR relates to #55 by implementing the ability to have a max cache size, which is enforced through a fairly low-cost LRW implementation.

Also introduced are the two new concepts of Limits and Policies.

-A Limit is quite simply a struct containing the Limits of the cache - right now this is just entry count, but I'm toying with an implementation which allows for memory bytes etc.
- A Policy is a ruleset for cache evictions when a Limit is hit. There's no behaviour for implementing these policies yet, but there should be. This will be added in future. Externally pluggable Policies will likely never be available - rather they'll all be internal to Cachex purely because a public interface for this would be difficult to maintain.

The LRW policy is clever in that it operates as a Hook into the cache, and so there's no special handling (which is awesome, no?). As far as this goes, it means that you could write your own Policy if you created a Hook version.

Although this PR doesn't contain documentation, it will come shortly (because this isn't finalised yet).

You can try out this behaviour using the following:

``` elixir
# start a cache with a limit of 500 items
# this will erase enough entries to get to 250 left in the cache (reclaim is a percentage to cull)
Cachex.start(:my_cache, [ max_size: %Cachex.Limit{ limit: 500, reclaim: 0.5 } ])

# start a cache with a limit of 500 items
# reclaim defaults to culling 10% of the cache (so you'd be left with 450 entries)
Cachex.start(:my_cache, [ max_size: 500 ])
```

#### [#52] - (2016-08-14T14:16:26Z) - [Remove the notion of remote Cachex instances](https://github.com/whitfin/cachex/pull/52)

This PR removes the notion of remote Cachex instances in favour of using fallbacks.
- All remote tests have been replaced with single tests inside the Transactional interface (as we still wish to support Transactions for the time being).
- Both the workers have been merged into a single action set, which may again change in future as it's slightly messy. 
- The Cachex Mix context has been removed as we no longer need remote nodes to test against. 

This will close both #50 and #51 when merged.

#### [#46] - (2016-06-21T17:25:08Z) - [Minor updates to avoid warnings with Elixir v1.3.0](https://github.com/whitfin/cachex/pull/46)

This PR will simply removed any warnings raised by Elixir 1.3.0. I also added v1.3.0 to the Travis build to make sure we take care of 1.3.0 going forward.

#### [#44] - (2016-06-17T21:22:58Z) - [Modify startup to require a name as first argument](https://github.com/whitfin/cachex/pull/44)

This will fix #42.

Rather than have a required argument inside the options list, we're going to explicitly require it in the function head so it's easier to document and matches the rest of the interface.

I did some minor binding to make sure that we don't break backwards compatibility. When it comes to 2.0, we can strip out the old behaviour.

#### [#43] - (2016-06-17T17:58:24Z) - [Migrate to having a single Cachex task](https://github.com/whitfin/cachex/pull/43)

This will resolve #41 by creating a single Cachex task to delegate through a context.

The first argument to the task should be the name of the task you wish to run in context. Any other arguments are passed to that task (inside the context).

Also caught the Travis and README examples.

#### [#39] - (2016-06-17T13:29:49Z) - [Move to using ETS for Cachex states](https://github.com/whitfin/cachex/pull/39)

This PR will resolve #38 once merged. 

The changes will strip out the internal GenServer worker in favour of everything executing on the calling thread, meaning that the user has better control over concurrency. All states are stored in an ETS table at this point instead. The ETS table is handled by [Eternal](https://github.com/zackehh/eternal) to make sure it doesn't die.

Both Hooks and Janitors still remain under a Supervisor, which now holds the cache name as the server name. The interface is identical apart from this.

The original intent was to remove the `execute/3` action, but it still makes sense to keep (with tweaked documentation) as it avoids hitting the local ETS table N times for N actions. 

Inspection needs further improvements because it's guaranteed a state, so it hits ETS needlessly. This will be addressed shortly.
- [x] Persistent ETS table
- [x] Remove internal GenServer
- [x] Remove the `gen_delegate` dependency
- [x] Provide internal wrappers to CRUD on state
- [x] Provide an application callback to setup ETS
- [x] Make sure that `inspect` uses the provided state
- [x] Strip out `async` and `timeout` options

#### [#35] - (2016-05-29T23:42:22Z) - [Add deps badge to README](https://github.com/whitfin/cachex/pull/35)

Hi Isaac,

we don't know each other, but I'd like to pitch you a new Elixir related badge:

[![Deps Status](https://beta.hexfaktor.org/badge/all/github/zackehh/cachex.svg)](https://beta.hexfaktor.org/github/zackehh/cachex)

It shows you an analysis for your dependencies. Behind the badge works a CI service written in Elixir which can notify you whenever important updates for your Hex packages are released.

This is still in its infancy, and I want to basically invite you to join the beta to test-drive this. I really believe that we can create a great service for the community with this. That said, don't feel any obligation to accept the PR. You can't hurt my feelings by voicing your honest opinion about this idea!

#### [#33] - (2016-05-23T18:48:32Z) - [Ensure Hooks are linked to the Cachex Supervisor](https://github.com/whitfin/cachex/pull/33)

This PR will resolve #32. Hooks will now be supervised by the Cachex supervisor rather than being linked to the calling process. This fixes an issue when you create a cache from a spawned process and all hooks immediately die due to the links.

I've also stripped out the internal `start/2` functions of both `Cachex.Worker` and `Cachex.Janitor` and made `Cachex.start/2` far more elegant (as it was actually broken previously).

In addition, there's some general cleanup of public functions which should've been private.

#### [#31] - (2016-05-18T20:30:18Z) - [Add the base implementation of code linting](https://github.com/whitfin/cachex/pull/31)

This PR will fix #30 as it embed Credo linting into CI builds, using a configuration provided in the repo. I also added a task to run Credo with some default arguments under the Cachex project.  

There are a couple of issues in the configuration because it's complaining about the use of `ttl` as a variable in `worker.ex` when there's a `ttl` function, but I think it actually hurts readability to rename either to something else. I briefly considered `expiry` but it doesn't jive.

#### [#29] - (2016-05-18T18:53:53Z) - [Provide the ability to reset cache states](https://github.com/whitfin/cachex/pull/29)

This PR will fix #26 by allowing a developer to reset various parts of a cache.

It implements the spec as described in the issue above, such that a user can reset keyspaces and hooks. Whitelists can be provided to control exactly what should be reset. Hooks are not deconstructed, rather they're just reinitialised and will live inside the same process.

#### [#28] - (2016-05-17T22:30:50Z) - [Migrate to using the :gen_delegate module](https://github.com/whitfin/cachex/pull/28)

This PR will remove the internal macros for delegation in favour of the external `GenDelegate` module. 

This change should be low risk as that external module was created based upon the macro inside Cachex. All that changes is the dependency, and then a `use` of that module rather than the internal.

Fixes #27.

#### [#24] - (2016-04-22T22:53:45Z) - [Strip out the transactional interfaces](https://github.com/whitfin/cachex/pull/24)

This PR will remove the transactional interfaces from Cachex. This is a breaking change for anyone using transactions (and I believe that to be few).

Rather than automatically binding everything inside a transaction, you have to manually initialise a transaction with `Cachex.transaction/3`. This is mainly to avoid people using transactions where there is no point, and to reduce the amount of wasted maintenance.

#### [#23] - (2016-04-21T23:18:51Z) - [Add a stream/2 function to the interface](https://github.com/whitfin/cachex/pull/23)

This PR introduces a new `stream/2` function which will return a Stream of the underlying ETS table. This Stream can then be used to iterate through all un-expired values quickly using a QLC handle.

In addition, I've included an `:only` option in case you wish to trim down what comes back to just being either keys or values. Default value being passed is `{ key, value }` - I didn't feel a need to raise the entire underlying record... but if anyone requests it in future I may be inclined to tweak.

Please note that this is a moving Stream, meaning it may or may not take new writes into account during traversal. It uses raw ETS as using a transaction would result in all processing having to be done eagerly and inside the cache worker, which is far too expensive and poses an easy-to-do issue with blocking the GenServer. The current implementation allows the iteration of the cache to happen out of proc, which is actually closer to what I imagine people would expect to happen.

This will fix #22 when merged.

**Edit**: I have tweaked `:only` to `:of` in a follow-up commit which allows custom stream formats, with access to all internal fields (even if only `:key` and `:value` will be used). Default stays the same. I also added aliases throughout to help with match specs, instead of having to provide `:"$1"` & co. which are quite fiddly to type.

#### [#21] - (2016-04-20T04:36:07Z) - [Add inspection options to view the last Janitor run](https://github.com/whitfin/cachex/pull/21)

This relates back to #3 and adds the ability to view the results of the last Janitor run.

These three values are maintained:
- the last time the Janitor check started
- the duration of the last Janitor run
- the total number of entries purged in the last run

I think this should be enough to keep an eye on Janitors so I'm ready to merge. I may add more in future, but for now I believe this is sufficient.

#### [#20] - (2016-04-20T03:15:29Z) - [Provide a way to access workers in hooks](https://github.com/whitfin/cachex/pull/20)

This will fix #1. It's just a starting point, but I think this should be sufficient going forward.

This PR adds a `:provide` option to all hooks, allowing you to ask for various things to be provided to the hook (although currently it's just `:worker`). This will then call `handle_info/2` in the hook with a `{ :provision, { :worker, worker } }` message and allow you to bind the worker to your state. 

You can then pass this worker to Cachex (i.e. `Cachex.get(worker, "key")`) for cache access within the hooks without jumping back over the proc barrier to the worker server.

#### [#19] - (2016-04-19T03:49:24Z) - [Fix up Janitors to ensure they broadcast to all hooks](https://github.com/whitfin/cachex/pull/19)

This fixes #17. Basically the Janitors were only reporting to the Stats hook (for whatever reason). This simply tweaks them to broadcast to all attached hooks via the worker.

I have also included a small `:broadcast` hook into the worker module to make it easier to jump messages straight to hooks. This adds an extra message to the worker but it should be extremely fast (bar any sync hooks).

#### [#18] - (2016-04-19T03:19:30Z) - [Add handling covering incr/3 on non-numeric keys](https://github.com/whitfin/cachex/pull/18)

Currently there's a bug in `decr/3` and `incr/3` in that if you create a non-numeric value beforehand, a call to either will crash the server.

This PR will add coverage around this issue and resolve it in all workers. I also added handling to `get_and_update/4` to better support transactions and unrecognised errors.

You can now `Cachex.abort(worker, :reason)` from inside a `get_and_update/4` call to exit early and not commit the changes, and `{ :error, :reason }` will be returned.

#### [#16] - (2016-04-17T14:53:27Z) - [Add new inspection functions for expired keys](https://github.com/whitfin/cachex/pull/16)

This PR will add `{ :expired, :count }` and `{ :expired, :keys }` to inspect expired keys in the cache which have not yet been deleted.

This is to cover some of the things mentioned in #3.

#### [#15] - (2016-04-16T05:01:09Z) - [Provide the ability to disable on-demand expiration](https://github.com/whitfin/cachex/pull/15)

This PR will add the feature to disable on-demand expirations per #11. This is useful when you don't really care about guaranteed TTL accuracy (for example if you're using TTLs to just lower your memory usage). In this case the deletes on demand can lower your read throughput, so this allows you to trade accuracy for read performance.

#### [#14] - (2016-04-16T02:50:25Z) - [Refactor worker implementations around a CRUD interface](https://github.com/whitfin/cachex/pull/14)

This should be enough to cover what's needed for #6.

I defined a CRUD behaviour on all workers, and then pulled everything out which could be. The advantage is that TTL is checked in a single place only (bar `take/3` in `local.ex`). It also cuts down on a fair amount of duplication.

I also snuck in a `:hook_result` option to all Worker functions which will override any results sent to the hook. I can't imagine this will be used often, but it was needed to fix #10.

This PR will also catch #10 and make it far easier to implement #11.

#### [#13] - (2016-04-15T18:34:23Z) - [Ensure nodes can reconnect after dropping out](https://github.com/whitfin/cachex/pull/13)

This is based around #12 and corrects several issues in remote caches, namely;
- fixes an issue where caches were not linked to supervisors correctly
- fixes an issue where nodes are not brought into the cluster
- fixes an issue where tables are not replicated across the cluster
- adds a new `add_node/2` function to add a node to a cache at runtime
- adds a new `start/1` function to start a cache without proc linking
- adds new integration tests based around adding remote nodes

#### [#9] - (2016-04-11T04:07:13Z) - [Add delegates outside of the Worker using a :via flag](https://github.com/whitfin/cachex/pull/9)

Based around #8. 

Right now the Worker has the code for various functions which delegate in order to notify hooks correctly. With this PR we can delegate in the main interface and maintain the hook notifications using `:via`. 

The example from the issue is if you call something like `Cachex.incr(:my_cache, "key", via: :decr)`, it notifies using `{ :decr, "key" }`. After this PR is merged, this will function correctly. The same implementation exists for both `expire_at/4` and `persist/3`.

#### [#7] - (2016-04-11T02:21:20Z) - [Begin refactoring of Stats to store all results](https://github.com/whitfin/cachex/pull/7)

This is the initial implementation of #5 which will ensure better consistency and accuracy inside the statistics gathering - it also has the knock-on effect of improving the accuracy of the hook system notifications in general.

This PR introduces the new `for` option with stat: `Cachex.stats(:my_cache, for: :get)`. This allows the retrieval of extremely raw values on an action level. The default is to still provide what we do now.

Naturally there's a bigger memory overhead to this because we're storing more data, and the retrieval will take a little bit longer if you're grabbing the current implementation (because it's calculated on-demand). I think these are perfectly fine and expected.

