from config import get_connection


def obtener_todos():
    conn = get_connection()
    curr = conn.cursor()

    curr.execute("SELECT nombre_proveedor, nit_proveedor FROM proveedor")

    data = curr.fetchall()

    curr.close()
    conn.close()

    return data


def obtener_proveedores(limite):
    conn = get_connection()
    curr = conn.cursor()

    curr.execute(
        "SELECT nombre_proveedor, nit_proveedor FROM proveedor LIMIT %s",
        (limite,)
    )

    data = curr.fetchall()

    curr.close()
    conn.close()

    return data


def filtrar_proveedores(tipo_doc):
    conn = get_connection()
    curr = conn.cursor()

    curr.execute(
        "SELECT nombre_proveedor, nit_proveedor FROM proveedor WHERE tipo_documento = %s",
        (tipo_doc,)
    )

    data = curr.fetchall()

    curr.close()
    conn.close()

    return data


def crear_proveedor(
    nit_proveedor,
    nombre_proveedor,
    telefono,
    direccion,
    correo,
    tipo_proveedor,
    estado_proveedor,
    tipo_documento,
    habeas_data,
    ciudad,
    representante_legal,
    regimen_tributario,
    rut,
    banco,
    tipo_cuenta,
    numero_cuenta,
    tiempo_entrega_dias,
    contacto_comercial,
    contacto_cartera,
    contacto_logistico,
    condiciones_pago_dias,
    calificacion
):

    conn = get_connection()
    curr = conn.cursor()

    curr.execute("""
        INSERT INTO proveedor(
            nit_proveedor,
            nombre_proveedor,
            telefono,
            direccion,
            correo,
            tipo_proveedor,
            estado_proveedor,
            tipo_documento,
            habeas_data,
            ciudad,
            representante_legal,
            regimen_tributario,
            rut,
            banco,
            tipo_cuenta,
            numero_cuenta,
            tiempo_entrega_dias,
            contacto_comercial,
            contacto_cartera,
            contacto_logistico,
            condiciones_pago_dias,
            calificacion
        )
        VALUES (
            %s,%s,%s,%s,%s,
            %s,%s,%s,%s,
            %s,%s,%s,%s,%s,
            %s,%s,%s,
            %s,%s,%s,
            %s,%s
        )
    """, (
        nit_proveedor,
        nombre_proveedor,
        telefono,
        direccion,
        correo,
        tipo_proveedor,
        estado_proveedor,
        tipo_documento,
        habeas_data,
        ciudad,
        representante_legal,
        regimen_tributario,
        rut,
        banco,
        tipo_cuenta,
        numero_cuenta,
        tiempo_entrega_dias,
        contacto_comercial,
        contacto_cartera,
        contacto_logistico,
        condiciones_pago_dias,
        calificacion
    ))

    conn.commit()

    curr.close()
    conn.close()

def actualizar_proveedor(
    nit_proveedor,
    nombre_proveedor,
    telefono,
    direccion,
    correo,
    tipo_proveedor,
    estado_proveedor,
    tipo_documento,
    habeas_data,
    ciudad,
    representante_legal,
    regimen_tributario,
    rut,
    banco,
    tipo_cuenta,
    numero_cuenta,
    tiempo_entrega_dias,
    contacto_comercial,
    contacto_cartera,
    contacto_logistico,
    condiciones_pago_dias,
    calificacion
):

    conn = get_connection()
    curr = conn.cursor()

    curr.execute("""
        UPDATE proveedor
        SET
            nombre_proveedor=%s,
            telefono=%s,
            direccion=%s,
            correo=%s,
            tipo_proveedor=%s,
            estado_proveedor=%s,
            tipo_documento=%s,
            habeas_data=%s,
            ciudad=%s,
            representante_legal=%s,
            regimen_tributario=%s,
            rut=%s,
            banco=%s,
            tipo_cuenta=%s,
            numero_cuenta=%s,
            tiempo_entrega_dias=%s,
            contacto_comercial=%s,
            contacto_cartera=%s,
            contacto_logistico=%s,
            condiciones_pago_dias=%s,
            calificacion=%s
        WHERE nit_proveedor=%s
    """, (
        nombre_proveedor,
        telefono,
        direccion,
        correo,
        tipo_proveedor,
        estado_proveedor,
        tipo_documento,
        habeas_data,
        ciudad,
        representante_legal,
        regimen_tributario,
        rut,
        banco,
        tipo_cuenta,
        numero_cuenta,
        tiempo_entrega_dias,
        contacto_comercial,
        contacto_cartera,
        contacto_logistico,
        condiciones_pago_dias,
        calificacion,
        nit_proveedor
    ))

    conn.commit()
    curr.close()
    conn.close()

def eliminar_proveedor(nit):
    conn = get_connection()
    curr = conn.cursor()

    curr.execute(
        "DELETE FROM proveedor WHERE nit_proveedor = %s",
        (nit,)
    )

    conn.commit()

    curr.close()
    conn.close()