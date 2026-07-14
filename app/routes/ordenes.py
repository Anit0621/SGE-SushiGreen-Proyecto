from flask import Blueprint, render_template, request, redirect, url_for
from app.services.orden import (
    todas_ordenes,
    ordenes_por_estado,
    crear_orden_nueva,
    cambiar_estado_orden,
    borrado_orden,
    ReglaNegocioError
)

orden_bp = Blueprint("orden", __name__, template_folder="templates")


@orden_bp.route("/todas")
def ordenes_todas():
    ordenes = todas_ordenes()
    return render_template("ordenes.html", ordenes=ordenes)


@orden_bp.route("/estado/<string:estado>")
def orden_filtro(estado):
    try:
        ordenes = ordenes_por_estado(estado)
        return render_template("ordenes.html", ordenes=ordenes)
    except ReglaNegocioError as e:
        return render_template("ordenes.html", ordenes=[], error=str(e))


@orden_bp.route("/submit", methods=["GET", "POST"])
def orden_submit():

    if request.method == "POST":
        nit = request.form["nit_proveedor"]
        fecha = request.form["fecha_pedido"]
        lugar = request.form["lugar_entrega"]

        ids = request.form.getlist("id_ingrediente")
        cantidades = request.form.getlist("cantidad")
        precios = request.form.getlist("precio_compra")
        id_sede = request.form["id_sede"]

        lineas = []
        for id_ing, cant, precio in zip(ids, cantidades, precios):
            if id_ing and cant and precio:
                lineas.append((id_ing, cant, precio))

        try:
            crear_orden_nueva(nit, fecha, lugar, lineas, id_sede)
            return redirect(url_for("orden.ordenes_todas"))
        except ReglaNegocioError as e:
            return render_template("registrar_orden.html", error=str(e))

    return render_template("registrar_orden.html")


@orden_bp.route("/cambiar_estado", methods=["GET", "POST"])
def orden_estado():

    if request.method == "POST":
        id_pedido = request.form["id_pedido_prov"]
        nuevo_estado = request.form["estado"]

        try:
            cambiar_estado_orden(id_pedido, nuevo_estado)
            return redirect(url_for("orden.ordenes_todas"))
        except ReglaNegocioError as e:
            return render_template("estado_orden.html", error=str(e))

    return render_template("estado_orden.html")


@orden_bp.route("/delete", methods=["GET", "POST"])
def orden_delete():

    if request.method == "POST":
        id_pedido = request.form["id_pedido_prov"]

        try:
            borrado_orden(id_pedido)
            return redirect(url_for("orden.ordenes_todas"))
        except ReglaNegocioError as e:
            return render_template("borrado_orden.html", error=str(e))

    return render_template("borrado_orden.html")