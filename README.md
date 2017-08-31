# idQ Auth

[![Master](https://travis-ci.org/maxneuvians/idq_auth.svg?branch=master)](https://travis-ci.org/maxneuvians/idq_auth)

A collection of modules that allows an application to complete the various OAuth 2.0 based authentication authentication flows offered by idQ® TaaS Authentication from inBay Technologies Inc. (https://inbaytech.com/)

Available authentication methods include:

* `IdqAuth.Explicit` and `IdqAuth.Plug` - Explicit Authentication (requires `Plug` and `Plug.Session`)
* `IdqAuth.Implicit` - Implicit Authentication
* `IdqAuth.Delegated` - Implicit Delegated Authentication (Push notifications)

Please review the documentation for each module to understand how to best use them in your application.

## Demo

You can view a demo in a phoenix application here:
[https://idq-auth-demo.herokuapp.com/](https://idq-auth-demo.herokuapp.com/)

The source code can be found here:
[https://github.com/maxneuvians/idq_auth_demo](https://github.com/maxneuvians/idq_auth_demo)


## Installation
Add `idq_auth` to your list of dependencies in `mix.exs`:

```
def deps do
  [{:idq_auth, git: "https://github.com/maxneuvians/idq_auth"}]
end
```

## Configuration

Please include the following configuration in your config files:

```
config :idq_auth,
  endpoint: "https://taas.idquanta.com/idqoauth/api/v1/",
  callback_url: "CALLBACK_URL",
  client_id: "KEY",
  client_secret: "SECRET"
```

`callback_url`, `client_id`, and `client_secret` are all available through your idQ®
application management backend.


## Docs

`mix docs`

## Test and style

`mix test`

`mix dialyxir`

`mix credo`

### Version
0.1.1

License
----
MIT

idQ® is a registered trademark owned by inBay Technologies Inc.
