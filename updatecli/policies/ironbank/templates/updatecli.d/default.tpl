---
# Copyright Elasticsearch B.V. and contributors
# SPDX-License-Identifier: Apache-2.0
#
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
# {{ range .config }}

# {{ if .path }}

# {{ if not .skip_manifest }}
  hardening_manifest_{{ .path | base }}.yaml:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi_version" }}'
    sourceid: ubi_version
# if no manifest entry or yaml extensions then use the Kind: yaml
# {{ if or (not .manifest) (hasSuffix .manifest "yaml") (hasSuffix .manifest "yml") }}
    kind: yaml
    spec:
      file: {{ .path }}/{{ default "hardening_manifest.yaml" .manifest }}
      key: "$.args.BASE_TAG"
      value: '"{{ source "ubi_version" }}"'
# {{ else }}
    kind: file
    spec:
      file: {{ .path }}/{{ .manifest }}
      matchpattern: 'BASE_TAG: ".*"'
      replacepattern: 'BASE_TAG: "{{ source "ubi_version" }}"'
# {{ end }}
# {{ end }} # end if not .skip_manifest

# {{ if not .skip_dockerfile }}
  dockerfile_{{ .path | base }}:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi_version" }}'
    kind: dockerfile
    sourceid: ubi_version
    spec:
      file: {{ .path }}/{{ default "Dockerfile" .dockerfile }}
      instruction:
        keyword: "ARG"
        matcher: "BASE_TAG"
# {{ end }} # end if not .skip_dockerfile

# {{ end }} # end if .path

# {{ if .ent_search_ruby }}
  ent_search_{{ .ent_search_ruby | base }}:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi_version" }}'
    sourceid: ubi_version
    kind: file
    spec:
      file: {{ .ent_search_ruby }}
      matchpattern: "@base_tag = (')(.+)(')"
      replacepattern: '@base_tag = ${1}{{ source "ubi_version" }}$3'
# {{ end }} # end if .ent_search_ruby

# Elastic Agent and Beats use a packaging yaml definition
# {{ if .beats_packages }}
  packages_{{ .beats_packages | dir | base }}:
# {{ if or (.scm.enabled) (env "GITHUB_REPOSITORY") }}
    scmid: default
# {{ end }}
    name: 'deps(ironbank): Bump ubi version to {{ source "ubi_version" }}'
    kind: file
    sourceid: ubi_version
    spec:
      file: {{ .beats_packages }}
      matchpattern: "from: ('registry.access.redhat.com/.*):(.+)(')"
      replacepattern: 'from: $1:{{ source "ubi_version" }}$3'
# {{ end }}

# {{ end }} # end range .config

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
