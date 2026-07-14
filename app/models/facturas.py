from config import get_connection


def obtener_todas():
    conn = get_connection()
    curr = conn.cursor()
    curr.execute("""
                 SELECT f.numero_factura,
                        f.id_factura,
                        c.nombre || ' ' || c.apellido AS cliente,
                        f.fecha_factura,
                        f.subtotal,
                        f.impuestos,
                        f.propina,
                        f.total
                 FROM factura f
                          LEFT JOIN cliente c ON f.cedula_cliente = c.cedula_cliente
                 ORDER BY f.id_factura DESC
                 """)
    data = curr.fetchall()
    curr.close()
    conn.close()
    return data


def filtrar_por_cliente(cedula):
    conn = get_connection()
    curr = conn.cursor()
    curr.execute("""
                 SELECT f.numero_factura,
                        f.id_factura,
                        c.nombre || ' ' || c.apellido AS cliente,
                        f.fecha_factura,
                        f.subtotal,
                        f.impuestos,
                        f.propina,
                        f.total
                 FROM factura f
                          LEFT JOIN cliente c ON f.cedula_cliente = c.cedula_cliente
                 WHERE f.cedula_cliente = %s
                 ORDER BY f.id_factura DESC
                 """, (cedula,))
    data = curr.fetchall()
    curr.close()
    conn.close()
    return data


def obtener_detalle(id_factura):
    conn = get_connection()
    curr = conn.cursor()
    curr.execute("""
                 SELECT pr.nombre_producto,
                        pr.tipo_impuesto,
                        pr.tarifa_impuesto,
                        d.cantidad_producto,
                        d.precio_unitario,
                        d.subtotal,
                        ROUND(d.subtotal * pr.tarifa_impuesto / 100.0, 2) AS impuesto
                 FROM factura f
                          JOIN pedido p         ON p.id_factura = f.id_factura
                          JOIN detalle_pedido d ON d.id_pedido = p.id_pedido
                          JOIN producto pr      ON pr.id_producto = d.id_producto
                 WHERE f.id_factura = %s
                 ORDER BY pr.nombre_producto
                 """, (id_factura,))
    data = curr.fetchall()
    curr.close()
    conn.close()
    return data


def existe_factura(id_factura):
    conn = get_connection()
    curr = conn.cursor()
    curr.execute(
        "SELECT 1 FROM factura WHERE id_factura = %s",
        (id_factura,)
    )
    fila = curr.fetchone()
    curr.close()
    conn.close()
    return fila is not None


def crear_factura(cedula_cliente, cedula_empleado, tipo_pedido,
                  fecha, hora, propina, resolucion_dian, nit_empresa,
                  lineas):

    conn = get_connection()
    curr = conn.cursor()

    try:
        # 1. Se leen precio y tarifa de cada producto desde la BD.
        #    Asi el usuario no puede alterar el precio ni el impuesto.
        detalle = []
        subtotal_factura = 0
        impuesto_factura = 0

        for id_producto, cantidad in lineas:
            curr.execute("""
                         SELECT precio, tarifa_impuesto
                         FROM producto
                         WHERE id_producto = %s
                         """, (id_producto,))
            fila = curr.fetchone()

            if fila is None:
                raise ValueError(f"El producto {id_producto} no existe.")

            precio, tarifa = float(fila[0]), float(fila[1])
            cantidad = int(cantidad)

            subtotal_linea = round(precio * cantidad, 2)
            impuesto_linea = round(subtotal_linea * tarifa / 100.0, 2)

            detalle.append((id_producto, cantidad, precio, subtotal_linea))
            subtotal_factura += subtotal_linea
            impuesto_factura += impuesto_linea

        propina = float(propina)
        total = round(subtotal_factura + impuesto_factura + propina, 2)

        # 2. IDs consecutivos, siguiendo el formato de los datos existentes.
        curr.execute("""
                     SELECT COALESCE(MAX(SUBSTRING(id_factura FROM 5)::int), 0) + 1
                     FROM factura
                     """)
        n = curr.fetchone()[0]
        id_factura = "FAC-" + str(n).zfill(5)        # FAC-00501
        numero_factura = "INV-" + str(n).zfill(6)    # INV-000501

        curr.execute("""
                     SELECT COALESCE(MAX(SUBSTRING(id_pedido FROM 5)::int), 0) + 1
                     FROM pedido
                     """)
        id_pedido = "PED-" + str(curr.fetchone()[0]).zfill(5)

        # 3. Primero la factura (el pedido la necesita: id_factura es NOT NULL).
        curr.execute("""
                     INSERT INTO factura
                     (id_factura, cedula_cliente, numero_factura,
                      fecha_factura, hora_factura, subtotal, impuestos,
                      propina, total, resolucion_dian, nit_empresa)
                     VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                     """, (id_factura, cedula_cliente, numero_factura, fecha, hora,
                           subtotal_factura, impuesto_factura, propina, total,
                           resolucion_dian, nit_empresa))

        # 4. El pedido que origino esa factura.
        curr.execute("""
                     INSERT INTO pedido
                     (id_pedido, id_empleado, id_factura, cedula_cliente,
                      fecha_pedido, hora_pedido, tipo_pedido, estado_pedido,
                      subtotal, impuestos, propina, total)
                     VALUES (%s, %s, %s, %s, %s, %s, %s, 'Completado', %s, %s, %s, %s)
                     """, (id_pedido, cedula_empleado, id_factura, cedula_cliente,
                           fecha, hora, tipo_pedido,
                           subtotal_factura, impuesto_factura, propina, total))

        # 5. Las lineas de productos vendidos.
        curr.execute("""
                     SELECT COALESCE(MAX(SUBSTRING(id_detalle FROM 5)::int), 0)
                     FROM detalle_pedido
                     """)
        consecutivo = curr.fetchone()[0]

        for id_producto, cantidad, precio, subtotal_linea in detalle:
            consecutivo += 1
            id_detalle = "DET-" + str(consecutivo).zfill(5)
            curr.execute("""
                         INSERT INTO detalle_pedido
                         (id_detalle, id_pedido, id_producto,
                          cantidad_producto, precio_unitario, subtotal)
                         VALUES (%s, %s, %s, %s, %s, %s)
                         """, (id_detalle, id_pedido, id_producto,
                               cantidad, precio, subtotal_linea))

        conn.commit()
        return id_factura

    except Exception:
        conn.rollback()   # si algo falla, no queda nada a medias
        raise
    finally:
        curr.close()
        conn.close()