from app.models.ordenes import (
    obtener_todas,
    filtrar_por_estado,
    obtener_estado,
    crear_orden,
    actualizar_estado,
    eliminar_orden
)



ESTADOS_VALIDOS = ("pendiente", "en transito", "entregado", "cancelado")


class ReglaNegocioError(Exception):
    pass




def todas_ordenes():
    return obtener_todas()


def ordenes_por_estado(estado):
    if estado not in ESTADOS_VALIDOS:
        raise ReglaNegocioError(
            f"El estado '{estado}' no existe. "
            f"Validos: {', '.join(ESTADOS_VALIDOS)}."
        )
    return filtrar_por_estado(estado)




def crear_orden_nueva(nit_proveedor, fecha_pedido, lugar_entrega, lineas):
    if not lineas:
        raise ReglaNegocioError(
            "Una orden de pedido debe tener al menos un insumo."
        )

    # El enunciado exige cantidad minima 1 y la BD topa en 500 porque son
    # insumos perecederos. Se valida aqui para dar un mensaje claro en vez
    # de dejar que reviente el CHECK de PostgreSQL con un error 500.
    for id_ingrediente, cantidad, precio in lineas:
        if float(cantidad) < 1 or float(cantidad) > 500:
            raise ReglaNegocioError(
                f"La cantidad del insumo {id_ingrediente} debe estar "
                f"entre 1 y 500 unidades."
            )
        if float(precio) <= 0:
            raise ReglaNegocioError(
                f"El precio de compra del insumo {id_ingrediente} "
                f"debe ser mayor que cero."
            )

    return crear_orden(nit_proveedor, fecha_pedido, lugar_entrega, lineas)


def cambiar_estado_orden(id_pedido_prov, nuevo_estado):
    estado_actual = obtener_estado(id_pedido_prov)

    if estado_actual is None:
        raise ReglaNegocioError(f"No existe la orden {id_pedido_prov}.")

    if nuevo_estado not in ESTADOS_VALIDOS:
        raise ReglaNegocioError(
            f"El estado '{nuevo_estado}' no es valido. "
            f"Validos: {', '.join(ESTADOS_VALIDOS)}."
        )

    if estado_actual in ("entregado", "cancelado"):
        raise ReglaNegocioError(
            f"La orden {id_pedido_prov} ya esta cerrada (estado: "
            f"'{estado_actual}'). Una orden cerrada no se puede modificar."
        )

    actualizar_estado(id_pedido_prov, nuevo_estado)


def borrado_orden(id_pedido_prov):
    estado_actual = obtener_estado(id_pedido_prov)

    if estado_actual is None:
        raise ReglaNegocioError(f"No existe la orden {id_pedido_prov}.")

    # REGLA: una orden ya despachada o recibida es un
    # documento en firme. Solo se puede anular mientras sigue pendiente.
    if estado_actual != "pendiente":
        raise ReglaNegocioError(
            f"No se puede eliminar la orden {id_pedido_prov}: su estado es "
            f"'{estado_actual}'. Solo se pueden anular las ordenes pendientes."
        )

    eliminar_orden(id_pedido_prov)