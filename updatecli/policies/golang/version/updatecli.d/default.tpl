---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
    golang:
        name: Get latest Golang version
        kind: golang

targets:
    go-version:
        name: 'deps(.go-version): Bump Golang version to {{ source "golang" }}'
        kind: file
#{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
        scmid: default
# {{ end }}
        sourceid: golang
        spec:
          content: '{{ source `golang` }}'
          file: {{ .path }}/.go-version

conditions:
  container:
    name: "Ensure latest container image is publish"
    kind: dockerimage
    spec:
      image: golang
      tag: '{{ source "golang" }}'

{{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
scms:
  default:
    kind: "github"
    spec:
      # Priority set to the environment variable
      user: '{{ default $GitHubUser .scm.user}}'
      email: '{{ .scm.email }}'
      owner: '{{ default $GitHubRepositoryList._0 .scm.owner }}'
      repository: '{{ default $GitHubRepositoryList._1 .scm.repository}}'
      token: '{{ default $GitHubPAT .scm.token }}'
      username: '{{ default $GitHubUsername .scm.username }}'
      branch: '{{ .scm.branch }}'

actions:
  default:
    title: 'deps: Bump Golang version to {{ source "golang" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
    scmid: "default"
{{ end }}
