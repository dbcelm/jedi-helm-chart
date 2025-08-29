{{/*
Expand the name of the chart.
*/}}
{{- define "helm-template.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm-template.fullname" -}}
{{- $name := default .Chart.Name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-template.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "helm-template.labels" -}}
helm.sh/chart: {{ include "helm-template.chart" . }}
{{ include "helm-template.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "helm-template.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Shared Environment Variables
- Renders an env list for a named group from .Values.environmentVariables
- Intended to be appended after per-service env vars
*/}}
{{- define "helm-template.sharedEnvironmentVariables" -}}
{{- $group := .group -}}
{{- $values := .Values -}}
{{- if hasKey $values.environmentVariables $group }}
{{- range (index $values.environmentVariables $group) }}
- name: {{ .name }}
  value: "{{ .value }}"
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Merge service configuration with global defaults
*/}}
{{- define "helm-template.mergeServiceConfig" -}}
{{- $defaults := .Values.global -}}
{{- $serviceConfig := .serviceConfig -}}
{{- $merged := merge (deepCopy $defaults) $serviceConfig -}}
{{- $merged | toYaml -}}
{{- end }}

{{/*
Get merged service configuration
*/}}
{{- define "helm-template.getServiceConfig" -}}
{{- $serviceName := .serviceName -}}
{{- $values := .Values -}}
{{- $serviceConfig := index $values.services $serviceName -}}
{{- $merged := merge (deepCopy $values.global) $serviceConfig -}}
{{- $merged -}}
{{- end }}


{{/*
Metadata name base prefix - returns the service ID passed as parameter
*/}}
{{- define "_metaNameBase" -}}
{{- . -}}
{{- end }}


{{/*
Service metadata name base
*/}}
{{- define "helm-template.serviceMetaNameBase" -}}
{{ include "_metaNameBase" .}}-svc
{{- end }}


{{/*
Deployment metadata name base
*/}}
{{- define "helm-template.deploymentMetaNameBase" -}}
{{ include "_metaNameBase" .}}-dep
{{- end }}


{{/*
HPA metadata name base
*/}}
{{- define "helm-template.hpaMetaNameBase" -}}
{{ include "_metaNameBase" .}}-hpa
{{- end }}


{{/*
Ingress metadata name base
*/}}
{{- define "helm-template.ingressMetaNameBase" -}}
{{ include "_metaNameBase" .}}-ing
{{- end }}


{{/*
Cronjob metadata name base
*/}}
{{- define "helm-template.cronjobMetaNameBase" -}}
{{ include "_metaNameBase" .}}-crn
{{- end }}


{{/*
Statefulset metadata name base
*/}}
{{- define "helm-template.statefulsetMetaNameBase" -}}
{{ include "_metaNameBase" .}}-sts
{{- end }}


{{/*
Daemonset metadata name base
*/}}
{{- define "helm-template.daemonsetMetaNameBase" -}}
{{ include "_metaNameBase" .}}-dmn
{{- end }}


{{/*
Configmap metadata name base
*/}}
{{- define "helm-template.configmapMetaNameBase" -}}
{{ include "_metaNameBase" .}}-cfg
{{- end }}


{{/*
Secret metadata name base
*/}}
{{- define "helm-template.secretMetaNameBase" -}}
{{ include "_metaNameBase" .}}-sec
{{- end }}


{{/*
PersistentVolume metadata name base
*/}}
{{- define "helm-template.persistentvolumeMetaNameBase" -}}
{{ include "_metaNameBase" .}}-pv
{{- end }}


{{/*
PersistentVolumeClaim metadata name base
*/}}
{{- define "helm-template.persistentvolumeclaimMetaNameBase" -}}
{{ include "_metaNameBase" .}}-pvc
{{- end }}


{{/*
StorageClass metadata name base
*/}}
{{- define "helm-template.storageclassMetaNameBase" -}}
{{ include "_metaNameBase" .}}-sc
{{- end }}


{{/*
ServiceAccount metadata name base
*/}}
{{- define "helm-template.serviceaccountMetaNameBase" -}}
{{ include "_metaNameBase" .}}-sa
{{- end }}


{{/*
Role metadata name base
*/}}
{{- define "helm-template.roleMetaNameBase" -}}
{{ include "_metaNameBase" .}}-rl
{{- end }}


{{/*
RoleBinding metadata name base
*/}}
{{- define "helm-template.rolebindingMetaNameBase" -}}
{{ include "_metaNameBase" .}}-rb
{{- end }}


{{/*
ServiceAccount autofill
*/}}
{{- define "helm-template.serviceAccountName" -}}
{{- $serviceConfig := .serviceConfig | default dict -}}
{{- $values := .Values | default dict -}}
{{- $legacySA := (dig "serviceAccount" "name" "" $serviceConfig) -}}
{{- $svcSA := (or $serviceConfig.serviceAccountName $legacySA) -}}
{{- default (default "default" $values.global.serviceAccountName) $svcSA -}}
{{- end -}}


{{/*
Build full image reference with flexible inputs.
Precedence:
1) service.image.repository (full "repo/name")
2) global.image.repository
3) (service.image.repo | global.image.repo | global.repoName) + "/" + (service.image.name | global.image.name | serviceName)
Tag precedence: service.image.tag | global.image.tag | Chart.AppVersion
*/}}
{{- define "helm-template.imageRef" -}}
{{- $serviceName := .serviceName -}}
{{- $values := .Values -}}
{{- $chart := .Chart -}}
{{- $svc := .serviceConfig | default dict -}}
{{- $img := $svc.image | default dict -}}
{{- $defImg := $values.global.image | default dict -}}
{{- $explicitRepo := (or $img.repository $defImg.repository) -}}
{{- $repoHost := (or $img.repo $defImg.repo $values.global.repoName) -}}
{{- $imageName := (or $img.name $defImg.name $serviceName) -}}
{{- $tag := (or $img.tag $defImg.tag $chart.AppVersion) -}}
{{- if $explicitRepo -}}
{{- printf "%s:%s" $explicitRepo $tag -}}
{{- else -}}
{{- if $repoHost -}}
{{- printf "%s/%s:%s" $repoHost $imageName $tag -}}
{{- else -}}
{{- printf "%s:%s" $imageName $tag -}}
{{- end -}}
{{- end -}}
{{- end -}}
