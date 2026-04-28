{{/*
Reusable Deployment template for single or multi app.
Parameters:
  root: root . context
  app:  application values (single or item from apps[])
*/}}

{{- define "base.deployment" -}}
{{- $root := .root }}
{{- $app := .app }}
{{- $appversion := "" -}}
{{- $imagerepository := "" -}}
{{- $imagepullpolicy := "" -}}
{{- if $app.image -}}
{{- $appversion = $app.image.tag | default "latest" -}}
{{- $imagerepository = $app.image.repository -}}
{{- $imagepullpolicy = $app.image.pullPolicy | default "IfNotPresent" -}}
{{- else if $root.Values.global.image -}}
{{- $appversion = $root.Values.global.image.tag | default "latest" -}}
{{- $imagerepository = $root.Values.global.image.repository -}}
{{- $imagepullpolicy = $root.Values.global.image.pullPolicy | default "IfNotPresent" -}}
{{- else -}}
{{- $appversion = $root.Values.image.tag | default "latest" -}}
{{- $imagerepository = $root.Values.image.repository -}}
{{- $imagepullpolicy = $root.Values.image.pullPolicy | default "IfNotPresent" -}}
{{- end -}}



{{- if eq $root.Values.global.deploymentType "Deployment" }}
{{- if or $app.image $root.Values.global.image $root.Values.image }}

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $app.name | default (include "base.fullname" $root) }}
  labels:
    app.kubernetes.io/name: {{ $app.name | default (include "base.fullname" $root) }}
    app.kubernetes.io/version: "{{ $appversion }}"
    {{- include "base.labels" $root | nindent 4 }}

spec:
  {{- $replicas := 1 }}
  {{- if kindIs "float64" $app.replicaCount }}
    {{- $replicas = int $app.replicaCount }}
  {{- else if kindIs "int" $app.replicaCount }}
    {{- $replicas = $app.replicaCount }}
  {{- end }}
  replicas: {{ $replicas }}

  selector:
    matchLabels:
      app.kubernetes.io/name: {{ $app.name | default (include "base.fullname" $root) }}
      {{- include "base.selectorLabels" $root | nindent 6 }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ $app.name | default (include "base.fullname" $root) }}
        app.kubernetes.io/version: "{{ $appversion }}"
        {{- include "base.labels" $root | nindent 8 }}

    spec:
      {{- if $app.securityContext -}}
      {{- with $app.securityContext.pod }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end -}}
      {{- end }}

      {{- if $app.imagePullSecrets }}
      imagePullSecrets:
        {{- range $app.imagePullSecrets }}
        - name: {{ . }}
        {{- end }}
      {{- end }}

      {{- if $app.serviceAccount }}
      serviceAccountName: {{ $app.serviceAccount }}
      {{- end }}
      automountServiceAccountToken: {{ $app.automountServiceAccountToken | default (false)}}

      {{- with $app.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with $app.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- with $app.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}

      {{- if $app.hostNetwork }}
      hostNetwork: {{ $app.hostNetwork }}
      {{- end }}

      containers:
        - name: {{ $app.name | default (include "base.fullname" $root) }}
          image: "{{ $imagerepository }}:{{ $appversion }}"
          imagePullPolicy: {{ $imagepullpolicy }}

          {{- if $app.command }}
          command:
            {{- range $app.command }}
            - {{ . | quote }}
            {{- end }}
          {{- end }}

          {{- if $app.args }}
          args:
            {{- range $app.args }}
            - {{ . | quote }}
            {{- end }}
          {{- end }}
          {{- if and $app.service $app.service.ports }}
          ports:
            {{- range $app.service.ports }}
            - name: {{ .name | default "http" }}
              protocol: {{ .protocol | default "TCP" }}
              containerPort: {{ .targetPort }}
            {{- end }}
            {{- end }}
          {{- if $app.securityContext -}}
          {{- with $app.securityContext.container }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- end }}
          {{- if or $app.env $app.secrets }}
          env:
          {{- with $app.env }}
            {{- range . }}
            - name: {{ .name }}
              value: {{ .value | quote }}
            {{- end }}
          {{- end }}
          {{- $secret := $app.secrets }}
            {{- $secretName := $secret.name | default (printf "%s-secret" $root.Release.Name ) }}
            {{with $secret }}
            {{- range $key, $value := $secret }}
            - name: {{ $key | upper }}
              valueFrom:
                secretKeyRef:
                  name: {{ $secretName }}
                  key: {{ $key }}
            {{- end }}
          {{- end }}
          {{- end }}
          resources:
            {{- if $app.resources }}
            limits:
              {{- if $app.resources.cpu }}
              cpu: {{ $app.resources.cpu | quote | default "100m" }}
              {{- end }}
              {{- if $app.resources.memory }}
              memory: {{ $app.resources.memory | quote | default "512Mi" }}
              {{- end }}
            requests:
              {{- if $app.resources.cpu }}
              cpu: {{ $app.resources.cpu | quote | default "100m" }}
              {{- end }}
              {{- if $app.resources.memory }}
              memory: {{ $app.resources.memory | quote | default "512Mi" }}
              {{- end }}
            {{- end }}

          {{- with $app.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- with $app.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}

          {{- if or (and $app.persistence $app.persistence.claims) $app.configmap $app.extraVolumeMounts }}
          volumeMounts:
            {{- if and $app.persistence $app.persistence.claims }}
            {{- range $app.persistence.claims }}
            - name: {{ .name }}
              mountPath: {{ .podMountPath }}
            {{- end }}
            {{- end }}

            {{- if $app.configmap }}
            {{- range $app.configmap }}
            - name: {{ include "base.fullname" $root }}-{{ .name }}-configmap
              mountPath: {{ .podMountPath }}
              {{- if .readOnly }}
              readOnly: true
              {{- end }}
              {{- if .subPath }}
              subPath: {{ .subPath }}
              {{- end }}
            {{- end }}
            {{- end }}

            {{- if $app.extraVolumeMounts }}
            {{- range $app.extraVolumeMounts }}
            - name: {{ .name }}
              mountPath: {{ .mountPath }}
              {{- if .readOnly }}
              readOnly: {{ .readOnly }}
              {{- end }}
              {{- if .subPath }}
              subPath: {{ .subPath }}
              {{- end }}
            {{- end }}
            {{- end }}
          {{- end }}

      {{- if or (and $app.persistence $app.persistence.claims) $app.configmap $app.extraVolumes }}
      volumes:
        {{- if and $app.persistence $app.persistence.claims }}
        {{- range $app.persistence.claims }}
        - name: {{ .name }}
          persistentVolumeClaim:
            claimName: {{ .name }}-{{ $root.Release.Name }}
        {{- end }}
        {{- end }}

        {{- if $app.configmap }}
        {{- range $app.configmap }}
        - name: {{ include "base.fullname" $root }}-{{ .name }}-configmap
          configMap:
            name: {{ include "base.fullname" $root }}-{{ .name }}-configmap
            defaultMode: 420
        {{- end }}
        {{- end }}

        {{- if $app.extraVolumes }}
        {{- range $app.extraVolumes }}
        - name: {{ .name }}
          {{- if .persistentVolumeClaim }}
          persistentVolumeClaim:
            claimName: {{ .persistentVolumeClaim.claimName }}
          {{- end }}
          {{- if .configMap }}
          configMap:
            name: {{ .configMap.name }}
          {{- end }}
          {{- if .secret }}
          secret:
            secretName: {{ .secret.name }}
            defaultMode: 420
          {{- end }}
          {{- if .emptyDir }}
          emptyDir: {}
          {{- end }}
          {{- if .hostPath }}
          hostPath:
            path: {{ .hostPath.path }}
            type: {{ .hostPath.type | default "" }}
          {{- end }}
        {{- end }}
        {{- end }}
      {{- end }}

  {{- if $app.strategy }}
  strategy:
    type: {{ $app.strategy.type | default "RollingUpdate" }}

    {{- if eq $app.strategy.type "RollingUpdate" }}
    rollingUpdate:
      maxUnavailable: {{ $app.strategy.rollingUpdate.maxUnavailable | default "25%" }}
      maxSurge: {{ $app.strategy.rollingUpdate.maxSurge | default "25%" }}
    {{- end }}
  {{- end }}

{{- end }}
{{- end }}
{{- end }}
