# Bitácora de Implementación Operativa y Lanzamiento — Cora v1.0.0

Este directorio documenta la ejecución y certificación de los **5 pasos operativos** necesarios para el despliegue en la nube, aprovisionamiento de secretos, ingesta de la biblioteca clínica RAG, empaquetado móvil y preparación para tiendas de **Cora**.

---

## Tablero de Estado de los Pasos Operativos

| Paso | Alcance Operativo | Estado | Bitácora Detallada |
| :---: | :--- | :---: | :--- |
| **0** | **Plan Maestro y Gobernanza de Implementación** | ✅ Completado | [plan-despliegue-y-lanzamiento-produccion.md](./plan-despliegue-y-lanzamiento-produccion.md) |
| **1** | **Despliegue del Backend en la Nube y CI/CD CD** | ✅ Completado | [paso-01-despliegue-nube.md](./paso-01-despliegue-nube.md) |
| **2** | **Validación y Aprovisionamiento de Secretos Prod** | ✅ Completado | [paso-02-secretos-y-entorno.md](./paso-02-secretos-y-entorno.md) |
| **3** | **Ingesta Automatizada del Corpus RAG en Neon** | ✅ Completado | [paso-03-ingesta-corpus-rag.md](./paso-03-ingesta-corpus-rag.md) |
| **4** | **Andamiaje Nativo, Firma y Compilación Móvil** | ⏳ Pendiente | [paso-04-empaquetado-y-firma-movil.md](./paso-04-empaquetado-y-firma-movil.md) |
| **5** | **Preparación de Lanzamiento y Metadata de Tiendas** | ⏳ Pendiente | [paso-05-lanzamiento-tiendas.md](./paso-05-lanzamiento-tiendas.md) |

---

## Flujo de Trabajo y Estándares
1. Cada paso se ejecuta de forma modular con pruebas automatizadas (unitarias, integración o de humo).
2. Se mantiene el árbol de Git limpio, con commits atómicos descriptivos por paso.
3. Se verifica que los flujos de CI en GitHub Actions permanezcan al 100% en verde.
