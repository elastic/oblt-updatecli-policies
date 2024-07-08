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
      command: gh api /repos/{{ default $GitHubRepositoryList._0 .scm.owner }}/ecs-logging/contents/spec/spec.json --jq .sha
      environments:
        - name: GITHUB_TOKEN
        - name: PATH
  pull_request:
    kind: shell
    dependson:
      - sha
    spec:
      command: gh api /repos/{{ default $GitHubRepositoryList._0 .scm.owner }}/ecs-logging/commits/{{ source "sha" }}/pulls --jq '.[].html_url'
      environments:
        - name: GITHUB_TOKEN
        - name: PATH
  spec.json:
    name: Get specs from json
    kind: file
    spec:
      file: https://raw.githubusercontent.com/elastic/ecs-logging/main/spec/spec.json

targets:
  spec.json-update:
    name: 'synchronize ecs-logging spec'
    kind: file
    sourceid: spec.json
    spec:
      file: "{{ .spec_path }}"
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

actions:
  default:
    title: '[Automation] synchronize ecs-logging specs'
    kind: "github/pullrequest"
    scmid: "default"
    sourceid: sha
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
      description: |-
        ### What

        ECS logging specs automatic sync

        ### Why
        *Changeset*
        * {{ source "pull_request" }}
        * https://github.com/{{ default $GitHubRepositoryList._0 .scm.owner }}/ecs-logging/commit/{{ source "sha" }}

{{ end }}
