# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
