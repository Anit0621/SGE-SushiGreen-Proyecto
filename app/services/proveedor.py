from app.models.proveedores import (
    obtener_proveedores,
    filtrar_proveedores,
    crear_proveedor,
    obtener_todos,
    eliminar_proveedor,
    actualizar_proveedor
)


def todos_proveedores():
    return obtener_todos()


def listar_proveedores(limite):
    return obtener_proveedores(limite)


def filtro_por_doc(tipo_doc):
    return filtrar_proveedores(tipo_doc)


def crear_proveedor_nuevo(
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
    crear_proveedor(
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

def actualizar_proveedor_nuevo(
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
    actualizar_proveedor(
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

def borrado_proveedor(nit):
    eliminar_proveedor(nit)