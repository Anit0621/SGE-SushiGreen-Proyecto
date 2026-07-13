
from config import get_connection

def obtener_todos_productos():
    conn = get_connection()
    curr = conn.cursor()

    curr.execute("SELECT nombre_producto, descripcion, precio FROM producto")

    data = curr.fetchall()

    curr.close()
    conn.close()
    return data


def obtener_productos(limite):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("SELECT nombre_producto, descripcion, precio FROM producto LIMIT %s",(limite,))


    data = curr.fetchall()

    curr.close()
    conn.close()
    return data


def filtrar_productos(categoria):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("SELECT nombre_producto, descripcion, precio FROM producto WHERE id_categoria = %s",(categoria,))

    data = curr.fetchall()

    curr.close()
    conn.close()
    return data


def crear_producto(id_producto,id_categoria,nombre_producto,descripcion,
                   precio, estado_producto, tarifa_impuesto, tipo_impuesto):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("INSERT INTO producto(id_producto,id_categoria,"
                 "nombre_producto, descripcion, precio, estado_producto, "
                 "tarifa_impuesto, tipo_impuesto) VALUES(%s,%s,%s,%s,%s,%s,%s,%s)",
                 (id_producto,id_categoria,nombre_producto,descripcion,
                   precio, estado_producto, tarifa_impuesto, tipo_impuesto))
    conn.commit()
    curr.close()
    conn.close()


def desactivar_producto(id_producto):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("UPDATE producto SET estado_producto = 'Inactivo' "
                 "WHERE id_producto = %s",(id_producto,))
    conn.commit()
    curr.close()
    conn.close()

def activar_producto(id_producto):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("UPDATE producto SET estado_producto = 'Activo' "
                 "WHERE id_producto = %s",(id_producto,))
    conn.commit()
    curr.close()
    conn.close()

def cambiar_precio(precio, id_producto):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("UPDATE producto SET precio = %s "
                 "WHERE id_producto = %s",(precio, id_producto,))
    conn.commit()
    curr.close()
    conn.close()

