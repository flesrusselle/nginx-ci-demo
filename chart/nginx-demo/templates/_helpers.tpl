{{/* Helper template to return the chart name */}}
{{- define "nginx-ci-demo.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}

{{- define "nginx-ci-demo.fullname" -}}
{{- printf "%s" (include "nginx-ci-demo.name" .) -}}
{{- end -}}
