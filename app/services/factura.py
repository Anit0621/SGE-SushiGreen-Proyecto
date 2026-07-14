from app.models.facturas import (
    obtener_todas,
    filtrar_por_cliente,
    obtener_detalle,
    existe_factura,
    crear_factura
)

RESOLUCION_DIAN = "RES-DIAN-2023"
NIT_EMPRESA = "900.123.456-7"

TIPOS_PEDIDO = ("Mesa", "Domicilio", "Llevar")


class ReglaNegocioError(Exception):
    pass



def todas_facturas():
    return obtener_todas()


def facturas_por_cliente(cedula):
    return filtrar_por_cliente(cedula)


def detalle_factura(id_factura):
    if not existe_factura(id_factura):
        raise ReglaNegocioError(f"No existe la factura {id_factura}.")
    return obtener_detalle(id_factura)



def emitir_factura(cedula_cliente, cedula_empleado, tipo_pedido,
                   fecha, hora, propina, lineas):

    if not lineas:
        raise ReglaNegocioError(
            "Una factura debe tener al menos un producto."
        )

    if tipo_pedido not in TIPOS_PEDIDO:
        raise ReglaNegocioError(
            f"El tipo de pedido '{tipo_pedido}' no es valido. "
            f"Validos: {', '.join(TIPOS_PEDIDO)}."
        )

    for id_producto, cantidad in lineas:
        if int(cantidad) < 1:
            raise ReglaNegocioError(
                f"La cantidad del producto {id_producto} debe ser "
                f"minimo 1."
            )

    if float(propina) < 0:
        raise ReglaNegocioError("La propina no puede ser negativa.")

    return crear_factura(
        cedula_cliente, cedula_empleado, tipo_pedido,
        fecha, hora, propina,
        RESOLUCION_DIAN, NIT_EMPRESA,
        lineas
    )


def actualizar_factura(id_factura):
    """

      "Las Facturas y Ordenes de Pedido, una vez finalizadas y guardadas,
       no deben ser eliminables ni editables (segun la normativa de
       Facturacion Electronica en Colombia)."

    Una factura emitida ya fue reportada a la DIAN. Corregirla en la base
    de datos falsificaria el historial contable. Si hay un error, la ley
    obliga a emitir una NOTA CREDITO, que es un documento nuevo; no se
    edita la factura original.
    """
    raise ReglaNegocioError(
        f"La factura {id_factura} no se puede editar. Una factura emitida "
        f"es un documento en firme ante la DIAN. Para corregirla se debe "
        f"emitir una nota credito."
    )


def eliminar_factura(id_factura):
    raise ReglaNegocioError(
        f"La factura {id_factura} no se puede eliminar. La normativa de "
        f"Facturacion Electronica exige que el rastro de la transaccion "
        f"sea inalterable."
    )   