# 03 · OOMKilled: el contenedor supera su límite de memoria

> Namespace del escenario: `lab-03` · Directorio: `scenarios/03-oomkilled/`

## Practicar

```bash
scripts/lab.sh break 3    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 3    # ¿ya está resuelto?
scripts/lab.sh fix 3      # aplica la solución de referencia
scripts/lab.sh clean 3    # borra el namespace
```

## Síntomas

El pod reinicia continuamente. `STATUS` muestra `OOMKilled` o `CrashLoopBackOff`, y el código de salida es 137 (128 + SIGKILL).

## Diagnóstico

El log de la aplicación no menciona nada: el kernel la mata sin darle opción a escribir. La prueba está en `lastState.terminated.reason` del pod.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-03 get pods
NAME                      READY   STATUS      RESTARTS      AGE
worker-7bd995c656-vkxm5   0/1     OOMKilled   3 (44s ago)   60s

$ kubectl -n lab-03 describe pod -l app=worker | sed -n '/Last State:/,/Ready:/p'
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Tue, 24 Nov 2026 20:34:54 +0100
      Finished:     Tue, 24 Nov 2026 20:34:54 +0100
    Ready:          False

$ kubectl -n lab-03 get pod -l app=worker -o jsonpath='{.items[0].status.containerStatuses[0].lastState.terminated.reason}'
OOMKilled
```

## Causa raíz

El contenedor necesita unas decenas de MiB para cargar su carga de trabajo, pero el `limit` de memoria es 20 Mi. El cgroup del kernel mata el proceso al superarlo.

## Solución

Subir el límite a un valor realista (`256Mi` en `solution.yaml`) tras medir el consumo real. Si la app tiene una fuga de memoria, subir el límite solo la retrasa: hay que arreglar la fuga.

## Prevención

- Dimensionar `requests`/`limits` a partir de métricas reales (`kubectl top pod`, Prometheus), no a ojo.
- Alertar por `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`.
- Usar `LimitRange` y `ResourceQuota` por namespace para tener valores por defecto sensatos.
