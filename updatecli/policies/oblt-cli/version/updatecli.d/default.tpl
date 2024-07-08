---
# Helpers
# {{ $GitHubUser := env ""}}
# {{ $GitHubRepositoryList := env "GITHUB_REPOSITORY" | split "/"}}
# {{ $GitHubPAT := env "GITHUB_TOKEN"}}
# {{ $GitHubUsername := env "GITHUB_ACTOR"}}

name: '{{ .name }}'
pipelineid: '{{ .pipelineid }}'

sources:
  obs-test-env:
    name: Get latest oblt-cli version from elastic/observability-test-environments
    kind: githubRelease
    spec:
      repository: elastic/observability-test-environments
      token: "{{ default $GitHubPAT .scm.token }}"
      username: "{{ default $GitHubUsername .scm.username }}"
      versionFilter:
        kind: latest

targets:
  oblt-cli-version-file:
    name: 'deps(oblt-cli): Bump oblt-cli version to {{ source "obs-test-env" }}'
    kind: file
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    sourceid: obs-test-env
    spec:
      file: '{{ .path }}'
# {{ if hasSuffix '.tool-versions' .path }}
      matchpattern: '^oblt-cli\s+\d+\.\d+\.\d+'
      content: 'oblt-cli {{ source `obs-test-env` }}'
# {{ else }}
      content: '{{ source `obs-test-env` }}'
# {{ end }}


# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
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
# {{ if .signedcommit }}
      commitusingapi: {{ .signedcommit }}
# {{ end }}

actions:
  default:
    title: 'deps: Bump oblt-cli version to {{ source "obs-test-env" }}'
    kind: "github/pullrequest"
    spec:
      automerge: {{ .automerge }}
      labels:
         - dependencies
    scmid: "default"
{{ end }}
