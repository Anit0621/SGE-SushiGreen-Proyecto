
from config import get_connection

def obtener_todos():
    conn = get_connection()
    curr = conn.cursor()

    curr.execute("SELECT nombre, apellido FROM cliente")


    data = curr.fetchall()

    curr.close()
    conn.close()
    return data


def obtener_clientes(limite):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("SELECT nombre, apellido FROM cliente LIMIT %s",(limite,))


    data = curr.fetchall()

    curr.close()
    conn.close()
    return data

def filtrar_clientes(tipo_doc):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("SELECT nombre, apellido FROM cliente WHERE tipo_documento = %s",(tipo_doc,))

    data = curr.fetchall()

    curr.close()
    conn.close()
    return data

def crear_cliente(cedula_cliente,nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,direccion_residencia,
                 direccion_operativa,email,representante_legal,regimen_tributario):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("INSERT INTO cliente(cedula_cliente,nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,direccion_residencia,"
                 "direccion_operativa,email,representante_legal,regimen_tributario) VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                 (cedula_cliente,nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,
                direccion_residencia,direccion_operativa,email,representante_legal,regimen_tributario))
    conn.commit()
    curr.close()
    conn.close()

def eliminar_cliente(id_cliente):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("DELETE FROM cliente WHERE cedula_cliente = %s",(id_cliente,))
    conn.commit()
    curr.close()
    conn.close()

def actualizar_cliente(cedula_cliente,nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,direccion_residencia,direccion_operativa,
                       email,representante_legal,regimen_tributario):
    conn = get_connection()

    curr = conn.cursor()

    curr.execute("UPDATE cliente SET nombre=%s,apellido=%s,telefono=%s,"
                 "tipo_documento=%s,habeas_data=%s,ciudad=%s,direccion_residencia=%s,direccion_operativa=%s, "
                 "email=%s,representante_legal=%s,regimen_tributario=%s WHERE cedula_cliente = %s",(nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,direccion_residencia,direccion_operativa,
                       email,representante_legal,regimen_tributario,cedula_cliente))

    conn.commit()
    curr.close()
    conn.close()






