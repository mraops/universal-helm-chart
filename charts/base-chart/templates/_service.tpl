{{/*
Reusable Service template for single or multi app.
Parameters:
  root: root . context
  app:  application values (single or item from apps[])
*/}}

{{- define "base.service" -}}
{{- $root := .root }}
{{- $app := .app }}
{{- $appversion := "latest" -}}
{{- if $app.image -}}
{{-   $appversion = $app.image.tag | default "latest" -}}
{{- else if $root.Values.global.image -}}
{{-   $appversion = $root.Values.global.image.tag | default "latest" -}}
{{- else -}}
{{-   $appversion = $root.Values.image.tag | default "latest" -}}
{{- end -}}
{{- if $app.service }}
apiVersion: v1
kind: Service
metadata:
  name: {{ $app.name | default (include "base.fullname" $root) }}
  labels:
    app.kubernetes.io/name: {{ $app.name | default (include "base.fullname" $root) }}
    app.kubernetes.io/version: "{{ $appversion }}"
    {{- include "base.labels" $root | nindent 4 }}

spec:
  {{- if $app.service.type }}
  type: {{ $app.service.type | default "ClusterIP" }}
  {{- end }}
  {{- if $app.service.loadBalancerIP }}
  loadBalancerIP: {{ $app.service.loadBalancerIP }}
  {{- end }}
  {{- if $app.service.externalIPs }}
  externalIPs:
    {{- toYaml $app.service.externalIPs | nindent 4 }}
  {{- end }}
  {{- if $app.service.externalTrafficPolicy }}
  externalTrafficPolicy: {{ $app.service.externalTrafficPolicy }}
  {{- end }}
  {{- if $app.service.sessionAffinity }}
  sessionAffinity: {{ $app.service.sessionAffinity }}
  {{- end }}
  ports:
    {{- range $app.service.ports }}
    - name: {{ .name | default "http" }}
      protocol: {{ .protocol | default "TCP" }}
      port: {{ .port }}
      targetPort: {{ .targetPort | default .port }}
      {{- if .nodePort }}
      nodePort: {{ .nodePort }}
      {{- end }}
    {{- end }}
  selector:
    app.kubernetes.io/name: {{ $app.name | default (include "base.fullname" $root) }}
    {{- include "base.selectorLabels" $root | nindent 4 }}

{{- end }}
{{- end }}