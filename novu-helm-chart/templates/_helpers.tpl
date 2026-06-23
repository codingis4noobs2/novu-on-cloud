{{/*
Expand the name of the chart.
*/}}
{{- define "novu.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "novu.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart label.
*/}}
{{- define "novu.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "novu.labels" -}}
helm.sh/chart: {{ include "novu.chart" . }}
app.kubernetes.io/name: {{ include "novu.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels.
*/}}
{{- define "novu.selectorLabels" -}}
app.kubernetes.io/name: {{ include "novu.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Build an ECR image reference for Novu app containers.
*/}}
{{- define "novu.ecrImage" -}}
{{- printf "%s/%s:%s" .root.Values.registry .service.image.repository .service.image.tag -}}
{{- end -}}

{{/*
StorageClass name used by StatefulSet PVCs.
*/}}
{{- define "novu.storageClassName" -}}
{{- if and .Values.localStorage .Values.localStorage.enabled -}}
{{- .Values.localStorage.storageClassName -}}
{{- else -}}
{{- .Values.storageClass.name -}}
{{- end -}}
{{- end -}}

{{/*
Default MongoDB replica set connection string.
*/}}
{{- define "novu.mongoUrl" -}}
{{- if .Values.secrets.MONGO_URL -}}
{{- .Values.secrets.MONGO_URL -}}
{{- else -}}
{{- $fullname := include "novu.fullname" . -}}
{{- if .Values.mongodb.replicaSet.enabled -}}
{{- printf "mongodb://%s:%s@%s-mongodb-0.%s-mongodb-headless:%v,%s-mongodb-1.%s-mongodb-headless:%v/admin?replicaSet=%s&authSource=admin" .Values.secrets.MONGO_INITDB_ROOT_USERNAME .Values.secrets.MONGO_INITDB_ROOT_PASSWORD $fullname $fullname (.Values.mongodb.service.port | int) $fullname $fullname (.Values.mongodb.service.port | int) .Values.mongodb.replicaSet.name -}}
{{- else -}}
{{- printf "mongodb://%s:%s@%s-mongodb-headless:%v/admin?authSource=admin" .Values.secrets.MONGO_INITDB_ROOT_USERNAME .Values.secrets.MONGO_INITDB_ROOT_PASSWORD $fullname (.Values.mongodb.service.port | int) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Use a supplied secret value, reuse the existing Kubernetes Secret on upgrades,
or generate a new value on first install. This mirrors setup.sh behavior for
JWT_SECRET, STORE_ENCRYPTION_KEY, and NOVU_SECRET_KEY without rotating them
on each Helm upgrade.
*/}}
{{- define "novu.generatedSecret" -}}
{{- $provided := .value | default "" -}}
{{- $secretName := printf "%s-secret" (include "novu.fullname" .root) -}}
{{- $existing := lookup "v1" "Secret" .root.Release.Namespace $secretName -}}
{{- if $provided -}}
{{- $provided -}}
{{- else if and $existing (hasKey $existing.data .key) -}}
{{- index $existing.data .key | b64dec -}}
{{- else -}}
{{- randAlphaNum .length -}}
{{- end -}}
{{- end -}}
