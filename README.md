# Docker CloudFlare DDNS

## Most recently forked from giorginogreg/docker-cloudflare-ddns

- Allow comma separated SUBDOMAINS

### Forked from [giorginogreg/docker-cloudflare-ddns](https://github.com/giorginogreg/docker-cloudflare-ddns) -

- Merged repository from [two70](https://github.com/two70/cloudflare-ddns/tree/master)
- Merged features from [TThanhXuan](https://github.com/TThanhXuan/docker-cloudflare-ddns-telegram)
- Merged Features from [VSF1](https://github.com/VSF1/docker-cloudflare-ddns)
- Merged Features from [sachasmart](https://github.com/sachasmart/docker-cloudflare-ddns)
- Merged Features from [enstyrka](https://github.com/enstyrka/docker-cloudflare-ddns)
- Merged Features from [aaronbolton](https://github.com/aaronbolton/docker-cloudflare-ddns)
- Merged Features from [ian-otto](https://github.com/ian-otto/docker-cloudflare-ddns)

### Originally by [oznu/docker-cloudflare-ddns](https://github.com/oznu/docker-cloudflare-ddns)

> [!NOTE]
> Since the main repo is no longer maintained, People forked it to add some functinality they would like to see, such as dates in logging, Discord webhooks, multiple subdomains.

[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/Rycochet/docker-cloudflare-ddns/publish.yml)](https://github.com/Rycochet/docker-cloudflare-ddns/actions/workflows/publish.yml)

This small Alpine Linux based Docker image will allow you to use the free [CloudFlare DNS Service](https://www.cloudflare.com/dns/) as a Dynamic DNS Provider ([DDNS](https://en.wikipedia.org/wiki/Dynamic_DNS)).

This is a multi-arch image and will run on amd64, aarch64, and armhf devices, including the Raspberry Pi.

## Usage

Quick Setup:

```shell
docker run \
  -e API_KEY=xxxxxxx \
  -e ZONE=example.com \
  -e SUBDOMAIN=@,www \
  ghcr.io/rycochet/docker-cloudflare-ddns
```

## **Required** parameters

| Parameter | Definition |
| --- | --- |
| `API_KEY` **or** <br> `API_KEY_FILE` [^1] | **Required** <br> Your CloudFlare scoped API token. See the [Creating a Cloudflare API token](#creating-a-cloudflare-api-token) below. |
| `ZONE` **or** <br> `ZONE_FILE` [^1] | **Required** <br> The DNS zone that DDNS updates should be applied to. |
| `SUBDOMAIN` **or** <br> `SUBDOMAIN_FILE` [^1] | One or more comma separated subdomains of the `ZONE` to write DNS changes to. <br> **`@`** will update the root zone. <br> **`*`** will update the wildcard subdomain. <br> *Default* `@` |
| `CRON` | Set your own custom CRON value before the exec portion. <br> *Defaults to every 5 minutes* `*/5 * * * *` |
| `CUSTOM_LOOKUP_CMD` | Set to any shell command to run them and have the IP pulled from the standard output. Leave unset to use default IP address detection methods.|
| `DELETE_ON_STOP` | Set to `true` to have the dns record deleted when the container is stopped. <br> *Default* `false` |
| `DNS_SERVER` | Set to the IP address of the DNS server you would like to use. <br> *Default* `1.1.1.1` |
| `EMAIL` | **Deprecated** <br> Your CloudFlare email address when using an Account-level token. This variable MUST NOT be set when using a scoped API token. |
| `INTERFACE` | Set to `tun0` to have the IP pulled from a network interface named `tun0`. If this is not supplied the public IP will be used instead. <br> Requires `--network host` run argument. |
| `PROXIED` | Set to `true` to make traffic go through the CloudFlare CDN. <br> *Default*  `false` |
| `RRTYPE` | Set to `AAAA` to use set IPv6 records instead of IPv4 records. <br> *Default* `A` for IPv4 records.* |
| `WEBHOOK_URL` | Set to a webhook URL to send a message when the IP address changes.

[^1]: Path to load your CloudFlare DNS Zone from (e.g. a Docker secret).<br>  If both normal and a `_FILE` parameter are specified the file takes precedence.

## Explanation on how this container works

It is based on an alpine OS with S6 supervisor and the s6-overlay architecture

### Creating a Cloudflare API token

To create a CloudFlare API token for your DNS zone go to <https://dash.cloudflare.com/profile/api-tokens> and follow these steps:

1. Click Create Token
2. Provide the token a name, for example, `cloudflare-ddns`
3. Grant the token the following permissions:
    - Zone - Zone Settings - Read
    - Zone - Zone - Read
    - Zone - DNS - Edit
4. Set the zone resources to:
    - Include - All zones
5. Complete the wizard and copy the generated token into the `API_KEY` variable for the container

### Multiple Domains

If you need multiple records pointing to your public IP address you can create CNAME records in CloudFlare.

### IPv6

If you're wanting to set IPv6 records set the environment variable `RRTYPE=AAAA`. You will also need to run docker with IPv6 support, or run the container with host networking enabled.

### Docker Compose

If you prefer to use [Docker Compose](https://docs.docker.com/compose/):

```yml
services:
  cloudflare-ddns:
    image: ghcr.io/two70/cloudflare-ddns
    restart: always
    environment:
      - API_KEY=<apikey>
      - ZONE=<mydomain>
      - SUBDOMAIN=@subdomain,subdomain2
      - PROXIED=true
      - WEBHOOK_URL=https://discord.com/api/webhooks/xxxxxx
      - TZ=America/Denver
```

## License

Copyright (C) 2017-2020 oznu

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.
