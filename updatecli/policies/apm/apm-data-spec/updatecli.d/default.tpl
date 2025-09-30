---
# Copyright Elasticsearch B.V. and contributors
# SPDX-License-Identifier: Apache-2.0
#
# Helpers
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
  sha:
    kind: file
    spec:
      file: 'https://github.com/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm-data/commit/{{ .scm.branch }}.patch'
      matchpattern: "^From\\s([0-9a-f]{40})\\s"
    transformers:
      - findsubmatch:
          pattern: "[0-9a-f]{40}"
  pull_request:
    kind: shell
    dependson:
      - sha
    spec:
      command: gh api /repos/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm-data/commits/{{ source "sha" }}/pulls --jq '.[].html_url'
      environments:
        - name: GITHUB_TOKEN
        - name: PATH
  agent-specs-tarball:
    kind: shell
    scmid: apm-data
    dependson:
      - sha
    spec:
      command: tar cvzf {{ requiredEnv "GITHUB_WORKSPACE" }}/json-schema.tgz .
      environments:
        - name: PATH
      workdir: "input/elasticapm/docs/spec/v2"

targets:
  agent-json-schema:
    name: APM agent json server schema {{ source "sha" }}
    disablesourceinput: true
    kind: shell
    dependson:
      - source#agent-specs-tarball
    spec:
      # git diff helps to print what it changed, If it is empty, then updatecli report a success with no changes applied.
      # See https://www.updatecli.io/docs/plugins/resource/shell/#_shell_target
      command: 'tar -xzf {{ requiredEnv "GITHUB_WORKSPACE" }}/json-schema.tgz && git --no-pager diff'
      workdir: "{{ .apm_schema_specs_path }}"
#{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}

{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: "github"
    spec:
      # Priority set to the environment variable
      user: '{{ default $GitHubUsername .scm.username}}'
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: '{{ default $GitHubRepositoryList._1 .scm.repository}}'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'
#{{ if .scm.commitusingapi }}
      commitusingapi: {{ .scm.commitusingapi }}
# {{ end }}

  apm-data:
    kind: github
    spec:
      user: '{{ default $GitHubUsername .scm.username }}'
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: 'apm-data'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'

actions:
  default:
    title: '[Automation] Update JSON server schema specs'
    kind: "github/pullrequest"
    scmid: "default"
    sourceid: sha
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
      description: |-
        ### What
        APM agent json server schema automatic sync

        ### Why
        *Changeset*
        * {{ source "pull_request" }}
        * https://github.com/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm-data/commit/{{ source "sha" }}

{{ end }}
