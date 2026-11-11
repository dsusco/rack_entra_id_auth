# RackEntraIdAuth

Rails-aware Rack middleware for Microsoft Entra ID (SAML) authentication, built on [ruby-saml](https://github.com/SAML-Toolkits/ruby-saml).

The middleware handles single sign-on and single logout with Entra ID. It stores the user's SAML attributes in the session and redirects any `401 Unauthorized` response from your app to the Entra ID login. In development it can run a mock login server instead, so you don't need a real IdP.

## Requirements

- Ruby 3.2+
- Rails 7.2+
- Rack 3.0+

## Installation

Add the gem to your Gemfile:

```ruby
gem 'rack_entra_id_auth'
```

Or install it straight from GitHub:

```ruby
gem 'rack_entra_id_auth', github: 'dsusco/rack_entra_id_auth'
```

Then run `bundle install`. In a Rails app the middleware is added automatically by the gem's Railtie.

## Setup

Generate the initializer, then fill in your Entra ID (IdP) and app (SP) settings:

```bash
bin/rails generate rack_entra_id_auth:initializer
```

This creates `config/initializers/rack_entra_id_auth.rb`, which documents every available setting. A minimal configuration looks like this:

```ruby
RackEntraIdAuth.configure do |config|
  config.idp_sso_service_url = 'https://login.microsoftonline.com/<tenant>/saml2'
  config.idp_slo_service_url = 'https://login.microsoftonline.com/<tenant>/saml2'
  config.idp_cert            = '<Entra ID X.509 certificate>'

  config.sp_entity_id                   = 'https://your.app/'
  config.assertion_consumer_service_url = 'https://your.app/saml/login'
  config.single_logout_service_url      = 'https://your.app/saml/logout'
end
```

Instead of setting the IdP values by hand, you can load them from your Entra ID app's federation metadata URL:

```ruby
config.metadata_url = 'https://login.microsoftonline.com/<tenant>/federationmetadata/2007-06/federationmetadata.xml?appid=<app id>'
```

The middleware intercepts requests to the assertion consumer service and single logout URLs, so make sure they don't clash with routes in your app.

Optionally, generate `login` and `logout` routes so you can use `login_path` and `logout_path` helpers in your views:

```bash
bin/rails generate rack_entra_id_auth:routes
```

### Mock server

The mock server is **on by default**. It shows a simple login page where you pick one of the users defined in `config.mock_attributes`. Turn it off wherever you use Entra ID.

This setting must go in `config/application.rb` or an environment file, not the initializer, because the middleware is chosen before initializers run:

```ruby
# config/environments/production.rb
config.rack_entra_id_auth.mock_server = false
```

## Usage

To require a login, return a `401`. The middleware turns it into a redirect to Entra ID (or the mock login page), and sends the user back to the original URL afterwards.

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate!

  private

    def authenticate!
      head :unauthorized if current_user.blank?
    end

    def current_user
      session[:entra_id]
    end
end
```

After login, `session[:entra_id]` holds the user's SAML attributes, for example `displayname`, `emailaddress`, `name` and `groups`. You can change the session key with `config.session_key`, and change how attributes are stored with `config.session_value_proc`.

Linking to `/login` or `/logout` starts a login or logout. Add a `relay_state` query parameter to choose where the user lands afterwards:

```erb
<%= link_to 'Log out', logout_path(relay_state: root_url) %>
```

To leave paths alone entirely (health checks, public assets), list them as strings or regular expressions:

```ruby
config.exclude_paths = ['/up', %r{\A/assets/}]
```

### Single logout

Single logout is disabled by default, so `/logout` only clears the local session. To also sign the user out of Entra ID, switch to a session store that can be cleared server-side, such as [entra_id_active_record_session_store](https://github.com/dsusco/entra_id_active_record_session_store), then set:

```ruby
config.skip_single_logout = false
```

## Development

```bash
bundle install
bundle exec rake test
bundle exec rubocop
```

## License

Available as open source under the terms of the [MIT License](MIT-LICENSE).
