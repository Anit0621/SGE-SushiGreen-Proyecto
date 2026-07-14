from flask import Blueprint, render_template, request, redirect, url_for
from app.services.factura import (
    todas_facturas,
    facturas_por_cliente,
    detalle_factura,
    emitir_factura,
    actualizar_factura,
    eliminar_factura,
    ReglaNegocioError
)

factura_bp = Blueprint("factura", __name__, template_folder="templates")



@factura_bp.route("/todas")
def facturas_todas():
    facturas = todas_facturas()
    return render_template("facturas.html", facturas=facturas)


@factura_bp.route("/cliente/<string:cedula>")
def factura_filtro(cedula):
    facturas = facturas_por_cliente(cedula)
    return render_template("facturas.html", facturas=facturas)


@factura_bp.route("/detalle/<string:id_factura>")
def factura_detalle(id_factura):
    try:
        lineas = detalle_factura(id_factura)
        return render_template("detalle_factura.html",
                               lineas=lineas, id_factura=id_factura)
    except ReglaNegocioError as e:
        return render_template("detalle_factura.html",
                               lineas=[], id_factura=id_factura, error=str(e))



@factura_bp.route("/submit", methods=["GET", "POST"])
def factura_submit():

    if request.method == "POST":
        cedula_cliente = request.form["cedula_cliente"]
        cedula_empleado = request.form["cedula_empleado"]
        tipo_pedido = request.form["tipo_pedido"]
        fecha = request.form["fecha"]
        hora = request.form["hora"]
        propina = request.form["propina"]

        ids = request.form.getlist("id_producto")
        cantidades = request.form.getlist("cantidad")

        lineas = []
        for id_prod, cant in zip(ids, cantidades):
            if id_prod and cant:
                lineas.append((id_prod, cant))

        try:
            emitir_factura(cedula_cliente, cedula_empleado, tipo_pedido,
                           fecha, hora, propina, lineas)
            return redirect(url_for("factura.facturas_todas"))
        except ReglaNegocioError as e:
            return render_template("registrar_factura.html", error=str(e))

    return render_template("registrar_factura.html")


@factura_bp.route("/update", methods=["GET", "POST"])
def factura_update():

    if request.method == "POST":
        id_factura = request.form["id_factura"]
        try:
            actualizar_factura(id_factura)
            return redirect(url_for("factura.facturas_todas"))
        except ReglaNegocioError as e:
            return render_template("actualizar_factura.html", error=str(e))

    return render_template("actualizar_factura.html")


@factura_bp.route("/delete", methods=["GET", "POST"])
def factura_delete():

    if request.method == "POST":
        id_factura = request.form["id_factura"]
        try:
            eliminar_factura(id_factura)
            return redirect(url_for("factura.facturas_todas"))
        except ReglaNegocioError as e:
            return render_template("borrado_factura.html", error=str(e))

    return render_template("borrado_factura.html")