# 05 · Pending: nodeSelector que ningún nodo cumple

> Namespace del escenario: `lab-05` · Directorio: `scenarios/05-pending-nodeselector/`

## Practicar

```bash
scripts/lab.sh break 5    # aplica broken.yaml
# ...diagnostica con kubectl, sin mirar solution.yaml...
scripts/lab.sh check 5    # ¿ya está resuelto?
scripts/lab.sh fix 5      # aplica la solución de referencia
scripts/lab.sh clean 5    # borra el namespace
```

## Síntomas

El pod está `Pending`, igual que en el escenario anterior, pero hay capacidad de sobra.

## Diagnóstico

De nuevo `describe pod`: el evento `FailedScheduling` cambia de motivo. Compara el `Node-Selectors` del pod con las etiquetas de los nodos.

Salida **real** capturada en un cluster kind al ejecutar este escenario:

```text
$ kubectl -n lab-05 get pods
NAME                     READY   STATUS    RESTARTS   AGE
cache-7bdb486948-5n2jd   0/1     Pending   0          15s

$ kubectl -n lab-05 describe pod -l app=cache | sed -n '/Node-Selectors:/p;/Events:/,$p'
Node-Selectors:              disktype=ssd
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  15s   default-scheduler  0/2 nodes are available: 1 node(s) didn't match Pod's node affinity/selector, 1 node(s) had untolerated taint(s). preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.

$ kubectl get nodes --show-labels | cut -c1-120
NAME                                STATUS   ROLES           AGE   VERSION   LABELS
troubleshooting-lab-control-plane   Ready    control-plane   19m   v1.37.0   beta.kubernetes.io/arch=amd64,beta.kubernet
troubleshooting-lab-worker          Ready    <none>          19m   v1.37.0   beta.kubernetes.io/arch=amd64,beta.kubernet
```

## Causa raíz

El pod exige `disktype=ssd` y ningún nodo tiene esa etiqueta.

## Solución

Dos arreglos válidos: quitar el `nodeSelector` (es lo que hace `solution.yaml`) o etiquetar un nodo: `kubectl label node <nodo> disktype=ssd`. Elige según si el requisito es real.

## Prevención

- Centralizar las etiquetas de nodo en el aprovisionamiento (Terraform/Ansible), no a mano.
- Preferir `nodeAffinity` con `preferredDuringScheduling` cuando el requisito sea una preferencia.
- Alerta sobre pods `Pending`.
