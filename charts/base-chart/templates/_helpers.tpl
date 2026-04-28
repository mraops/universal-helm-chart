{{/*
Fully qualified application name (release name, with override support)
*/}}
{{- define "base.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- $name := default .Release.Name .Values.global.nameOverride }}
  {{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
  {{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
chart metadata label
*/}}
{{- define "base.chart" -}}
{{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common selector labels — SHOULD NOT contain redundant fields
*/}}
{{- define "base.selectorLabels" -}}
app.kubernetes.io/part-of: {{ .Release.Name }}
{{- end }}

{{/*
Standard production-grade labels
*/}}
{{- define "base.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "base.chart" . }}
app.kubernetes.io/part-of: {{ .Values.global.partOf | default .Release.Name }}
{{- if .Values.global.customLabels }}
{{- range $key, $value := .Values.global.customLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Reusable annotations block
*/}}
{{- define "base.annotations" -}}
{{- if or .Values.global.customAnnotations .Values.monitoring .Values.istio .Values.logging }}
annotations:
  # user-defined custom annotations
  {{- if .Values.global.customAnnotations }}
  {{- toYaml .Values.global.customAnnotations | nindent 2 }}
  {{- end }}

  # Prometheus auto-discovery
  {{- if .Values.monitoring }}
  prometheus.io/scrape: "{{ .Values.monitoring.scrape | default "true" }}"
  prometheus.io/port: "{{ .Values.monitoring.port | default "9090" }}"
  prometheus.io/path: "{{ .Values.monitoring.path | default "/metrics" }}"
  {{- end }}

  # Istio service mesh control
  {{- if .Values.istio.inject }}
  sidecar.istio.io/inject: "{{ .Values.istio.inject }}"
  {{- end }}

  # Logging (Fluentbit, Loki, Vector)
  {{- if .Values.logging.parser }}
  fluentbit.io/parser: "{{ .Values.logging.parser }}"
  {{- end }}
{{- end }}
{{- end }}