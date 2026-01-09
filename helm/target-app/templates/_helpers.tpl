{{/*
Expand the name of the chart.
*/}}
{{- define "target-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "target-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "target-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "target-app.labels" -}}
helm.sh/chart: {{ include "target-app.chart" . }}
{{ include "target-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for web
*/}}
{{- define "target-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "target-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Web selector labels
*/}}
{{- define "target-app.web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "target-app.name" . }}-web
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: web
{{- end }}

{{/*
MySQL selector labels
*/}}
{{- define "target-app.mysql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "target-app.name" . }}-mysql
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "target-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "target-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MySQL hostname
*/}}
{{- define "target-app.mysql.fullname" -}}
{{- printf "%s-mysql" (include "target-app.fullname" .) }}
{{- end }}

{{/*
Web fullname
*/}}
{{- define "target-app.web.fullname" -}}
{{- printf "%s-web" (include "target-app.fullname" .) }}
{{- end }}
