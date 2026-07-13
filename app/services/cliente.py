
from app.models.clientes import obtener_clientes, filtrar_clientes, crear_cliente, obtener_todos, eliminar_cliente

def todos_clientes():
    return obtener_todos()

def listar_clientes(limite):
    return obtener_clientes(limite)

def filtro_por_doc(tipo_doc):
    return filtrar_clientes(tipo_doc)

def crear_cliente_nuevo(cedula_cliente,nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,direccion_residencia,
                 direccion_operativa,email,representante_legal,regimen_tributario):
    crear_cliente(cedula_cliente,nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,direccion_residencia,
                 direccion_operativa,email,representante_legal,regimen_tributario)

def borrado_cliente(id_cliente):
    eliminar_cliente(id_cliente)