---
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
      file: 'https://github.com/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm/commit/{{ .scm.branch }}.patch'
      matchpattern: "^From\\s([0-9a-f]{40})\\s"
    transformers:
      - findsubmatch:
          pattern: "[0-9a-f]{40}"
  pull_request:
    kind: shell
    dependson:
      - sha
    spec:
      command: gh api /repos/{{ .scm.owner }}/apm/commits/{{ source "sha" }}/pulls --jq '.[].html_url'
      environments:
        - name: GITHUB_TOKEN
        - name: PATH
  agents-json-specs-tarball:
    kind: shell
    scmid: apm
    dependson:
      - sha
    spec:
      command: tar cvzf {{ requiredEnv "GITHUB_WORKSPACE" }}/json-specs.tgz .
      environments:
        - name: PATH
      workdir: 'tests/agents/json-specs'

targets:
  agent-json-specs:
    name: APM agent json specs {{ source "sha" }}
    disablesourceinput: true
    kind: shell
    spec:
      # git diff helps to print what it changed, If it is empty, then updatecli report a success with no changes applied.
      # See https://www.updatecli.io/docs/plugins/resource/shell/#_shell_target
      command: 'tar -xzf {{ requiredEnv "GITHUB_WORKSPACE" }}/json-specs.tgz && git --no-pager diff'
      workdir: "{{ .apm_json_specs_path }}"
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
#{{ if .signedcommit }}
      commitusingapi: {{ .signedcommit }}
# {{ end }}

  apm:
    kind: github
    spec:
      user: '{{ default $GitHubUsername .scm.username }}'
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: 'apm'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'
actions:
  default:
    title: '[Automation] Update JSON specs'
    kind: "github/pullrequest"
    scmid: "default"
    sourceid: sha
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
      description: |-
        ### What
        APM agent specs automatic sync

        ### Why
        *Changeset*
        * {{ source "pull_request" }}
        * https://github.com/{{ default $GitHubRepositoryList._0 .scm.owner }}/apm/commit/{{ source "sha" }}

{{ end }}
