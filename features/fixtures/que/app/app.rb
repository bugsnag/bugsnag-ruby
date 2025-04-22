require_relative "setup-que"

Que.migrate!(version: Que::Migrations::CURRENT_VERSION)
