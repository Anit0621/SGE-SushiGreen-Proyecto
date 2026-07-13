from config import get_connection



def obtener_todas():
    conn = get_connection()
    curr = conn.cursor()
    curr.execute("""
                 SELECT pp.numero_orden,
                        pp.id_pedido_prov,
                        p.nombre_proveedor,
                        pp.fecha_pedido,
                        pp.estado,
                        pp.lugar_entrega,
                        pp.total_pedido
                 FROM pedido_proveedor pp
                          JOIN proveedor p ON pp.nit_proveedor = p.nit_proveedor
                 ORDER BY pp.numero_orden DESC
                 """)
    data = curr.fetchall()
    curr.close()
    conn.close()
    return data


def filtrar_por_estado(estado):
    conn = get_connection()
    curr = conn.cursor()
    curr.execute("""
                 SELECT pp.numero_orden,
                        pp.id_pedido_prov,
                        p.nombre_proveedor,
                        pp.fecha_pedido,
                        pp.estado,
                        pp.lugar_entrega,
                        pp.total_pedido
                 FROM pedido_proveedor pp
                          JOIN proveedor p ON pp.nit_proveedor = p.nit_proveedor
                 WHERE pp.estado = %s
                 ORDER BY pp.numero_orden DESC
                 """, (estado,))
    data = curr.fetchall()
    curr.close()
    conn.close()
    return data


def obtener_estado(id_pedido_prov):
    """Devuelve el estado de una orden, o None si no existe."""
    conn = get_connection()
    curr = conn.cursor()
    curr.execute(
        "SELECT estado FROM pedido_proveedor WHERE id_pedido_prov = %s",
        (id_pedido_prov,)
    )
    fila = curr.fetchone()
    curr.close()
    conn.close()
    return fila[0] if fila else None



def crear_orden(nit_proveedor, fecha_pedido, lugar_entrega, lineas):
    """
    lineas: lista de tuplas (id_ingrediente, cantidad, precio_compra).

    Una orden vive en DOS tablas: el encabezado (pedido_proveedor) y sus
    insumos (detalle_pedido_prov). Por eso se guardan en UNA transaccion:
    si falla una linea, se deshace todo y no queda una orden sin insumos.

    No se envian 'estado' ni 'numero_orden': la base de datos los pone
    sola ('pendiente' por defecto y el consecutivo de seq_numero_orden).
    """
    conn = get_connection()
    curr = conn.cursor()

    try:
        # Siguiente ID de orden: PED-PROV-016, PED-PROV-017, ...
        curr.execute("""
                     SELECT 'PED-PROV-' || LPAD(
                             (COALESCE(MAX(SUBSTRING(id_pedido_prov FROM 10)::int), 0) + 1)::text,
                             3, '0')
                     FROM pedido_proveedor
                     """)
        id_pedido = curr.fetchone()[0]

        # El total no se digita: se calcula de las lineas.
        total = sum(float(cant) * float(precio) for _, cant, precio in lineas)

        curr.execute("""
                     INSERT INTO pedido_proveedor
                     (id_pedido_prov, nit_proveedor, fecha_pedido,
                      total_pedido, lugar_entrega)
                     VALUES (%s, %s, %s, %s, %s)
                     """, (id_pedido, nit_proveedor, fecha_pedido, total, lugar_entrega))

        # Siguiente consecutivo del detalle: DET-PROV-001, DET-PROV-002, ...
        curr.execute("""
                     SELECT COALESCE(MAX(SUBSTRING(id_detalle_prov FROM 10)::int), 0)
                     FROM detalle_pedido_prov
                     """)
        consecutivo = curr.fetchone()[0]

        for id_ingrediente, cantidad, precio in lineas:
            consecutivo += 1
            id_detalle = "DET-PROV-" + str(consecutivo).zfill(3)
            curr.execute("""
                         INSERT INTO detalle_pedido_prov
                         (id_detalle_prov, id_pedido_prov, id_ingrediente,
                          cantidad_solicitada, precio_compra)
                         VALUES (%s, %s, %s, %s, %s)
                         """, (id_detalle, id_pedido, id_ingrediente, cantidad, precio))

        conn.commit()
        return id_pedido

    except Exception:
        conn.rollback()   # si algo falla, no queda nada a medias
        raise
    finally:
        curr.close()
        conn.close()


def actualizar_estado(id_pedido_prov, nuevo_estado):
    conn = get_connection()
    curr = conn.cursor()
    curr.execute(
        "UPDATE pedido_proveedor SET estado = %s WHERE id_pedido_prov = %s",
        (nuevo_estado, id_pedido_prov)
    )
    conn.commit()
    curr.close()
    conn.close()


def eliminar_orden(id_pedido_prov):
    """Borra primero el detalle y luego el encabezado (por lo de la FK)."""
    conn = get_connection()
    curr = conn.cursor()
    try:
        curr.execute(
            "DELETE FROM detalle_pedido_prov WHERE id_pedido_prov = %s",
            (id_pedido_prov,)
        )
        curr.execute(
            "DELETE FROM pedido_proveedor WHERE id_pedido_prov = %s",
            (id_pedido_prov,)
        )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        curr.close()
        conn.close()