---
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
      command: gh api /repos/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm-managed-service/commits/main --jq '.sha'
      environments:
        - name: GITHUB_TOKEN
        - name: PATH
  pull_request:
    kind: shell
    dependson:
      - sha
    spec:
      command: gh api /repos/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm-managed-service/commits/{{ source "sha" }}/pulls --jq '.[].html_url'
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

#{{ if (.pgo_diff) }}
  pgo-copy:
    kind: shell
    scmid: default
    dependson:
      - pgo-file
    spec:
      command: 'tar -xzf {{ requiredEnv "GITHUB_WORKSPACE" }}/pgo.tgz'
      environments:
        - name: PATH
  pgo-compare:
    kind: shell
    scmid: default
    dependson:
      - pgo-copy
    spec:
      command: 'go tool pprof -top -base={{ .pgo_target_path }}/{{ .pgo_file }} {{ .pgo_file }} | head -n 30'
      environments:
        - name: PATH
# {{ end }}

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
      command: 'tar -xzf {{ requiredEnv "GITHUB_WORKSPACE" }}/pgo.tgz && git --no-pager diff'
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
      repository: 'apm-managed-service'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'

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
        * https://github.com/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm-managed-service/commit/{{ source "sha" }}

#{{ if (.pgo_diff) }}
        ### Diff

        ```
          {{ source "pgo-compare" }}
        ```
# {{ end }}

{{ end }}
