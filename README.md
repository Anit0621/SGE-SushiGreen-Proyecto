# Proyecto Final: Sistema de Gestión Empresarial (SGE) — Sushi Green

**Asignatura:** 750006C Bases de Datos — Grupo 01
**Institución:** Universidad del Valle — Escuela de Ingeniería de Sistemas y Computación
**Docente:** Susana Medina Gordillo
**Semestre:** 2026-1

---

## 🏢 Información de la Empresa Seleccionada

- **Nombre de la Empresa:** Sushi Green (Grupo FMC S.A.S.)
- **Sector Económico:** Servicios — Alimentos y Bebidas (restaurantes)
- **Descripción breve:** Sushi Green es una cadena colombiana de restaurantes especializada
  en cocina japonesa (sushi, rolls, entradas calientes), cócteles y bebidas, con presencia en
  varias sedes. Su operación diaria involucra la gestión de un menú de productos preparados a
  partir de ingredientes perecederos, control de inventario por sede, atención en mesa,
  reservas, pedidos a domicilio a través de plataformas externas, facturación electrónica con
  IVA y compras recurrentes a proveedores de insumos.
- **Sitio web oficial:** _(pendiente de enlazar)_
- **Redes sociales:** _(pendiente de enlazar)_

---

## 👥 Integrantes del Grupo

1. Juancamilo González Bernal — 202440237-3743
2. Dilan Mosquera Zapata — 2242349-3743
3. Juan David Guar Valencia — 2341909-3743
4. Valentina Montezuma González — 202242058-3743

---

## 🛠️ Stack Tecnológico

- **Lenguaje:** Python 3.10+
- **Framework Web:** Flask _(en desarrollo)_
- **Base de Datos:** PostgreSQL 16 (local para desarrollo)
- **Conector:** psycopg2
- **Administración de BD:** pgAdmin 4

---

## 📐 Diseño de la Base de Datos

La base de datos `sushi_green` está implementada en PostgreSQL, normalizada hasta **Tercera
Forma Normal (3FN)**, y consta de **22 tablas** con sus llaves primarias, llaves foráneas y
restricciones de integridad.

### Diagrama Entidad-Relación (MER)

_(Pendiente: se subirá a `docs/` y se referenciará aquí)_

### Diccionario de Datos Resumido

| Módulo | Tablas | Descripción |
|---|---|---|
| **Terceros** | `cliente`, `proveedor` | Datos de clientes (tipo de documento, Habeas Data) y proveedores (RUT, condiciones de pago, calificación, tiempo de entrega). |
| **Organización** | `sede`, `empleado`, `cargo`, `turno`, `mesa` | Estructura operativa del restaurante y su personal. |
| **Catálogo e Inventario** | `producto`, `categoria`, `ingrediente`, `producto_ingrediente`, `inventario`, `ingreso_inventario` | Menú, recetas (relación producto–ingrediente) y control de stock por sede. |
| **Ventas** | `pedido`, `detalle_pedido`, `reserva`, `plataforma_domicilio` | Pedidos en mesa y a domicilio, reservas de mesa. |
| **Facturación** | `factura`, `pago`, `metodo_pago` | Registro de ventas con cálculo de IVA según legislación colombiana. |
| **Compras** | `pedido_proveedor`, `detalle_pedido_prov` | Órdenes de pedido a proveedores para reabastecimiento. |

### Reglas de negocio implementadas en la BD

- **Trigger PL/pgSQL** de validación de capacidad de mesas: impide registrar una reserva cuyo
  número de comensales exceda la capacidad de la mesa asignada.
- **Integridad referencial** en todas las relaciones (no se pueden registrar órdenes de pedido
  ni ingredientes sin un proveedor previamente registrado).

---

## 📂 Estructura del Repositorio

```
/
├── database/     # Scripts SQL (esquema, datos, consultas, vistas, triggers)
├── docs/         # Diagramas, informes de avance y bitácora de IA
├── app/          # Código fuente de la aplicación web (en desarrollo)
├── .gitignore
└── README.md
```

---

## 🚀 Guía de Instalación y Ejecución

### 1. Clonar el repositorio

```bash
git clone https://github.com/<usuario>/SGE-SushiGreen-Proyecto.git
cd SGE-SushiGreen-Proyecto
```

### 2. Crear y cargar la base de datos

1. Crear una base de datos en PostgreSQL llamada `sushi_green`.
2. Ejecutar, desde pgAdmin o desde la terminal, el script del esquema y los datos:

```bash
psql -U postgres -d sushi_green -f database/01_schema_datos.sql
```

Este archivo contiene el DDL completo (22 tablas, PKs, FKs, constraints) junto con los datos
de prueba ya cargados.

### 3. Ejecutar la aplicación web

Para realizar la ejecución de la app hay que realizar los siguientes pasos: 
1. Crear una carpeta nueva en algún lugar del equipo, e inicializar un repositorio git en ella. Esto se realiza abriendo el Git bash en esa ubicación e ingresando 
```bash
git init
```
2. luego, hay que vincular el repositorio con este repositorio remoto; para esta acción hay que usar el siguiente comando:
```bash
git remote add origin https://github.com/Anit0621/SGE-SushiGreen-Proyecto.git
```
3. Posteriormente hay que traer todo lo contenido en el repositorio; para esto se usa el comando:
```bash
git pull origin
```
4. Finalmente, hay que especificar la rama a utilizar; para correr la app en modo despliegue se utiliza la rama main:
```bash
git checkout main
```
RECOMENDACIONES: 
En caso de errores con el compilador de Python, se recomienda realizar la configuración para establecer un nuevo interpretador; esta opción en PyCharm se encuentra en la parte inferior derecha del programa;
Hay que añadir un nuevo interpretador local y crear uno nuevo utilizando el archivo ubicado en la carpeta raíz de Python en el equipo; esto crea un nuevo entorno virtual. Posterior a esto hay que hacer: 
```bash
pip install -r requirements.txt
```
Para realizar la instalación de las dependencias/librerias adicionales utilizadas para este proyecto y contempladas en requirements.txt.
Para correr la app web hay que correr el archivo `run.py`

## 🤖 Uso de Inteligencia Artificial

El proceso de apoyo con LLMs (prompts utilizados, resultados obtenidos y ajustes manuales
realizados por el grupo) está documentado en `docs/Bitacora_IA.pdf`.

---

## 📄 Estado de Avance

- [x] Avance 1 — Modelo Entidad-Relación
- [x] Avance 2 — Esquema relacional
- [x] Avance 3 — Normalización 3FN, implementación en PostgreSQL, carga de datos y 10 consultas de validación
- [ ] Entrega Final — 20 consultas SQL, MER en notación UML, vista de días de stock, aplicación web con CRUD y despliegue
