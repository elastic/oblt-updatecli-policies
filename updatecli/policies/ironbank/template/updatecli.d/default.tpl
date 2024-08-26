---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
  ubi-version:
    ame: Get latest ubi version
    kind: file
    spec:
      file: '{{ .ubi-version-path }}/-/raw/{{ .ubi-version-branch }}/Dockerfile?ref_type=heads'
      matchpattern: 'FROM registry.access.redhat.com/ubi\d+:(.*)'
      replacepattern: '$1'

targets:
  hardening_manifest.yaml:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi-version" }}'
    kind: yaml
    sourceid: ubi-version
    spec:
      file: '{{ .path }}/hardening_manifest.yaml'
      key: "args.BASE_TAG"

  dockerfile:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi-version" }}'
    kind: dockerfile
    sourceid: ubi-version
    spec:
      file: '{{ .path }}/Dockerfile'
      instruction:
        keyword: "ARG"
        matcher: "BASE_TAG"

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
# {{ if .scm.signedcommit }}
      commitusingapi: {{ .scm.signedcommit }}
# {{ end }}

actions:
  default:
    title: 'deps: Bump ironbank version to {{ source "obs-test-env" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
# {{ range .pull_request.labels }}
        - {{ . }}
# {{ end }}
    scmid: "default"
{{ end }}
