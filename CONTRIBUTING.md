
## How to contribute

-   [Fork](https://help.github.com/articles/fork-a-repo) the [notifier on github](https://github.com/bugsnag/bugsnag-ruby)
-   Commit and push until you are happy with your contribution
-   Run the tests with and make sure they all pass

    ```
    rake spec
    ```

-   [Make a pull request](https://help.github.com/articles/using-pull-requests)
-   Thanks!


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
    git commit -am v2.X.X
    git push origin master
    ```

* Release to rubygems

    ```
    bundle exec rake release
    ```

* Update the version running in the bugsnag-website project
