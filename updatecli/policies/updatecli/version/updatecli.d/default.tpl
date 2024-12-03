---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
  version:
    name: Get latest updatecli version from updatecli/updatecli
    kind: githubrelease
    spec:
      owner: updatecli
      repository: updatecli
      token: "{{ default $GitHubPAT .scm.token }}"
      username: "{{ default $GitHubUsername .scm.username }}"
      versionFilter:
        kind: latest

targets:
  updatecli-version-file:
    name: 'deps(updatecli): Bump updatecli version to {{ source "version" }}'
    kind: file
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    sourceid: version
    spec:
      file: '{{ .path }}'
# {{ if hasSuffix ".tool-versions" .path }}
      matchpattern: '^updatecli\s+v\d+\.\d+\.\d+'
      content: 'updatecli {{ source `version` }}'
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
    title: 'deps: Bump updatecli version to {{ source "version" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
# {{ range .pull_request.labels }}
        - {{ . }}
# {{ end }}
    scmid: "default"
{{ end }}
