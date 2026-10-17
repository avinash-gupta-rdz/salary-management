# Single HR manager login (HTTP basic auth). Credentials come from the
# environment; development and test fall back to local defaults. In production a
# missing credential leaves both values nil, so every request is refused.
local_default = ->(value) { Rails.env.production? ? nil : value }

Rails.application.config.x.hr_auth = ActiveSupport::OrderedOptions.new.merge(
  username: ENV.fetch("HR_USERNAME", local_default.call("hr")),
  password: ENV.fetch("HR_PASSWORD", local_default.call("password"))
)
