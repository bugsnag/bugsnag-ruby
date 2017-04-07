
## How to contribute

We are glad you're here! First-time and returning contributors are welcome to
add bug fixes and new integrations. If you are unsure about the direction of an
enhancement or if it would be generally useful, feel free to open an issue or a
work-in-progress pull request and ask for input.

Thank you!

### Getting started

-   [Fork](https://help.github.com/articles/fork-a-repo) the [library on github](https://github.com/bugsnag/bugsnag-ruby)
-   Commit and push until you are happy with your contribution

### Polish

-   Run the tests with and make sure they all pass

    ```
    rake spec
    ```
-   For adding a new integration (like support for a web framework or worker
    queue), include an example in the `example/` directory showing off what
    you've built. Include a `README` with the example app so others know how to
    run it.


### Ship it!

-   [Make a pull request](https://help.github.com/articles/using-pull-requests)


## How to release

If you're a member of the core team, follow these instructions for releasing bugsnag-ruby.

### First time setup

* Create a Rubygems account
* Get James/Simon to add you as contributor on bugsnag-ruby in Rubygems

### Every time

* Update `VERSION`
* Update `CHANGELOG.md`
* Update `README.md` if necessary
* Commit/push your changes

    ```
    git commit -am v5.X.X
    git push origin master
    ```

* Release to rubygems

    ```
    bundle exec rake release
    ```

* Update the version running in the bugsnag-website project

### Update docs.bugsnag.com

Update the setup guides for Ruby (and its frameworks) with any new content.
