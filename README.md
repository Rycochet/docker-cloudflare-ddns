# Docker CloudFlare DDNS

[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Rycochet/docker-cloudflare-ddns/publish.yml)](https://github.com/Rycochet/docker-cloudflare-ddns/actions/workflows/publish.yml) ![GitHub contributors](https://img.shields.io/github/contributors/Rycochet/docker-cloudflare-ddns) [![Docker Pulls](https://img.shields.io/docker/pulls/rycochet/docker-cloudflare-ddns) ![Docker Image Size](https://img.shields.io/docker/image-size/rycochet/docker-cloudflare-ddns)](https://hub.docker.com/r/rycochet/docker-cloudflare-ddns/)

This small Alpine Linux based Docker image will allow you to use the free [CloudFlare DNS Service](https://www.cloudflare.com/dns/) as a Dynamic DNS Provider ([DDNS](https://en.wikipedia.org/wiki/Dynamic_DNS)).

This is a multi-arch image and will run on amd64, aarch64, and armhf devices, including the Raspberry Pi.

## Usage

### Docker

Quick Setup:

```shell
docker run \
  -e API_KEY=<apikey> \
  -e ZONE=<mydomain> \
  -e SUBDOMAIN=@,www \
  ghcr.io/rycochet/docker-cloudflare-ddns:latest
```

### Docker Compose

If you prefer to use [Docker Compose](https://docs.docker.com/compose/):

```yml
services:
  cloudflare-ddns:
    image: ghcr.io/rycochet/docker-cloudflare-ddns:latest
    restart: always
    environment:
      - API_KEY=<apikey>
      - ZONE=<mydomain>
      - SUBDOMAIN=@,www
```

## Environment Variables

| Name | Definition | Default |
| --- | --- | --- |
| `API_KEY` **or** <br> `API_KEY_FILE` [^1] | **Required** <br> Your CloudFlare scoped API token. See [Creating a Cloudflare API token](#creating-a-cloudflare-api-token) below. | |
| `ZONE` **or** <br> `ZONE_FILE` [^1] | **Required** <br> The DNS Zone (domain name) that DDNS updates should be applied to. | |
| `SUBDOMAIN` **or** <br> `SUBDOMAIN_FILE` [^1] | One or more comma separated subdomains of the `ZONE` to write DNS changes to. <br> **`@`** will update the root zone. <br> **`*`** will update the wildcard subdomain. | `@` |
| `CRON` | Set your own custom [CRON value](https://en.wikipedia.org/wiki/Cron#Overview) for how often this runs. | `*/5 * * * *` (every 5 minutes) |
| `CUSTOM_LOOKUP_CMD` | A shell command to run that must print the IP on the standard output. | |
| `DELETE_ON_STOP` | Delete the DNS record when the container is stopped. | `false` |
| `DNS_SERVER` | The IP address of the DNS server for automatic DNS lookups should [ipify](https://www.ipify.org/) fail. | `1.1.1.1` |
| `EMAIL` | **Deprecated** <br> Your CloudFlare email address when using an Account-level token. This variable MUST NOT be set when using a scoped API token. | |
| `INTERFACE` | Set to `tun0` to have the IP pulled from a network interface named `tun0`. If this is not supplied the public IP will be used instead. <br> Requires `--network host` run argument. | |
| `PROXIED` | Make traffic go through the CloudFlare CDN. | `false` |
| `RRTYPE` | [DNS record type](https://developers.cloudflare.com/dns/manage-dns-records/reference/dns-record-types/): <br> `A` for IPv4. <br> `AAAA` for IPv6 (you will also need to run docker with IPv6 support, or run the container with host networking enabled). | `A` |
| `WEBHOOK_URL` | Set to a webhook URL to send a message when the IP address changes. | |

[^1]: Path to load your CloudFlare DNS Zone from (e.g. a Docker secret).<br>  If both normal and a `_FILE` parameter are specified the file takes precedence.

## Explanation on how this container works

The image is based on an alpine OS with S6 supervisor and the s6-overlay architecture.

It will find out the DNS address to use, then for each requested subdomain it will check if it needs to update, and only change if needed.

This runs (by default) every 5 minutes using cron. The default [TTL](https://developers.cloudflare.com/dns/manage-dns-records/reference/ttl/) (`Auto`) on Cloudflare is 5 minutes, so records are updated about as quickly as possible.

### Creating a Cloudflare API token

To create a CloudFlare API token for your DNS zone go to <https://dash.cloudflare.com/profile/api-tokens> and follow these steps:

1. Click `Create Token`.
1. Use the `Edit zone DNS` Template.
1. Provide the token a name, for example: `cloudflare-ddns`.
1. Leave the Permissions unchanged (`Zone` - `DNS` - `Edit`).
1. Set the Zone Resources to `Include` - `All zones`
1. Click `Continue to summary`, then `Create Token`.
1. Make a record of the token somewhere safe (such as a password manager) as you cannot view it again, and then use the token for the `API_KEY` variable.

### Multiple Domains

If you need multiple records pointing to your public IP address you can create CNAME records in CloudFlare, or run multiple instances of the image with different options.

### Supported Platforms

- `linux/386`
- `linux/amd64`
- `linux/arm/v6`
- `linux/arm/v7`
- `linux/arm64`
- `linux/ppc64le`
- `linux/riscv64`
- `linux/s390x`

## License

Copyright (C) 2017-2025 [oznu](https://github.com/oznu/docker-cloudflare-ddns) (original developer until 2020), [two70](https://github.com/two70/cloudflare-ddns), [TThanhXuan](https://github.com/TThanhXuan/docker-cloudflare-ddns-telegram), [VSF1](https://github.com/VSF1/docker-cloudflare-ddns), [sachasmart](https://github.com/sachasmart/docker-cloudflare-ddns), [enstyrka](https://github.com/enstyrka/docker-cloudflare-ddns), [aaronbolton](https://github.com/aaronbolton/docker-cloudflare-ddns), [ian-otto](https://github.com/ian-otto/docker-cloudflare-ddns), [giorginogreg](https://github.com/giorginogreg/docker-cloudflare-ddns), [Rycochet](https://github.com/Rycochet/docker-cloudflare-ddns)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.
