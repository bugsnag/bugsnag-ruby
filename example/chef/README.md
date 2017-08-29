# Example [Bugsnag](https://bugsnag.com/) + [Chef](https://www.chef.io/) integration

These are some examples of integrating exposed [Chef events](https://docs.chef.io/handlers.html#event-types)

Obtain an API key: https://docs.bugsnag.com/api/error-reporting/#json-payload

## Getting started

```bash
rake setup
```

## Examples:

* Report failed chef runs:
  ```
  rake chef:failed_run
  ```

  Takes a minute because of a large Chef Docker image.
