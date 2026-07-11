
-- PROYECTO SGE - SUSHI GREEN (Grupo FMC S.A.S.)
-- Curso 750006C Bases de Datos - Grupo 01
-- Universidad del Valle - Semestre 2026-1
--
-- Archivo: 06_ajustes_facturacion.sql
--
-- OBJETIVO
--   1. Modulo de Ventas (Facturacion): implementar el calculo de
--      impuestos segun la legislacion tributaria colombiana.
--   2. Modulo de Compras (Ordenes de Pedido): completar los campos
--      exigidos y las restricciones de cantidad.
--
-- USO: ejecutar DESPUES de 05_ajustes_inventario.sql



-- PARTE 1 - MODULO DE VENTAS (FACTURACION)

-- =====================================================================
-- 1.1 TARIFA DE IMPUESTO POR PRODUCTO
-- =====================================================================
-- El sistema debe soportar las tarifas descritas en el enunciado:
--   General (19%), Diferencial (5%), Exentos (0%) y Excluidos.
-- Se agrega ademas la tarifa de Impoconsumo (8%), por la razon que se
-- explica en el punto 1.2.

ALTER TABLE public.producto
    ADD COLUMN IF NOT EXISTS tarifa_impuesto numeric(4,2),
    ADD COLUMN IF NOT EXISTS tipo_impuesto   character varying(25);


-- =====================================================================
-- 1.2 ASIGNACION DE TARIFAS SEGUN LA LEY COLOMBIANA
-- =====================================================================
-- FUNDAMENTO TRIBUTARIO:
--
--   Sushi Green es un restaurante. En Colombia, el servicio de
--   restaurante NO esta gravado con IVA sino con el Impuesto Nacional
--   al Consumo (Impoconsumo), a una tarifa del 8% (Art. 512-1 del
--   Estatuto Tributario). Aplicarle IVA del 19% a un plato de sushi
--   seria tributariamente incorrecto.
--
--   Las bebidas alcoholicas y las gaseosas, en cambio, SI estan gravadas
--   con IVA a la tarifa general del 19%.
--
--   Por eso la tarifa no es la misma para todo el menu: depende de la
--   categoria del producto.
--
--   El sistema queda preparado igualmente para las tarifas del 5%, 0% y
--   Excluido (ver la restriccion CHECK del punto 1.5), de modo que si el
--   restaurante llegara a vender productos de canasta basica o exentos,
--   la aplicacion los soporta sin cambiar el esquema.

UPDATE public.producto p
   SET tarifa_impuesto = CASE c.nombre_categoria
            WHEN 'Bebidas y Licores'   THEN 19.00  -- IVA general
            WHEN 'Happy Hour Cocteles' THEN 19.00  -- IVA general (alcohol)
            ELSE                             8.00  -- Impoconsumo (comida)
       END,
       tipo_impuesto = CASE c.nombre_categoria
            WHEN 'Bebidas y Licores'   THEN 'IVA General'
            WHEN 'Happy Hour Cocteles' THEN 'IVA General'
            ELSE                             'Impoconsumo'
       END
  FROM public.categoria c
 WHERE p.id_categoria = c.id_categoria
   AND p.tarifa_impuesto IS NULL;


-- =====================================================================
-- 1.3 RECALCULO DE LOS IMPUESTOS EN LOS PEDIDOS HISTORICOS
-- =====================================================================
-- INCONSISTENCIA DETECTADA:
--   178 de las 500 facturas tenian impuestos = 0. Los datos sinteticos
--   aplicaron el impuesto de forma arbitraria: unas facturas lo cobraban
--   y otras no, sin ninguna regla. Eso es contable y tributariamente
--   imposible.
--
-- CORRECCION:
--   Se recalcula el impuesto de cada pedido a partir de sus lineas de
--   detalle, aplicando a cada producto la tarifa que legalmente le
--   corresponde. La verificacion previa confirmo que en las 500 facturas
--   el subtotal SI coincide con la suma de sus lineas de detalle, por lo
--   que el recalculo es exacto y no rompe la contabilidad.

UPDATE public.pedido pe
   SET impuestos = t.impuesto_calculado,
       total     = pe.subtotal + t.impuesto_calculado + pe.propina
  FROM (
        SELECT dp.id_pedido,
               ROUND(SUM(dp.subtotal * pr.tarifa_impuesto / 100.0), 2)
                   AS impuesto_calculado
          FROM public.detalle_pedido dp
          JOIN public.producto pr
            ON dp.id_producto = pr.id_producto
         GROUP BY dp.id_pedido
       ) t
 WHERE pe.id_pedido = t.id_pedido;


-- =====================================================================
-- 1.4 PROPAGACION A FACTURAS Y PAGOS
-- =====================================================================
-- Al cambiar el impuesto cambia el total de la factura. Para que la base
-- de datos siga siendo consistente hay que propagar el cambio en cascada:
--
--   pedido -> factura -> pago
--
-- Si solo se actualizara la factura, los pagos dejarian de cuadrar con
-- ella (hoy los 637 pagos suman exactamente el total de las 500 facturas).

-- 1.4.1 La factura hereda los impuestos y el total de su pedido.
UPDATE public.factura f
   SET impuestos = pe.impuestos,
       total     = f.subtotal + pe.impuestos + f.propina
  FROM public.pedido pe
 WHERE pe.id_factura = f.id_factura;

-- 1.4.2 Los pagos se reajustan proporcionalmente al nuevo total.
--   Una factura puede tener varios pagos (pago parcial). Se conserva la
--   proporcion que representaba cada pago sobre el total anterior, de modo
--   que la suma de los pagos vuelva a coincidir exactamente con el total.
WITH totales_previos AS (
    SELECT id_factura, SUM(valor_pago) AS suma_pagos
      FROM public.pago
     GROUP BY id_factura
)
UPDATE public.pago pg
   SET valor_pago = ROUND(
            pg.valor_pago * (f.total / NULLIF(tp.suma_pagos, 0)), 2
       )
  FROM public.factura f
  JOIN totales_previos tp ON tp.id_factura = f.id_factura
 WHERE pg.id_factura = f.id_factura
   AND tp.suma_pagos > 0;


-- =====================================================================
-- 1.5 RESTRICCIONES DE INTEGRIDAD (VENTAS)
-- =====================================================================

-- El sistema solo admite las tarifas legales en Colombia:
--   19% IVA general | 8% Impoconsumo | 5% IVA diferencial
--    0% exento      | NULL/0 excluido (no causa el impuesto)
ALTER TABLE public.producto
    DROP CONSTRAINT IF EXISTS producto_tarifa_impuesto_check;
ALTER TABLE public.producto
    ADD CONSTRAINT producto_tarifa_impuesto_check
    CHECK (tarifa_impuesto IN (0.00, 5.00, 8.00, 19.00));

ALTER TABLE public.producto
    DROP CONSTRAINT IF EXISTS producto_tipo_impuesto_check;
ALTER TABLE public.producto
    ADD CONSTRAINT producto_tipo_impuesto_check
    CHECK (tipo_impuesto IN ('IVA General', 'Impoconsumo',
                             'IVA Diferencial', 'Exento', 'Excluido'));

ALTER TABLE public.producto ALTER COLUMN tarifa_impuesto SET NOT NULL;
ALTER TABLE public.producto ALTER COLUMN tipo_impuesto   SET NOT NULL;

-- Ningun valor monetario puede ser negativo.
ALTER TABLE public.pedido
    DROP CONSTRAINT IF EXISTS pedido_impuestos_check;
ALTER TABLE public.pedido
    ADD CONSTRAINT pedido_impuestos_check
    CHECK (impuestos >= 0 AND propina >= 0 AND total >= 0);


-- #####################################################################
-- PARTE 2 - MODULO DE COMPRAS (ORDENES DE PEDIDO)
-- #####################################################################

-- =====================================================================
-- 2.1 CAMPOS EXIGIDOS EN LA ORDEN DE PEDIDO
-- =====================================================================
-- El enunciado exige, ademas de lo que ya existe:
--   - Numero de Orden: un consecutivo que aumenta con cada pedido.
--   - Lugar de entrega: la bodega o sede especifica donde se recibe.

ALTER TABLE public.pedido_proveedor
    ADD COLUMN IF NOT EXISTS numero_orden   integer,
    ADD COLUMN IF NOT EXISTS lugar_entrega  character varying(100);


-- 2.2 Numero de orden consecutivo (1, 2, 3, ...)
-- Se asigna siguiendo el orden cronologico real de los pedidos.
WITH numerados AS (
    SELECT id_pedido_prov,
           ROW_NUMBER() OVER (ORDER BY fecha_pedido, id_pedido_prov)
               AS consecutivo
      FROM public.pedido_proveedor
)
UPDATE public.pedido_proveedor pp
   SET numero_orden = n.consecutivo
  FROM numerados n
 WHERE pp.id_pedido_prov = n.id_pedido_prov
   AND pp.numero_orden IS NULL;

-- La secuencia continua desde el ultimo numero usado, para que las
-- ordenes creadas desde la aplicacion web sigan el consecutivo.
CREATE SEQUENCE IF NOT EXISTS public.seq_numero_orden;
SELECT setval('public.seq_numero_orden',
              COALESCE((SELECT MAX(numero_orden) FROM public.pedido_proveedor), 0) + 1,
              false);

ALTER TABLE public.pedido_proveedor
    ALTER COLUMN numero_orden SET DEFAULT nextval('public.seq_numero_orden');


-- 2.3 Lugar de entrega
-- Sushi Green recibe los insumos en la bodega de cada sede. Se asigna la
-- bodega de la sede principal, dejando el campo editable desde la
-- aplicacion para las ordenes que se despachen a otra sede.
UPDATE public.pedido_proveedor
   SET lugar_entrega = 'Bodega Central - Sede Unicentro, Cali'
 WHERE lugar_entrega IS NULL;


-- =====================================================================
-- 2.4 RESTRICCIONES DE INTEGRIDAD (COMPRAS)
-- =====================================================================

-- RESTRICCION DEL ENUNCIADO:
--   "Se debe verificar que la cantidad sea minimo 1. El limite maximo
--    debe estar definido acorde a las necesidades de la empresa."
--
-- Se fija un tope de 500 unidades por linea: Sushi Green maneja insumos
-- perecederos (pescado fresco, vegetales), por lo que pedir mas de 500
-- unidades de un mismo insumo generaria desperdicio antes de venderlo.
ALTER TABLE public.detalle_pedido_prov
    DROP CONSTRAINT IF EXISTS detalle_prov_cantidad_check;
ALTER TABLE public.detalle_pedido_prov
    ADD CONSTRAINT detalle_prov_cantidad_check
    CHECK (cantidad_solicitada >= 1 AND cantidad_solicitada <= 500);

-- El precio de compra no puede ser negativo.
ALTER TABLE public.detalle_pedido_prov
    DROP CONSTRAINT IF EXISTS detalle_prov_precio_check;
ALTER TABLE public.detalle_pedido_prov
    ADD CONSTRAINT detalle_prov_precio_check
    CHECK (precio_compra >= 0);

-- El numero de orden debe ser unico: es el identificador del documento.
ALTER TABLE public.pedido_proveedor
    DROP CONSTRAINT IF EXISTS pedido_proveedor_numero_orden_key;
ALTER TABLE public.pedido_proveedor
    ADD CONSTRAINT pedido_proveedor_numero_orden_key UNIQUE (numero_orden);

ALTER TABLE public.pedido_proveedor
    ALTER COLUMN numero_orden  SET NOT NULL;
ALTER TABLE public.pedido_proveedor
    ALTER COLUMN lugar_entrega SET NOT NULL;

-- RESTRICCION DEL ENUNCIADO:
--   "El estado inicia siempre con estado Pendiente."
ALTER TABLE public.pedido_proveedor
    ALTER COLUMN estado SET DEFAULT 'pendiente';


-- =====================================================================
-- 3. VERIFICACION
-- =====================================================================

-- 3.1 Todos los productos deben tener tarifa (228/228).
-- SELECT tipo_impuesto, tarifa_impuesto, COUNT(*) AS productos
--   FROM public.producto
--  GROUP BY tipo_impuesto, tarifa_impuesto
--  ORDER BY tarifa_impuesto DESC;
-- Esperado: IVA General 19% -> 66 productos | Impoconsumo 8% -> 162 productos

-- 3.2 Ya NO deben quedar facturas con impuestos en cero.
-- SELECT COUNT(*) AS facturas_sin_impuesto
--   FROM public.factura WHERE impuestos = 0;
-- Esperado: 0

-- 3.3 La ecuacion contable se mantiene en las 500 facturas.
-- SELECT COUNT(*) AS facturas_descuadradas
--   FROM public.factura
--  WHERE ABS(subtotal + impuestos + propina - total) > 1;
-- Esperado: 0

-- 3.4 Los pagos siguen cuadrando con el total de su factura.
-- SELECT COUNT(*) AS facturas_con_pagos_descuadrados
--   FROM public.factura f
--   JOIN (SELECT id_factura, SUM(valor_pago) AS pagado
--           FROM public.pago GROUP BY id_factura) pg
--     ON pg.id_factura = f.id_factura
--  WHERE ABS(f.total - pg.pagado) > 1;
-- Esperado: 0

-- 3.5 Ordenes de pedido con su consecutivo y lugar de entrega.
-- SELECT numero_orden, id_pedido_prov, nit_proveedor, fecha_pedido,
--        estado, lugar_entrega, total_pedido
--   FROM public.pedido_proveedor
--  ORDER BY numero_orden;
