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
    kind: shell
    spec:
      command: gh api /repos/{{ default $GitHubRepositoryList._0 .scm.owner }}/{{ .pgo_source_repo}}/commits/main --jq '.sha'
      environments:
        - name: GITHUB_TOKEN
        - name: PATH
  pull_request:
    kind: shell
    dependson:
      - sha
    spec:
      command: gh api /repos/{{ default $GitHubRepositoryList._0 .scm.owner }}/{{ .pgo_source_repo}}/commits/{{ source "sha" }}/pulls --jq '.[].html_url'
      environments:
        - name: GITHUB_TOKEN
        - name: PATH
  pgo-file:
    kind: shell
    scmid: apm-managed-service
    dependson:
      - sha
    spec:
      command: tar cvzf {{ requiredEnv "GITHUB_WORKSPACE" }}/pgo.tgz {{ .pgo_file }}
      environments:
        - name: PATH
      workdir: "{{ .pgo_source_path }}"

targets:
  pgo:
    name: PGO file {{ source "sha" }}
    disablesourceinput: true
    kind: shell
    dependson:
      - source#pgo-file
    spec:
      # git diff helps to print what it changed, If it is empty, then updatecli report a success with no changes applied.
      # See https://www.updatecli.io/docs/plugins/resource/shell/#_shell_target
      command: 'tar -xzf {{ requiredEnv "GITHUB_WORKSPACE" }}/pgo.tgz && git add -N {{ .pgo_file }} && git --no-pager diff'
      workdir: "{{ .pgo_target_path }}"
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

  apm-managed-service:
    kind: github
    spec:
      user: '{{ default $GitHubUsername .scm.username }}'
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: '{{ .pgo_source_repo }}'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: 'main'

actions:
  default:
    title: '[Automation] Update default.pgo'
    kind: "github/pullrequest"
    scmid: default
    sourceid: sha
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
      description: |-
        ### What
        Update default.pgo automatic sync

        ### Why
        *Changeset*
        * {{ source "pull_request" }}
        * https://github.com/{{ default $GitHubRepositoryList._0 .scm.owner }}/{{ .pgo_source_repo }}/commit/{{ source "sha" }}

{{ end }}
