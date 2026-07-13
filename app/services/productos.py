
from app.models.productos import (obtener_todos_productos, obtener_productos,
                                  filtrar_productos, crear_producto,
                                  desactivar_producto, activar_producto, cambiar_precio)

def todos_productos():
    return obtener_todos_productos()

def listar_productos(limite):
    return obtener_productos(limite)


def filtro_por_categoria(categoria):
    return filtrar_productos(categoria)


def crear_producto_nuevo(id_producto,id_categoria,nombre_producto,descripcion,
                   precio, estado_producto, tarifa_impuesto, tipo_impuesto):
    crear_producto(id_producto,id_categoria,nombre_producto,descripcion,
                   precio, estado_producto, tarifa_impuesto, tipo_impuesto)

def desactivar(id_producto):
    desactivar_producto(id_producto)

def activar(id_producto):
    activar_producto(id_producto)


def ajustar_precio(precio, id_producto):
    cambiar_precio(precio, id_producto)
