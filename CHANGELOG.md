# Changelog

## v0.2.0

Addresses issues between Okta API and OAuth2 implementation (Thanks @Deconstrained)

* The client credentials are included in both the body (params) and in the basic authorization header; Okta will issue a 403 in response to this.
* Okta's response containing the access token is JSON-encoded, and since oauth2 does not by default support the JSON mimetype, the JSON string containing the token is treated as the token itself, which results in a 401 when making the final request to authenticate the user back to Okta.

## v0.1.0

Initial Release
