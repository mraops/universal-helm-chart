{{/*
Reusable ConfigMap template for single or multi app.
Parameters:
  root: root . context
  app:  application values (single or item from apps[])
*/}}
{{- define "base.configmap" -}}
{{- $root := .root }}
{{- $app := .app }}
{{- if $app.configmap }}
{{range $app.configmap }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "base.fullname" $root }}-{{ .name }}-configmap
  labels:
    app.kubernetes.io/name: {{ .name | default (include "base.fullname" $root) }}
    {{- include "base.labels" $root | nindent 4 }}
data:
 {{- toYaml .data | nindent 2 }}
---
{{- end }}

{{- end }}
{{- end }}
