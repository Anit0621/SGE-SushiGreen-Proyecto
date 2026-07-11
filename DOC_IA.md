# 📓 Bitácora de Uso de IA — Proyecto SGE

**Empresa:** Sushi Green — Grupo FMC S.A.S.
**Curso:** 750006C Bases de Datos — Grupo 01 — Universidad del Valle
**Docente:** Susana Medina Gordillo — Semestre 2026-1
**Fecha de inicio:** 29/06/2026

**Integrantes:**
- Juancamilo González Bernal (202440237-3743)
- Dilan Mosquera Zapata (2242349-3743)
- Juan David Guar Valencia (2341909-3743)
- Valentina Montezuma González (202242058-3743)

> Las capturas de pantalla de los prompts correspondientes a las entradas 1 a 8 se encuentran en `docs/Bitacora_IA.pdf`.

---

## 1. Fase de Diseño: Generación de datos sintéticos para poblar tablas

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Necesito tu ayuda para el diseño de una base de datos. Necesito que me proveas datos sintéticos para llenar una tabla para una empresa de un restaurante de Sushi. *(Columnas de la tabla empleado y valores para las llaves foráneas)* Puedes dármelos en formato CSV para que sean introducidos a la base de datos; columna1, columna2, columnaN / dato11, dato12, dato1N / dato21, dato22, dato2N. Ese sería el formato para los CSV; que los datos contengan variabilidad y sesgos intencionales."
- **Resultado de la IA:** Generó 54 registros de empleados, con todos los campos completos y sin valores nulos.
- **Ajuste manual / Validación:** Revisamos que los datos cumplieran las restricciones de la tabla (tipos, longitudes y llaves foráneas válidas). No fue necesario corregir nada.

> **Nota:** este prompt fue la plantilla base que reutilizamos para varias tablas. A partir de las tablas ya cargadas, subíamos los CSV existentes para que la IA generara los datos de las tablas dependientes respetando las llaves foráneas.

---

## 2. Fase de Diseño: Tabla `ingrediente` a partir del menú real

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Actúa como un generador de datos. Necesito un archivo CSV con las filas necesarias simuladas para mi tabla ingredientes. Como aporte te daré los ingredientes en el archivo `ingredientes.txt` y tú generarás los datos para las otras columnas. Las columnas son: `id_ingrediente VARCHAR(20) PRIMARY KEY, nombre_ingrediente VARCHAR(50) NOT NULL UNIQUE, unidad_medida VARCHAR(20) NOT NULL, stock_minimo DECIMAL(10,2) NOT NULL CHECK (stock_minimo >= 0), estado_ingrediente VARCHAR(20)`; para `estado_ingrediente` hay dos posibilidades (disponible / no disponible). Quiero que las palabras no tengan caracteres fuera del inglés, es decir, sin tildes."
- **Resultado de la IA:** Generó 173 ingredientes con IDs secuenciales (`ING_001`…), sin tildes ni eñes, con unidades de medida coherentes según el insumo (Kg para carnes, Litros para licores, Gramos para especias, Unidades para huevos) y respetando el `CHECK (stock_minimo >= 0)`.
- **Ajuste manual / Validación:** Para que los ingredientes fueran reales y no inventados, construimos manualmente un archivo `ingredientes.txt` con la información publicada en el menú oficial de Sushi Green (página web y redes sociales) y se lo entregamos a la IA como insumo del prompt.

---

## 3. Fase de Diseño: Tabla `proveedor`

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Ahora este mismo ejercicio para una tabla de proveedor; no tiene llaves foráneas. *(Columnas y restricciones de la tabla proveedor)*"
- **Resultado de la IA:** Generó 30 registros de proveedores, sin campos nulos.
- **Ajuste manual / Validación:** Al revisar los datos encontramos que un proveedor traía el valor `N/A` en la columna `estado_proveedor`, lo cual no es un valor válido según nuestro diseño. Lo corregimos manualmente reemplazándolo por `Activo`.

---

## 4. Fase de Diseño: Tabla `reserva`

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Ahora vamos a generar datos para una tabla de reserva; *(Columnas de la tabla reserva y valores para las llaves foráneas)*. Acá hay unos cuantos valores para `cedula_cliente`; no tienes que usar todos; las `id_mesa` van de MES001 a MES088. Dame 20 valores para reservas; sesgos intencionales, variabilidad, en CSV."
- **Resultado de la IA:** Generó 20 registros de reservas, sin campos nulos.
- **Ajuste manual / Validación:**  La IA ignoró la capacidad de las mesas: generó reservas con más comensales de los que la mesa asignada podía acomodar. Corregimos manualmente la `cantidad_personas` de cada reserva para que respetara la capacidad real de su mesa, y redujimos el conjunto de 20 a **15 registros** válidos. Este error fue el que nos llevó a implementar el trigger de validación (ver entrada 8).

---

## 5. Fase de Diseño: Tabla `pedido_proveedor`

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Necesito que me ayudes a generar datos sintéticos para una base de datos. La tabla se llama `pedido_proveedor`; *(Columnas y restricciones)*. *(Valores para la llave foránea nit_proveedor)*. Que sean en CSV, sesgos intencionales y variabilidad; no hagas demasiados."
- **Resultado de la IA:** Generó 40 registros de pedidos a proveedores, sin valores nulos.
- **Ajuste manual / Validación:** Redujimos el conjunto a 15 pedidos para evitar inserciones demasiado grandes. Además corregimos los valores de `total_pedido`: la IA generó cifras arbitrarias que no correspondían a la suma de los detalles de cada pedido. Los recalculamos manualmente para que `pedido_proveedor.total_pedido` coincidiera con la suma de sus líneas en `detalle_pedido_prov`.

---

## 6. Fase de Diseño: Tabla `detalle_pedido_prov`

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Entonces ahora tenemos la tabla llamada `detalle_pedido_proveedor`; *(Columnas y restricciones)*. *(Valores para la llave foránea id_ingrediente)*. *(Valores para la llave foránea id_pedido_prov)*. Con sesgos intencionales y variabilidad; es un restaurante de sushi, por cierto."
- **Resultado de la IA:** Generó 58 registros. Cada detalle se asocia a un pedido específico, con un número variable de ítems por pedido.
- **Ajuste manual / Validación:** Verificamos que cada detalle apuntara a un pedido existente y que los ingredientes solicitados fueran coherentes con un restaurante de sushi. Con estos datos recalculamos los totales de `pedido_proveedor` (ver entrada 5).

---

## 7. Fase de Diseño: Tabla `pago`

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Ahora el último, la tabla se llama `pago`; *(Columnas y restricciones)*. *(Valores para la llave foránea metodo_pago)*. *(Valores para la llave foránea id_factura)*. Un pago va asociado a 1 sola factura, pero una factura puede tener varios pagos; sesgos intencionales y variabilidad, en CSV; genera un archivo CSV."
- **Resultado de la IA:** Generó 357 registros de pagos, cada uno asociado a una factura.
- **Ajuste manual / Validación:** ⚠️ Detectamos que no todas las facturas quedaban cubiertas por un pago, lo cual es imposible: toda factura emitida debe tener al menos un pago asociado. Le pedimos a la IA que corrigiera garantizando mínimo un pago por factura. Tras la corrección se obtuvieron 637 registros, y verificamos que la suma de los pagos coincide exactamente con el total de cada factura.

---

## 8. Fase de Desarrollo: Trigger de validación de capacidad de mesas (PL/pgSQL)

- **Herramienta utilizada:** Gemini 1.5 Pro
- **Prompt:**
  > "Cada mesa tiene una capacidad; estoy pensando que un trigger funcionaría para revisar esta condición, pero entonces ¿qué haría ese trigger? Si quieres puedes darme la sintaxis, pero me interesa ver cómo eso funcionaría en la estructura general de la BD; se me ocurre no permitir añadir, pero ¿qué más hay?"
- **Resultado de la IA:** Explicó el funcionamiento del trigger y entregó la función y el trigger, que se dispara `BEFORE INSERT OR UPDATE` sobre la tabla `reserva`.
- **Ajuste manual / Validación:** Definimos que debía ser un TRIGGER y no un CHECK, porque un `CHECK` solo puede evaluar columnas de su propia fila, y aquí es necesario comparar `reserva.cantidad_personas` contra `mesa.capacidad`, que está en otra tabla. Lo probamos con dos `INSERT`: uno dentro de la capacidad (aceptado) y uno que la excedía (rechazado con el mensaje de error esperado).

---

## 9. Fase de Ajuste de Esquema: Datos de Clientes

- **Herramienta utilizada:** Claude (Anthropic)
- **Prompt:**
  > "La tabla cliente solo tiene cédula, nombre, apellido y teléfono, pero el enunciado exige tipo de documento, Habeas Data, ciudad, direcciones, email, representante legal y régimen tributario. Ya hay 100 clientes cargados. Genera los ALTER TABLE y puebla los registros existentes sin dañar los datos."
- **Resultado de la IA:** Generó 8 columnas nuevas (`tipo_documento`, `habeas_data`, `ciudad`, `direccion_residencia`, `direccion_operativa`, `email`, `representante_legal`, `regimen_tributario`), los `UPDATE` para poblar los 100 clientes existentes y las restricciones `CHECK`.
- **Ajuste manual / Validación:**
  - Verificamos que las restricciones `CHECK` y `NOT NULL` se aplicaran después de poblar los datos. Si se aplicaran antes, PostgreSQL rechazaría las 100 filas existentes por contener `NULL`.
  - Definimos `habeas_data` con `DEFAULT FALSE`, para que todo cliente nuevo registrado desde la aplicación web tenga que **autorizar explícitamente** el tratamiento de sus datos (Ley 1581 de 2012).
  - Comprobamos con un `SELECT COUNT(*)` que los 100 clientes quedaran completos y sin ningún `NULL`.
- **Evidencia:** `database/03_ajustes_cliente.sql`

---

## 10. Fase de Ajuste de Esquema: Datos de Proveedores

- **Herramienta utilizada:** Claude (Anthropic)
- **Prompt:**
  > "La tabla proveedor solo tiene NIT, nombre, teléfono, dirección, correo y tipo. El enunciado exige además RUT, certificación bancaria, tiempo de entrega, contactos comercial/cartera/logístico, condiciones de pago y calificación 1-5. Hay 30 proveedores cargados. Genera los ALTER y puebla los existentes derivando los datos de la BD donde sea posible."
- **Resultado de la IA:** Generó 15 columnas nuevas, los `UPDATE` de relleno y las restricciones `CHECK` (calificación entre 1 y 5, tiempo de entrega positivo, tipo de cuenta válido).
- **Ajuste manual / Validación:**
  - **RUT:** verificamos en la fuente oficial de la DIAN que, para una persona jurídica, el número del RUT coincide con el NIT. Por eso no se inventó un número nuevo: se copió el NIT que ya existía.
  - **Calificación:** revisamos los datos y encontramos que solo 6 de los 30 proveedores tienen órdenes registradas en `pedido_proveedor`. Para esos 6, la calificación se calcula a partir de su cumplimiento real (entregas y cancelaciones). Para los 24 restantes no simulamos un historial que no existe: se les asigna una calificación base documentada en el script, que se irá ajustando cuando la aplicación registre órdenes reales.
  - **Tiempo de entrega:** no lo dejamos al azar. Lo definimos según la naturaleza del insumo: el pescado fresco y la cadena de frío se despachan en 1 día, mientras que los empaques y los granos, al no ser perecederos, se piden con 8 a 10 días de anticipación.
- **Evidencia:** `database/04_ajustes_proveedor.sql`

---

## 11. Fase de Ajuste de Esquema: Módulo de Gestión de Inventarios

- **Herramienta utilizada:** Claude (Anthropic)
- **Prompt:**
  > "La tabla ingrediente no tiene demanda_diaria ni proveedor asociado, y no existe la vista de días de stock. Deriva la demanda del consumo real (detalle_pedido × producto_ingrediente) y crea la vista con las 4 categorías del enunciado (AGOTADO, CRÍTICO, ALERTA, SEGURO)."
- **Resultado de la IA:** Generó las columnas `nit_proveedor` y `demanda_diaria` en `ingrediente`, la llave foránea hacia `proveedor`, los `UPDATE` que derivan los valores del historial ya registrado, y la vista `v_dias_stock`.
- **Ajuste manual / Validación:**
  - **Rechazamos almacenar los días de stock como columna**, siguiendo la restricción explícita del enunciado. Es un dato derivado: si se guardara, quedaría desactualizado apenas cambie el inventario. Por eso se calcula en una VISTA, que lo recalcula en cada consulta.
  - **Inconsistencia detectada en los datos:** encontramos 9 ingredientes marcados como `no disponible` que sin embargo tenían existencias en la tabla `inventario` (el Salmón fresco figuraba como agotado y a la vez con 953 unidades en bodega). Un insumo no puede estar agotado y tener stock al mismo tiempo. Corregimos poniendo sus existencias en cero, con lo cual la vista ahora los reporta correctamente como AGOTADO.
  - **La demanda diaria inicial era irreal:** al derivarla literalmente de los datos, el consumo daba 0,53 platos por sede al día, y en consecuencia los 173 ingredientes quedaban en la categoría `SEGURO`, dejando la vista sin utilidad. Concluimos que los 500 pedidos cargados son una **muestra** del historial y no la operación anual completa, por lo que escalamos el consumo a un nivel realista (~80 platos por sede al día), conservando las proporciones reales entre ingredientes: el atún sigue consumiéndose más que el wasabi, en la misma relación que arrojan las recetas y las ventas.
- **Evidencia:** `database/05_ajustes_inventario.sql`

---

## 12. Fase de Ajuste de Esquema: Facturación (IVA) y Órdenes de Pedido

- **Herramienta utilizada:** Claude (Anthropic)
- **Prompt:**
  > "Los productos no tienen tarifa de IVA y las órdenes de pedido no tienen número de orden ni lugar de entrega. Implementa el cálculo de impuestos según la legislación colombiana y completa el módulo de compras con sus restricciones."
- **Resultado de la IA:** Generó las columnas `tarifa_impuesto` y `tipo_impuesto` en `producto`, el recálculo de los impuestos de los pedidos y facturas históricos, los campos `numero_orden` y `lugar_entrega` en `pedido_proveedor`, y el `CHECK` de cantidad mínima 1.
- **Ajuste manual / Validación:**
  - **Corregimos la tarifa tributaria.** La propuesta inicial aplicaba IVA del 19% a todo el menú. Lo rechazamos: en Colombia el servicio de restaurante no está gravado con IVA sino con el Impuesto Nacional al Consumo (Impoconsumo) del 8% (Art. 512-1 del Estatuto Tributario). Únicamente las bebidas alcohólicas y las gaseosas llevan IVA general del 19%. Por eso la tarifa se asigna según la categoría del producto y no de forma uniforme.
  - **Inconsistencia detectada en los datos:** 178 de las 500 facturas tenían impuestos en cero. Los datos sintéticos habían aplicado el impuesto de forma arbitraria, lo cual es contablemente imposible. Antes de corregir, verificamos que en las 500 facturas el `subtotal` coincidiera con la suma de sus líneas de detalle, lo que nos permitió recalcular el impuesto de forma exacta.
  - Al recalcular el impuesto cambia el total de la factura, así que propagamos el cambio en cascada (`pedido → factura → pago`) reajustando los pagos proporcionalmente. De lo contrario, los 637 pagos habrían dejado de cuadrar con el total de sus facturas. Verificamos con un `SELECT` que la suma de los pagos volviera a coincidir exactamente con cada total.
- **Evidencia:** `database/06_ajustes_facturacion.sql`

---

## 📌 Recordatorios

1. **Honestidad técnica:** no se penaliza el uso de IA; se penaliza la falta de documentación o la falta de comprensión de lo que la IA generó.
2. **Ubicación:** este archivo se guarda como `DOC_IA.md` en la raíz del repositorio de GitHub.
3. **Sustentación:** durante la muestra final, la docente podrá preguntar sobre **cualquier ajuste manual** registrado en esta bitácora.
