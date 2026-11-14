# Parte práctica · GitOps con Argo CD

Exposición del Tema 6 (GitOps), Grupo J: Cristal Ariza, David Payares y José Rodríguez. Expone la práctica: José.

## Estado al 13 de noviembre de 2026

| Pieza | Estado |
|---|---|
| Repo público | https://github.com/Armandoj1/gitops-medicops-demo, en `main` |
| Clúster local (kind + Argo CD v3.5.7) | Instalado en el portátil de José. Arranca solo con Docker |
| Aplicación | Versión 1.0, verde, 2 pods. Argo CD en Synced / Healthy |
| Guion guiado (`demo/presentar.ps1`) | Probado de punta a punta, también arrancando con Docker apagado |
| Vista de réplicas (`demo/ver-replicas.ps1`) | Probada |
| Accesos directos en el escritorio de José | «Demo GitOps» y «Ver replicas» |

**Sin probar todavía:**

- El acto 1 hecho en GitHub desde el navegador, de principio a fin y bien escrito. El cambio en sí sí se probó, hecho desde la terminal (opción B). En un ensayo se cambió el nombre de la variable en vez de su valor y Kubernetes lo rechazó (ver «Si algo falla»).
- Montar la demo en el PC de Cristal o de David. No se ha intentado.

**Tiempos medidos:**

| Momento | Tiempo |
|---|---|
| De Docker apagado a listo para el acto 1 | 58 s |
| Acto 1: del commit a la página en v2 con 4 pods | 15 s (hasta 30 s) |
| Acto 2: Argo CD vuelve a crear la app borrada | 2 a 3 s |
| Acto 3: del revert a la página en v1 con 2 pods | 22 s (hasta 35 s) |

## Qué muestra el ejemplo, en una frase

Una página de estado de MedicOps corre en un Kubernetes del portátil y **nadie la despliega a mano**. Argo CD mira el
repo cada 15 segundos y deja el clúster igual a lo que dice Git.

```
Desarrollador --commit--> GitHub (app/deployment.yaml) <--revisa cada 15 s-- Argo CD --aplica--> Kubernetes --> localhost:8080
```

## Qué hay en el repo

| Ruta | Para qué |
|---|---|
| `app/deployment.yaml` | La app: versión, color, mensaje y número de copias (`replicas`). **El único archivo que se edita en la demo** |
| `app/service.yaml` | Publica la página en http://localhost:8080 |
| `argocd/aplicacion.yaml` | Le dice a Argo CD qué repo y qué carpeta vigilar, con sincronización y autocorrección automáticas |
| `demo/presentar.ps1` | **El guion guiado**: lleva los 3 actos con Enter, dice qué decir y cronometra |
| `demo/ver-replicas.ps1` | Ventana en vivo: cuántas copias corren y cuál atendió cada visita |
| `demo/1-preparar.ps1` | Crea el clúster e instala Argo CD (solo la primera vez, o si algo se dañó) |
| `demo/2-abrir.ps1` | Abre las pestañas y copia la clave de Argo CD |
| `demo/3-sabotear.ps1` | Borra la app a la fuerza (lo usa el acto 2) |
| `demo/4-apagar.ps1` | Borra el clúster. **No correrlo antes de exponer** |

## Antes de exponer (5 minutos)

1. Doble clic en **«Demo GitOps»** en el escritorio. Si Docker está apagado lo enciende solo; en menos de un minuto queda listo.
2. Se abren 3 pestañas: la página (8080), Argo CD (8081) y el editor del YAML en GitHub.
3. En Argo CD inicia sesión: usuario `admin`; la clave ya quedó en el portapapeles (Ctrl+V). Entra a la tarjeta **medicops-estado**.
4. Verifica que GitHub tenga la sesión iniciada, porque el acto 1 se edita allí.
5. Doble clic en **«Ver replicas»** y acomoda las ventanas: navegador grande, y al lado la del guion y la de réplicas.
6. La ventana del guion debe decir **«La pagina esta en la version 1.0 con 2 pods»**.

## Guion de los 3 actos

### Acto 1 · Un commit es un despliegue

- **Qué demuestra:** para sacar una versión nueva no se entra al servidor. Basta cambiar un archivo en Git.
- **Qué se hace:** en la pestaña de GitHub se cambian 4 cosas. **Solo las líneas `value:` y `replicas`; las líneas `- name:` no se tocan.**

  ```
  replicas: 2               ->  4
  - name: VERSION           (no tocar)
    value: "1.0"            ->  "2.0"
  - name: COLOR             (no tocar)
    value: "#0f766e"        ->  "#7c3aed"
  - name: MENSAJE           (no tocar)
    value: "Todos los..."   ->  "Nueva version desplegada desde Git"
  ```

  Luego el botón verde **Commit changes**, «Commit directly to main» y otra vez **Commit changes**. En la ventana del guion, Enter.
- **Plan B:** si GitHub falla, en vez de Enter se escribe **B** y Enter, y el cambio se hace desde la terminal.
- **Qué se ve:** Argo CD detecta el commit y aparecen 4 pods. La página pasa de verde v1.0 a **morada v2.0**, y «Ver replicas» pasa de 2 a 4 copias.
- **Qué decir:** *«Nadie se conectó al servidor: solo hicimos un commit.»*

### Acto 2 · Alguien borra producción a mano

- **Qué demuestra:** lo que se cambie por fuera de Git se corrige solo (autocorrección).
- **Qué se hace:** Enter en la ventana del guion, que borra la app con `kubectl`.
- **Qué se ve:** la página se pone **roja, «CAÍDO»**. En Argo CD la app sale roja o amarilla un instante. En 2 o 3 segundos todo vuelve solo a morado v2.0 con 4 copias. Puede haber un segundo parpadeo rojo cuando se apagan los pods viejos; se recupera solo.
- **Qué decir:** *«El cambio que no está en Git no sobrevive. Es un termostato: abres la ventana y vuelve a 22 grados.»*

### Acto 3 · La versión 2 salió mal: rollback

- **Qué demuestra:** volver atrás también es un commit, y queda registrado quién lo hizo y cuándo.
- **Qué se hace:** Enter en la ventana del guion. El guion ejecuta `git revert --no-edit HEAD` y `git push`.
- **Qué se ve:** la página vuelve a **verde v1.0 con 2 copias**. Se abre el historial de commits en GitHub, donde aparecen el despliegue y la reversa, con autor y hora.
- **Qué decir:** *«No borramos historia: agregamos un commit que deshace el anterior. Git es la bitácora.»*

### Cómo demostrar las réplicas

`replicas` es cuántas copias de la app corren a la vez. La ventana «Ver replicas» lo muestra en vivo:

- Antes del acto 1: 2 copias, y las visitas repartidas entre 2 nombres de pod.
- Después del acto 1: 4 copias, con 2 pods nuevos de pocos segundos de edad, y las visitas repartidas entre 4.
- En el acto 2: «(nadie respondió)» en rojo un par de segundos, y vuelven las 4.
- En el acto 3: otra vez 2.

**Qué decir:** *«Escalar tampoco requiere entrar al servidor: cambié un 2 por un 4 en Git y Kubernetes prendió 2 copias más.»*

### Cierre

*«Con GitOps, Git es la única fuente de verdad: desplegar, corregir y volver atrás se hace con commits, y Argo CD se
encarga de que el servidor siempre quede igual a lo que dice Git.»*

## Si algo falla

| Qué pasa | Qué hacer |
|---|---|
| A los 45 s la página no cambia | En Argo CD, botón **REFRESH** de la aplicación: revisa Git en el momento |
| Argo CD marca **OutOfSync** con error y la página no cambia | El YAML quedó mal escrito (por ejemplo, se cambió `- name: MENSAJE` en vez de su `value:`). Corregirlo en GitHub con otro commit. Sirve para contarlo: Argo CD no rompe producción, rechaza el cambio y la versión buena sigue funcionando |
| Se olvidó la clave de Argo CD | Correr `.\demo\2-abrir.ps1` en la carpeta del repo: la vuelve a copiar |
| La ventana del guion se cerró a mitad de la demo | Volver a abrir «Demo GitOps». Si la página quedó en v2, hacer el acto 3 antes de empezar de nuevo |
| El guion dice que el último commit no es el del acto 1 | No revertir a ciegas. Revisar el historial en GitHub: el acto 3 siempre deshace el último commit |
| Nada responde | Correr `.\demo\1-preparar.ps1` (tarda 1 minuto; 10 si tiene que descargar imágenes) |

## Montarlo en otro PC

Hace falta Docker Desktop, `kubectl` y `kind`. Luego:

```powershell
git clone https://github.com/Armandoj1/gitops-medicops-demo.git
cd gitops-medicops-demo
.\demo\1-preparar.ps1      # la primera vez tarda unos 10 minutos
.\demo\presentar.ps1
```

Para hacer los actos 1 y 3 desde la terminal hay que poder hacer push a este repo; pedirle a José que lo agregue como
colaborador.

## Después de exponer

`.\demo\4-apagar.ps1` borra el clúster y libera la memoria del portátil.
