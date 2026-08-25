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
  obs-cli-version:
    name: Get latest oblt-cli version from elastic/{{ .source_repository }}
    kind: githubrelease
    spec:
      owner: elastic
      repository: {{ .source_repository }}
      token: "{{ default $GitHubPAT .scm.token }}"
      username: "{{ default $GitHubUsername .scm.username }}"
      versionFilter:
        kind: latest

targets:
  oblt-cli-version-file:
    name: 'deps(oblt-cli): Bump oblt-cli version to {{ source "obs-cli-version" }}'
    kind: file
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    sourceid: obs-cli-version
    spec:
      file: '{{ .path }}'
# {{ if hasSuffix ".tool-versions" .path }}
      matchpattern: '^oblt-cli\s+\d+\.\d+\.\d+'
      content: 'oblt-cli {{ source `obs-cli-version` }}'
# {{ else }}
      # |+ adds newline to the end of the file
      content: |+
        {{ source `obs-cli-version` }}
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
#{{ if .scm.force }}
      force: {{ .scm.force }}
# {{ end }}

actions:
  default:
    title: 'deps: Bump oblt-cli version to {{ source "obs-cli-version" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
# {{ range .pull_request.labels }}
        - {{ . | quote }}
# {{ end }}
    scmid: "default"
{{ end }}
