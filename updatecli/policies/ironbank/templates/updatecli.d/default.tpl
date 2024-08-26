---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
  ubi_version:
    name: 'Get ubi version from {{ .ubi_version_path }}'
    kind: file
    spec:
      file: '{{ .ubi_version_path }}/-/raw/{{ .ubi_version_branch }}/Dockerfile?ref_type=heads'
      matchpattern: 'FROM registry.access.redhat.com/ubi\d+:(.+)'
    transformers:
      - findsubmatch:
          pattern: 'FROM .*:(.*)'
          captureindex: 1

targets:
  hardening_manifest.yaml:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi_version" }}'
    kind: yaml
    sourceid: ubi_version
    spec:
      file: '{{ .path }}/hardening_manifest.yaml'
      key: "$.args.BASE_TAG"
      value: '"{{ source "ubi_version" }}"'

  dockerfile:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi_version" }}'
    kind: dockerfile
    sourceid: ubi_version
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
# {{ if .signedcommit }}
      commitusingapi: {{ .signedcommit }}
# {{ end }}

actions:
  default:
    title: 'deps: Bump ironbank version to {{ source "ubi_version" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
# {{ range .pull_request.labels }}
        - {{ . }}
# {{ end }}
    scmid: "default"
{{ end }}
