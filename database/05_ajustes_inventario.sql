
-- PROYECTO SGE - SUSHI GREEN (Grupo FMC S.A.S.)
-- Curso 750006C Bases de Datos - Grupo 01
-- Universidad del Valle - Semestre 2026-1
--
-- Archivo: 05_ajustes_inventario.sql
--
-- OBJETIVO
--   Implementar el modulo de Gestion de Inventarios exigido en el
--   enunciado del proyecto:
--
--     1. Proveedor asociado a cada insumo (restriccion: no se puede
--        registrar un insumo sin un proveedor previo).
--     2. Demanda diaria de cada insumo.
--     3. Vista que calcule los DIAS DE STOCK y su categoria de estado.
--
--   Formula exigida:      Dias de Stock = Inventario actual / Demanda diaria
--
--
--   RESTRICCION CLAVE DEL ENUNCIADO:
--     "NO se debe almacenar el dato de dias de stock junto con
--      insumo/productos."
--   Por eso los dias de stock NO son una columna: son una VISTA que se
--   calcula en tiempo real cada vez que se consulta.
--


-- =====================================================================
-- 1. AGREGAR LAS COLUMNAS NUEVAS A INGREDIENTE
-- =====================================================================

ALTER TABLE public.ingrediente
    ADD COLUMN IF NOT EXISTS nit_proveedor   character varying(20),
    ADD COLUMN IF NOT EXISTS demanda_diaria  numeric(10,2);


-- =====================================================================
-- 2. PROVEEDOR ASOCIADO A CADA INSUMO
-- =====================================================================
-- El enunciado exige que cada insumo tenga un "Proveedor Asociado" y que
-- no se pueda registrar un insumo sin un proveedor previo.
--
-- NO se asigna al azar. El proveedor se DERIVA de los movimientos reales
-- que ya estan registrados en la base de datos, en tres pasos:
--   Paso A: quien ha surtido efectivamente ese ingrediente (ingreso_inventario)
--   Paso B: a quien se le ha comprado ese ingrediente (ordenes de compra)
--   Paso C: solo para los que no tienen ningun movimiento, se asigna el
--           proveedor cuyo tipo corresponde a la naturaleza del insumo.

-- ---------------------------------------------------------------------
-- PASO A: proveedor mas frecuente en los ingresos de mercancia.
-- La cadena es: ingreso_inventario -> inventario -> ingrediente
-- Cubre 142 de los 173 ingredientes.
-- ---------------------------------------------------------------------
UPDATE public.ingrediente i
   SET nit_proveedor = d.nit_proveedor
  FROM (
        SELECT DISTINCT ON (inv.id_ingrediente)
               inv.id_ingrediente,
               ii.nit_proveedor
          FROM public.ingreso_inventario ii
          JOIN public.inventario inv
            ON ii.id_inventario = inv.id_inventario
         GROUP BY inv.id_ingrediente, ii.nit_proveedor
         ORDER BY inv.id_ingrediente, COUNT(*) DESC
       ) d
 WHERE i.id_ingrediente = d.id_ingrediente
   AND i.nit_proveedor IS NULL;


-- ---------------------------------------------------------------------
-- PASO B: para los que aun no tienen proveedor, se busca en las ordenes
-- de compra ya realizadas (detalle_pedido_prov -> pedido_proveedor).
-- ---------------------------------------------------------------------
UPDATE public.ingrediente i
   SET nit_proveedor = d.nit_proveedor
  FROM (
        SELECT DISTINCT ON (dpp.id_ingrediente)
               dpp.id_ingrediente,
               pp.nit_proveedor
          FROM public.detalle_pedido_prov dpp
          JOIN public.pedido_proveedor pp
            ON dpp.id_pedido_prov = pp.id_pedido_prov
         GROUP BY dpp.id_ingrediente, pp.nit_proveedor
         ORDER BY dpp.id_ingrediente, COUNT(*) DESC
       ) d
 WHERE i.id_ingrediente = d.id_ingrediente
   AND i.nit_proveedor IS NULL;


-- ---------------------------------------------------------------------
-- PASO C: los ingredientes restantes nunca han tenido un ingreso ni una
-- orden de compra registrada, por lo que no hay historial del cual
-- derivar el proveedor. Se les asigna un proveedor ACTIVO cuyo tipo
-- corresponda a la naturaleza del insumo (el proveedor de pescados a los
-- ingredientes marinos, el de bebidas a los licores, etc.).
-- ---------------------------------------------------------------------
UPDATE public.ingrediente i
   SET nit_proveedor = (
        SELECT p.nit_proveedor
          FROM public.proveedor p
         WHERE p.estado_proveedor = 'Activo'
           AND p.tipo_proveedor = CASE
                WHEN i.nombre_ingrediente ~* 'salmon|atun|pescado|camaron|langostino|pulpo|calamar|marisco|anguila|tilapia|trucha'
                     THEN 'Pescado y Mariscos'
                WHEN i.nombre_ingrediente ~* 'cerdo|pollo|res|carne|lomo|tocineta|jamon|pato'
                     THEN 'Carnes y Aves'
                WHEN i.nombre_ingrediente ~* 'alga|nori|wakame|aguacate|pepino|zanahoria|cebolla|lechuga|tomate|champinon|espinaca|brocoli|choclo|vegetal'
                     THEN 'Vegetales y Algas'
                WHEN i.nombre_ingrediente ~* 'limon|naranja|mandarina|maracuya|mango|fresa|mora|frut|citric|pina'
                     THEN 'Frutas y Citricos'
                WHEN i.nombre_ingrediente ~* 'salsa|soya|teriyaki|ponzu|mayonesa|aderezo|vinagre|aceite|wasabi|jengibre|sriracha|terimayo|sal|azucar|especia'
                     THEN 'Salsas y Aderezos'
                WHEN i.nombre_ingrediente ~* 'arroz|harina|panko|semilla|ajonjoli|sesamo|fideo|pasta|grano|cereal'
                     THEN 'Granos y Cereales'
                WHEN i.nombre_ingrediente ~* 'tofu|edamame|soja'
                     THEN 'Proteina de Soya'
                WHEN i.nombre_ingrediente ~* 'cerveza|vino|sake|whisky|ron|tequila|vodka|gin|licor|gaseosa|jugo|agua|te |cafe|bebida|sangria'
                     THEN 'Bebidas'
                WHEN i.nombre_ingrediente ~* 'empaque|caja|bolsa|servilleta|palillo|contenedor'
                     THEN 'Empaques'
                ELSE 'Salsas y Aderezos'
           END
         ORDER BY p.calificacion DESC, p.nit_proveedor
         LIMIT 1
   )
 WHERE i.nit_proveedor IS NULL;

-- Red de seguridad: si algun insumo quedara sin proveedor, se le asigna
-- el proveedor activo mejor calificado. Ningun insumo puede quedar en
-- NULL, porque el enunciado lo prohibe explicitamente.
UPDATE public.ingrediente
   SET nit_proveedor = (
        SELECT nit_proveedor
          FROM public.proveedor
         WHERE estado_proveedor = 'Activo'
         ORDER BY calificacion DESC, nit_proveedor
         LIMIT 1
   )
 WHERE nit_proveedor IS NULL;


-- =====================================================================
-- 3. DEMANDA DIARIA DE CADA INSUMO
-- =====================================================================
-- La demanda diaria se DERIVA del consumo real registrado en la base de
-- datos, no se inventa. La cadena de calculo es:
--
--   detalle_pedido      -> cuantas unidades de cada plato se vendieron
--   producto_ingrediente-> cuanto de cada ingrediente lleva ese plato (receta)
--   ---------------------------------------------------------------
--   consumo_total(ingrediente) = SUM(unidades_vendidas * cantidad_receta)
--   demanda_diaria = consumo_total / dias_del_periodo
--
-- FACTOR DE OPERACION (ver bitacora de IA):
--   El conjunto de datos contiene 1.543 unidades vendidas en 363 dias y
--   8 sedes, lo que equivale a 0,53 platos por sede al dia: una cifra
--   irreal para un restaurante en operacion. Los 500 pedidos cargados son
--   una MUESTRA del historial, no la operacion completa del ano.
--   Por eso el consumo derivado se escala con un factor de 150, que lleva
--   la operacion a un nivel realista (~80 platos por sede al dia) sin
--   alterar las PROPORCIONES reales entre ingredientes: el atun sigue
--   consumiendose mas que el wasabi, exactamente en la misma relacion que
--   arrojan las recetas y las ventas.
--
-- PISO MINIMO:
--   19 ingredientes nunca aparecen en un plato vendido en la muestra, por
--   lo que su consumo derivado seria 0. Una demanda de cero haria imposible
--   dividir (division por cero). Se les asigna un piso de 0,50 unidades
--   diarias: estan en la carta, luego tienen rotacion, aunque sea baja.

UPDATE public.ingrediente i
   SET demanda_diaria = GREATEST(
        ROUND( COALESCE(c.consumo_total, 0) / 363.0 * 150.0, 2 ),
        0.50
   )
  FROM (
        SELECT pi.id_ingrediente,
               SUM(dp.cantidad_producto * pi.cantidad_utilizada) AS consumo_total
          FROM public.detalle_pedido dp
          JOIN public.producto_ingrediente pi
            ON dp.id_producto = pi.id_producto
         GROUP BY pi.id_ingrediente
       ) c
 WHERE i.id_ingrediente = c.id_ingrediente
   AND i.demanda_diaria IS NULL;

-- Ingredientes sin ninguna venta asociada: reciben el piso minimo.
UPDATE public.ingrediente
   SET demanda_diaria = 0.50
 WHERE demanda_diaria IS NULL;


-- =====================================================================
-- 4. CORRECCION DE COHERENCIA: INGREDIENTES NO DISPONIBLES
-- =====================================================================
-- INCONSISTENCIA DETECTADA:
--   9 ingredientes estan marcados con estado_ingrediente = 'no disponible'
--   pero tienen existencias en la tabla inventario. Ejemplo: el "Salmon
--   fresco" figura como no disponible y a la vez registra 953 unidades en
--   bodega. Un insumo no puede estar agotado y tener stock al mismo tiempo.
--
-- CORRECCION:
--   Se alinea el inventario con el estado del ingrediente: si el insumo
--   esta marcado como no disponible, sus existencias se ponen en cero.
--   De este modo la vista de dias de stock los reporta correctamente como
--   AGOTADO y genera su alerta de Pedido Inmediato.

UPDATE public.inventario inv
   SET cantidad_disponible = 0
  FROM public.ingrediente i
 WHERE inv.id_ingrediente = i.id_ingrediente
   AND i.estado_ingrediente = 'no disponible'
   AND inv.cantidad_disponible > 0;


-- =====================================================================
-- 5. RESTRICCIONES DE INTEGRIDAD
-- =====================================================================
-- Se aplican DESPUES de poblar, para que las 173 filas existentes ya
-- cumplan las reglas.

-- RESTRICCION DEL ENUNCIADO:
--   "NO se pueden registrar insumos o productos de proveedores que no
--    hayan sido registrados previamente en la aplicacion."
-- Esta llave foranea es lo que hace cumplir esa regla a nivel de motor:
-- PostgreSQL rechazara cualquier insumo cuyo nit_proveedor no exista.
ALTER TABLE public.ingrediente
    DROP CONSTRAINT IF EXISTS fk_ingrediente_proveedor;
ALTER TABLE public.ingrediente
    ADD CONSTRAINT fk_ingrediente_proveedor
    FOREIGN KEY (nit_proveedor)
    REFERENCES public.proveedor (nit_proveedor);

-- Ningun insumo puede quedar sin proveedor.
ALTER TABLE public.ingrediente
    ALTER COLUMN nit_proveedor SET NOT NULL;

-- La demanda diaria debe ser positiva: es el divisor de la formula de
-- dias de stock, y una demanda de cero provocaria una division por cero.
ALTER TABLE public.ingrediente
    DROP CONSTRAINT IF EXISTS ingrediente_demanda_check;
ALTER TABLE public.ingrediente
    ADD CONSTRAINT ingrediente_demanda_check
    CHECK (demanda_diaria > 0);

ALTER TABLE public.ingrediente
    ALTER COLUMN demanda_diaria SET NOT NULL;


-- =====================================================================
-- 6. VISTA: DIAS DE STOCK
-- =====================================================================
-- Esta es la pieza central del modulo de inventarios.
--
-- POR QUE UNA VISTA Y NO UNA COLUMNA:
--   El enunciado prohibe explicitamente almacenar los dias de stock.
--   Y con razon: es un dato DERIVADO. Si se guardara como columna,
--   quedaria obsoleto en el instante en que cambie el inventario o la
--   demanda, y habria que recalcularlo con triggers en cada movimiento.
--   Una VISTA no almacena nada: ejecuta el calculo en el momento en que
--   se consulta, por lo que el resultado SIEMPRE esta actualizado.
--
-- La vista consolida el stock de TODAS las sedes por ingrediente, que es
-- la vision que necesita el area de compras para decidir un pedido.

CREATE OR REPLACE VIEW public.v_dias_stock AS
SELECT
    i.id_ingrediente,
    i.nombre_ingrediente,
    i.unidad_medida,
    p.nombre_proveedor,
    p.tiempo_entrega_dias,

    -- Inventario actual: suma de las existencias en todas las sedes.
    COALESCE(SUM(inv.cantidad_disponible), 0)          AS inventario_actual,
    i.demanda_diaria,

    -- Dias de Stock = Inventario actual / Demanda diaria
    ROUND(
        COALESCE(SUM(inv.cantidad_disponible), 0) / i.demanda_diaria,
        1
    )                                                   AS dias_de_stock,

    -- Categoria de estado, segun la tabla del enunciado.
    CASE
        WHEN COALESCE(SUM(inv.cantidad_disponible), 0) = 0
             THEN 'AGOTADO'
        WHEN COALESCE(SUM(inv.cantidad_disponible), 0) / i.demanda_diaria < 5
             THEN 'CRITICO'
        WHEN COALESCE(SUM(inv.cantidad_disponible), 0) / i.demanda_diaria <= 15
             THEN 'ALERTA'
        ELSE 'SEGURO'
    END                                                 AS categoria_estado,

    -- Accion recomendada, segun la tabla del enunciado.
    CASE
        WHEN COALESCE(SUM(inv.cantidad_disponible), 0) = 0
             THEN 'Pedido Inmediato'
        WHEN COALESCE(SUM(inv.cantidad_disponible), 0) / i.demanda_diaria < 5
             THEN 'Pedido de Emergencia'
        WHEN COALESCE(SUM(inv.cantidad_disponible), 0) / i.demanda_diaria <= 15
             THEN 'Realizar Pedido Normal'
        ELSE 'Mantener Monitoreo'
    END                                                 AS accion_recomendada

FROM public.ingrediente i
JOIN public.proveedor p
    ON i.nit_proveedor = p.nit_proveedor
LEFT JOIN public.inventario inv
    ON i.id_ingrediente = inv.id_ingrediente
GROUP BY
    i.id_ingrediente, i.nombre_ingrediente, i.unidad_medida,
    i.demanda_diaria, p.nombre_proveedor, p.tiempo_entrega_dias;

-- Nota sobre el LEFT JOIN a inventario:
--   Se usa LEFT (y no INNER) a proposito. Un ingrediente que no tenga
--   ninguna fila en inventario debe aparecer igualmente en la vista, con
--   inventario_actual = 0 y categoria AGOTADO. Con un INNER JOIN ese
--   insumo desapareceria del reporte, que es justo lo contrario de lo que
--   necesita el area de compras: los agotados son los mas urgentes.


COMMENT ON VIEW public.v_dias_stock IS
'Calcula en tiempo real los dias de stock de cada insumo (inventario / demanda diaria) y su categoria de estado (AGOTADO, CRITICO, ALERTA, SEGURO). El dato NO se almacena, se deriva en cada consulta.';


-- =====================================================================
-- 7. VERIFICACION
-- =====================================================================

-- 7.1 Ningun ingrediente sin proveedor ni sin demanda (debe dar 173/173/173).
-- SELECT COUNT(*)               AS total,
--        COUNT(nit_proveedor)   AS con_proveedor,
--        COUNT(demanda_diaria)  AS con_demanda
--   FROM public.ingrediente;

-- 7.2 Distribucion de las 4 categorias.
--     Esperado aprox: AGOTADO 9 | CRITICO 9 | ALERTA 44 | SEGURO 111
-- SELECT categoria_estado, accion_recomendada, COUNT(*) AS ingredientes
--   FROM public.v_dias_stock
--  GROUP BY categoria_estado, accion_recomendada
--  ORDER BY CASE categoria_estado
--             WHEN 'AGOTADO' THEN 1 WHEN 'CRITICO' THEN 2
--             WHEN 'ALERTA'  THEN 3 ELSE 4 END;

-- 7.3 Insumos que exigen accion inmediata (lo que veria el area de compras).
-- SELECT nombre_ingrediente, nombre_proveedor, inventario_actual,
--        demanda_diaria, dias_de_stock, categoria_estado, accion_recomendada
--   FROM public.v_dias_stock
--  WHERE categoria_estado IN ('AGOTADO', 'CRITICO')
--  ORDER BY dias_de_stock;

-- 7.4 Prueba de que la vista es DINAMICA y no almacena nada:
--     al cambiar el inventario, los dias de stock cambian solos.
-- SELECT nombre_ingrediente, inventario_actual, dias_de_stock, categoria_estado
--   FROM public.v_dias_stock WHERE id_ingrediente = 'ING_001';
--
-- UPDATE public.inventario SET cantidad_disponible = 1
--  WHERE id_ingrediente = 'ING_001';
--
-- SELECT nombre_ingrediente, inventario_actual, dias_de_stock, categoria_estado
--   FROM public.v_dias_stock WHERE id_ingrediente = 'ING_001';
--   --> la categoria cambia sin haber tocado la vista.
