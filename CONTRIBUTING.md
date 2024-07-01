# Contributing to the oblt-updatecli-policies

Policies can be added by creating a new folder under `updatecli/policies` directory.
The subfolder path will be used as the policy name.

For example if we want to create a policy named `autodiscovery/golang`, we need to create a folder named `updatecli/policies/autodiscovery/golang`.
This policy will be named `ghcr.io/updatecli/policies/autodiscovery/golang` and will be published on `ghcr.io` docker registry.

The policy folder must contain:

* `Policy.yaml` file which contains the policy metadata.
* `updatecli.d` directory which contains the policy configuration files.
* `README.md` file which contains the policy documentation.
* `CHANGELOG.md` file which contains the policy changelog.
* `values.yaml` file which contains the default values for the policy.

**Policy.yaml**

The `Policy.yaml` file must contain at least the following fields:

```yaml
url: <link to this git repository>
documentation: <link to the policy documentation>
source: <link to this policy code>
version: <policy version>
description: <policy description with maximum 512 characters>
```

**Version**

The version must be a valid semantic version. For example `1.0.0` or `1.0.0-beta.1`
The version will be used as the "tag" for the policy such as `ghcr.io/updatecli/policies/autodiscovery/golang:1.0.0`

Any change to the policy code must be reflected by a new version. Policies are automatically published on `ghcr.io` if the version is updated.
