# oblt-updatecli-policies

This repository contains a list of common Updatecli published on `ghcr.io/elastic/oblt-updatecli-policies/**`.

**NOTE**: Used some bits and pieces from https://github.com/updatecli/policies

## HOWTO

**Login**

Even though all Updatecli policies published on `ghcr.io` are meant to be public, you'll probably need to authenticate to reduce rate limiting by running:

    docker login ghcr.io

**Publish**

Each policy defined in this repository is automatically published on ghcr.io via a GitHub Action workflow

**Show**

We can see the content of the policy by running:

    updatecli manifest show ghcr.io/elastic/oblt-updatecli-policies/<a policy name>:latest

**Use**

There are two ways to execute an Updatecli policy, either running one policy or several policies at once.

One policy can be executed by running:

    updatecli apply --config ghcr.io/elastic/oblt-updatecli-policies/<a policy name>:latest

**IMPORTANT**: Any values files specified at runtime will override the default values setting from the policy bundle.

Assuming we have a file named `update-compose.yaml`, multiple policies can be composed and executed by running:

    updatecli compose apply

.update-compose.yaml
```yaml
policies:
    - policy: "ghcr.io/elastic/oblt-updatecli-policies/golang:latest"
```

More information about Updatecli compose feature can be found [here](https://www.updatecli.io/docs/core/compose).
