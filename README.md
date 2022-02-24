# Netlify DDNS

This is a Bash script to update a [Netlify][netlify] subdomain A record with the current external IP.

---
## Usage
`netlify-ddns.sh <ACCESS_TOKEN> <DOMAIN> <SUBDOMAIN> <TTL> [<CACHED_IP_FILE>]`

## Example
The example below would update the local.example.com A record to the current external IP with a TTL of 5 minutes.
The last parameter for the script is optional and is used to cache the Netlify IP to reduce API calls.
`netlify-ddns.sh aCcEsStOKeN example.com local 300 /home/johnsmith/cached-ip-file.txt`

---
### Prerequisites
- Bash
- [jq](https://github.com/stedolan/jq)
---
### Related
- [lukehsiao/netlify-ddns-rs] for a similar client written in [Rust][rust].
- [oscartbeaumont/netlify-dynamic-dns] for a similar client written in [Go][go].
- [lytedev/netlify-ddns] for another similar shell script version.

[netlify]: https://www.netlify.com/docs/dns/
[rust]: https://rust-lang.org/
[go]: https://golang.org/
[lytedev/netlify-ddns]: https://github.com/lytedev/netlify-ddns
[lukehsiao/netlify-ddns-rs]: https://github.com/lukehsiao/netlify-ddns-rs
[oscartbeaumont/netlify-dynamic-dns]: https://github.com/oscartbeaumont/netlify-dynamic-dns
