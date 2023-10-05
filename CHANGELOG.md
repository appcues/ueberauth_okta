# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.1.3 - 2023-10-05

* Fix an issue where config wasn't correctly being merged in (thanks to @Swingcloud and @jamesvl :heart:)

## v1.1.2 [Revoked]

## v1.1.1 - 2023-01-25

* Fix an issue looking up provider options in the Application config which
  may be stored or referenced as a string (thanks @giddie :heart:)

## v1.1.0 - 2022-12-29

This essentially negates v1.0.0 and adds back the `Ueberauth.Strategy.Okta.OAuth`
configuration scope to support better runtime option management. Both this scope
and using the `:providers` key in Ueberauth config are supported.

* Fix support with `runtime.exs` files and runtime evaluations of options.
* Support `:providers` in `Ueberauth.Strategy.Okta.OAuth` to allow for
  multi-tenant support

## v1.0.0 - 2022-11-28

This is a breaking change that removes the ability to set OAuth settings in the
application environment via `Ueberauth.Strategy.Okta.OAuth` and instead relies
on the settings coming in from the Ueberauth `:providers` setup.

* Support `:authorization_server_id` for custom Okta Authorization Servers. This will
  add the id to the default urls used in the process (Thanks @giddie!)

## v0.3.1 - 2022-08-12

* Support multi-tenant applications by allowing dynamic Okta configs in the conn
  (Thanks @ryanzidago :heart:)

## v0.3.0 - 2021-07-30

Potentially breaking changes

* bump `ueberauth` 0.7.0 - If you require >= 0.6 then you may need to
  adjust things before updating
  * support CSRF attack protection bia the `with_state_param` from ueberauth (thanks @Jonathan-Arias!)

## v0.2.1 - 2021-06-01

No breaking changes

* Fix some compiler warnings (Thanks @zillou!)
* Bump development/release deps

## v0.2.0 - 2020-10-19

Addresses issues between Okta API and OAuth2 implementation (Thanks @Deconstrained)

* The client credentials are included in both the body (params) and in the basic authorization header; Okta will issue a 403 in response to this.
* Okta's response containing the access token is JSON-encoded, and since oauth2 does not by default support the JSON mimetype, the JSON string containing the token is treated as the token itself, which results in a 401 when making the final request to authenticate the user back to Okta.

## v0.1.0 - 2018-04-25

* Initial Release
