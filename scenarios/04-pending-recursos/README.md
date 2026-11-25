# 04 · Pending: recursos insuficientes en el cluster

> Namespace del escenario: `lab-04` · Directorio: `scenarios/04-pending-recursos/`

## Practicar

```bash
scripts/lab.sh break 4    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 4    # ¿ya está resuelto?
scripts/lab.sh fix 4      # aplica la solución de referencia
scripts/lab.sh clean 4    # borra el namespace
```

## Síntomas

El pod se queda en `Pending` indefinidamente, sin nodo asignado (`NODE` vacío) y sin logs.

## Diagnóstico

Un pod `Pending` sin nodo lo bloquea el scheduler. El motivo está en los eventos `FailedScheduling` y se contrasta con la capacidad de los nodos.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-04 get pods
NAME                     READY   STATUS    RESTARTS   AGE
batch-7ff4d47698-bsl95   0/1     Pending   0          15s

$ kubectl -n lab-04 describe pod -l app=batch | sed -n '/Events:/,$p'
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  15s   default-scheduler  0/2 nodes are available: 1 Insufficient cpu, 1 Insufficient memory, 1 node(s) had untolerated taint(s). preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

$ kubectl get nodes -o custom-columns=NODE:.metadata.name,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory
NODE                                CPU   MEM
troubleshooting-lab-control-plane   22    31644Mi
troubleshooting-lab-worker          22    31644Mi
```

## Causa raíz

El pod pide 200 CPUs y 64 GiB de memoria; ningún nodo tiene tanta capacidad (el control-plane además tiene un taint). El scheduler no encuentra dónde colocarlo.

## Solución

Pedir lo que realmente necesita (`100m` de CPU y `64Mi`, ver `solution.yaml`). Si la necesidad fuera real, la solución sería añadir nodos o activar el cluster autoscaler.

## Prevención

- Revisar `requests` en los PR (un cero de más es muy común: `cpu: 1000` en vez de `1000m`).
- `LimitRange` con máximos por contenedor para rechazar peticiones absurdas.
- Alerta sobre pods `Pending` durante más de 5 minutos.
