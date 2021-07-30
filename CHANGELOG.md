# Changelog

## v0.3.0

Potentially breaking changes

* bump `ueberauth` 0.7.0 - If you require >= 0.6 then you may need to
  adjust things before updating
  * support CSRF attack protection bia the `with_state_param` from ueberauth (thanks @Jonathan-Arias!)

## v0.2.1

No breaking changes

* Fix some compiler warnings (Thanks @zillou!)
* Bump development/release deps

## v0.2.0

Addresses issues between Okta API and OAuth2 implementation (Thanks @Deconstrained)

* The client credentials are included in both the body (params) and in the basic authorization header; Okta will issue a 403 in response to this.
* Okta's response containing the access token is JSON-encoded, and since oauth2 does not by default support the JSON mimetype, the JSON string containing the token is treated as the token itself, which results in a 401 when making the final request to authenticate the user back to Okta.

## v0.1.0

Initial Release
