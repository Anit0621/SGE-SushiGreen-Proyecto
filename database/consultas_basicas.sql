
-- PROYECTO SGE - SUSHI GREEN (Grupo FMC S.A.S.)
-- Curso 750006C Bases de Datos - Grupo 01
-- Universidad del Valle - Semestre 2026-1
-- Docente: Susana Medina Gordillo
--
-- Archivo: consultas_basicas.sql
-- 10 consultas SQL sobre aspectos basicos del negocio.
-- Operan sobre una sola tabla (SELECT, WHERE, ORDER BY y funciones de
-- agregacion simples), sin necesidad de JOIN.




-- CONSULTA 1: Carta del restaurante
-- Los 228 productos activos del menu, del mas costoso al mas economico.
-- Permite revisar la politica de precios de un vistazo.
SELECT
    id_producto,
    nombre_producto,
    precio
FROM producto
WHERE estado_producto = 'Activo'
ORDER BY precio DESC;



-- CONSULTA 2: Directorio de clientes registrados
SELECT
    cedula_cliente,
    nombre,
    apellido,
    telefono
FROM cliente
ORDER BY apellido, nombre;



-- CONSULTA 3: Sedes del restaurante y sus datos de contacto
SELECT
    id_sede,
    nombre_sede,
    direccion,
    telefono
FROM sede
ORDER BY nombre_sede;



-- CONSULTA 4: Proveedores activos, agrupados por tipo de insumo
-- Solo los proveedores con relacion comercial vigente.
SELECT
    nit_proveedor,
    nombre_proveedor,
    tipo_proveedor,
    telefono,
    correo
FROM proveedor
WHERE estado_proveedor = 'Activo'
ORDER BY tipo_proveedor, nombre_proveedor;



-- CONSULTA 5: Mesas para grupos grandes (6 o mas personas)
-- Necesario para atender reservas de eventos y celebraciones.
SELECT
    id_mesa,
    id_sede,
    numero_mesa,
    capacidad
FROM mesa
WHERE capacidad >= 6
ORDER BY capacidad DESC, id_sede;



-- CONSULTA 6: Ingredientes agotados o no disponibles
-- Lista de insumos que actualmente no se pueden usar en cocina.
SELECT
    id_ingrediente,
    nombre_ingrediente,
    unidad_medida,
    stock_minimo,
    estado_ingrediente
FROM ingrediente
WHERE estado_ingrediente = 'no disponible'
ORDER BY nombre_ingrediente;



-- CONSULTA 7: Nomina del restaurante
-- Empleados activos ordenados por salario.
SELECT
    cedula_empleado,
    nombre,
    apellido,
    tipo_contrato,
    salario
FROM empleado
WHERE estado_empleado = 'Activo'
ORDER BY salario DESC;



-- CONSULTA 8: Facturas de mayor valor emitidas
-- Las 15 ventas mas grandes registradas por el restaurante.
SELECT
    numero_factura,
    fecha_factura,
    subtotal,
    impuestos,
    propina,
    total
FROM factura
ORDER BY total DESC
LIMIT 15;



-- CONSULTA 9: Indicadores globales de venta
-- Numero de pedidos, venta total, ticket promedio y valores extremos.
SELECT
    COUNT(*)             AS numero_de_pedidos,
    SUM(total)           AS ventas_totales,
    ROUND(AVG(total), 2) AS ticket_promedio,
    MIN(total)           AS pedido_mas_bajo,
    MAX(total)           AS pedido_mas_alto
FROM pedido;



-- CONSULTA 10: Reservas confirmadas
-- Reservas vigentes ordenadas de la mas proxima a la mas lejana.
SELECT
    id_reserva,
    cedula_cliente,
    id_mesa,
    fecha_reserva,
    hora_reserva,
    cantidad_personas
FROM reserva
WHERE estado_reserva = 'Confirmada'
ORDER BY fecha_reserva, hora_reserva;
