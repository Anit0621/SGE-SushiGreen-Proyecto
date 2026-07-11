
-- PROYECTO SGE - SUSHI GREEN (Grupo FMC S.A.S.)
-- Curso 750006C Bases de Datos - Grupo 01
-- Universidad del Valle - Semestre 2026-1
-- Docente: Susana Medina Gordillo
--
-- Archivo: consultas_complejas.sql
-- 10 consultas SQL sobre aspectos complejos del negocio.
-- Todas utilizan JOIN entre dos o mas tablas junto con funciones de
-- agregacion (SUM, COUNT, AVG) y agrupamiento con GROUP BY.




-- CONSULTA 1: Productos mas vendidos del restaurante
-- Top 10 del menu por unidades vendidas. Base para decidir que platos
-- promocionar y que ingredientes mantener siempre en stock.
SELECT
    p.nombre_producto,
    SUM(dp.cantidad_producto) AS total_vendido
FROM detalle_pedido dp
JOIN producto p
    ON dp.id_producto = p.id_producto
GROUP BY p.nombre_producto
ORDER BY total_vendido DESC
LIMIT 10;



-- CONSULTA 2: Clientes con mas pedidos
-- Ranking de fidelizacion: quienes son los clientes recurrentes.
SELECT
    c.nombre,
    c.apellido,
    COUNT(pe.id_pedido) AS total_pedidos
FROM cliente c
JOIN pedido pe
    ON c.cedula_cliente = pe.cedula_cliente
GROUP BY c.cedula_cliente, c.nombre, c.apellido
ORDER BY total_pedidos DESC
LIMIT 10;



-- CONSULTA 3: Ventas totales por sede
-- Compara el desempeno economico de las 8 sedes del restaurante.
-- Doble JOIN: el pedido conoce la mesa, y la mesa conoce la sede.
SELECT
    s.nombre_sede,
    SUM(pe.total) AS ventas_totales
FROM pedido pe
JOIN mesa m
    ON pe.id_mesa = m.id_mesa
JOIN sede s
    ON m.id_sede = s.id_sede
GROUP BY s.nombre_sede
ORDER BY ventas_totales DESC;



-- CONSULTA 4: Empleados con mas pedidos atendidos
-- Mide la productividad del personal de servicio.
SELECT
    e.nombre,
    e.apellido,
    COUNT(pe.id_pedido) AS pedidos_atendidos
FROM empleado e
JOIN pedido pe
    ON e.cedula_empleado = pe.id_empleado
GROUP BY e.cedula_empleado, e.nombre, e.apellido
ORDER BY pedidos_atendidos DESC;



-- CONSULTA 5: Metodos de pagos mas usados
-- Permite negociar comisiones con bancos y pasarelas segun el volumen.
SELECT
    mp.nombre_metodo,
    COUNT(p.id_pago) AS total_usos
FROM pago p
JOIN metodo_pago mp
    ON p.id_metodo_pago = mp.id_metodo_pago
GROUP BY mp.nombre_metodo
ORDER BY total_usos DESC;



-- CONSULTA 6: Productos por categoria
-- Composicion del menu: cuantos platos hay en cada categoria.
SELECT
    c.nombre_categoria,
    COUNT(p.id_producto) AS cantidad_productos
FROM categoria c
JOIN producto p
    ON c.id_categoria = p.id_categoria
GROUP BY c.nombre_categoria;



-- CONSULTA 7: Los primeros 10 ingredientes con mas bajo stock
--             en la sede de Unicentro
-- Alerta de reabastecimiento para una sede especifica.
-- Triple JOIN: ingrediente -> inventario -> sede.
SELECT
    i.nombre_ingrediente, i.unidad_medida, s.nombre_sede AS SEDE,
    SUM(v.cantidad_disponible) AS STOCK_Del_Ingrediente
    FROM ingrediente i
    INNER JOIN inventario v
        ON i.id_ingrediente = v.id_ingrediente
            INNER JOIN sede s
            ON s.id_sede = v.id_sede
            WHERE s.nombre_sede = 'Unicentro'

    GROUP BY i.nombre_ingrediente,
    i.unidad_medida,
    s.nombre_sede
    ORDER BY STOCK_Del_Ingrediente ASC
    LIMIT 10;



-- CONSULTA 8: Pedidos por plataforma de domicilio
-- Mide la dependencia del restaurante frente las plataformas de domicilio.
SELECT
    pd.nombre_plataforma,
    COUNT(pe.id_pedido) AS total_pedidos
FROM pedido pe
JOIN plataforma_domicilio pd
    ON pe.id_plataforma = pd.id_plataforma
GROUP BY pd.nombre_plataforma
ORDER BY total_pedidos DESC;



-- CONSULTA 9: Ventas mensuales por sede
-- Estacionalidad del negocio desagregada por punto de venta: permite
-- ver si una sede cae en ciertos meses mientras otra crece.

SELECT
    s.nombre_sede,
    EXTRACT(MONTH FROM pe.fecha_pedido) AS mes,
    SUM(pe.total) AS ventas_totales
FROM pedido pe
JOIN mesa m
    ON pe.id_mesa = m.id_mesa
JOIN sede s
    ON m.id_sede = s.id_sede
GROUP BY s.nombre_sede, mes
ORDER BY s.nombre_sede, mes;



-- CONSULTA 10: Promedio de ventas diarias por sede
-- Ticket promedio de cada dia en cada sede. Util para identificar los
-- dias fuertes y flojos de cada punto de venta.
SELECT
    s.nombre_sede,
    pe.fecha_pedido,
    AVG(pe.total) AS promedio_ventas
FROM pedido pe
JOIN mesa m
    ON pe.id_mesa = m.id_mesa
JOIN sede s
    ON m.id_sede = s.id_sede
GROUP BY s.nombre_sede, pe.fecha_pedido
ORDER BY s.nombre_sede, pe.fecha_pedido;
