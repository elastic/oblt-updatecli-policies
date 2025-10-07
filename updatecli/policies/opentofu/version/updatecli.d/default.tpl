---
# Copyright Elasticsearch B.V. and contributors
# SPDX-License-Identifier: Apache-2.0
#
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
  version:
    name: Get latest opentofu version from opentofu/opentofu
    kind: githubrelease
    spec:
      owner: opentofu
      repository: opentofu
      token: "{{ default $GitHubPAT .scm.token }}"
      username: "{{ default $GitHubUsername .scm.username }}"
      versionFilter:
        kind: latest
    transformers:
      - trimprefix: "v"

targets:
  version-file:
    name: 'deps(opentofu): Bump opentofu version to {{ source "version" }}'
    kind: file
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    sourceid: version
    spec:
      file: '{{ .path }}'
# {{ if hasSuffix ".tool-versions" .path }}
      matchpattern: '^opentofu\s+v\d+\.\d+\.\d+'
      content: 'opentofu {{ source `version` }}'
# {{ else }}
      # |+ adds newline to the end of the file
      content: |+
        {{ source `version` }}
# {{ end }}

# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: "github"
    spec:
      # Priority set to the environment variable
      user: '{{ default $GitHubUser .scm.user}}'
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: '{{ default $GitHubRepositoryList._1 .scm.repository}}'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'
#{{ if .scm.commitusingapi }}
      commitusingapi: {{ .scm.commitusingapi }}
# {{ end }}

actions:
  default:
    title: 'deps: Bump opentofu version to {{ source "version" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
# {{ range .pull_request.labels }}
        - {{ . }}
# {{ end }}
    scmid: "default"
{{ end }}
