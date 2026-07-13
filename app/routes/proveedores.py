from flask import Blueprint, render_template, request, redirect, url_for
from app.services.proveedor import (
    listar_proveedores,
    filtro_por_doc,
    crear_proveedor_nuevo,
    todos_proveedores,
    borrado_proveedor,
    actualizar_proveedor_nuevo
)

proveedor_bp = Blueprint("proveedor", __name__, template_folder="templates")


@proveedor_bp.route("/<int:limite>")
def proveedor(limite):
    proveedores = listar_proveedores(limite)
    return render_template("proveedores.html", proveedores=proveedores)


@proveedor_bp.route("/tipo/<string:tipo_doc>")
def proveedor_filtro(tipo_doc):
    proveedores = filtro_por_doc(tipo_doc)
    return render_template("proveedores.html", proveedores=proveedores)


@proveedor_bp.route("/todos")
def proveedores_todos():
    proveedores = todos_proveedores()
    return render_template("proveedores.html", proveedores=proveedores)


@proveedor_bp.route("/submit", methods=["GET", "POST"])
def proveedor_submit():

    if request.method == "POST":

        nit = request.form["nit"]
        nombre = request.form["nombre"]
        telefono = request.form["telefono"]
        direccion = request.form["direccion"]
        correo = request.form["correo"]
        tipo_proveedor = request.form["tipo_proveedor"]
        estado_proveedor = request.form["estado_proveedor"]
        tipo_documento = request.form["tipo_documento"]
        habeas_data = request.form["habeas_data"]
        ciudad = request.form["ciudad"]
        representante_legal = request.form["representante_legal"]
        regimen_tributario = request.form["regimen_tributario"]
        rut = request.form["rut"]
        banco = request.form["banco"]
        tipo_cuenta = request.form["tipo_cuenta"]
        numero_cuenta = request.form["numero_cuenta"]
        tiempo_entrega_dias = request.form["tiempo_entrega_dias"]
        contacto_comercial = request.form["contacto_comercial"]
        contacto_cartera = request.form["contacto_cartera"]
        contacto_logistico = request.form["contacto_logistico"]
        condiciones_pago_dias = request.form["condiciones_pago_dias"]
        calificacion = request.form["calificacion"]

        crear_proveedor_nuevo(
            nit,
            nombre,
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

        return redirect(url_for("proveedor.proveedores_todos"))

    return render_template("registrar_proveedor.html")

@proveedor_bp.route("/update", methods=["GET", "POST"])
def proveedor_update():

    if request.method == "POST":

        nit = request.form["nit"]
        nombre = request.form["nombre"]
        telefono = request.form["telefono"]
        direccion = request.form["direccion"]
        correo = request.form["correo"]
        tipo_proveedor = request.form["tipo_proveedor"]
        estado_proveedor = request.form["estado_proveedor"]
        tipo_documento = request.form["tipo_documento"]
        habeas_data = request.form["habeas_data"]
        ciudad = request.form["ciudad"]
        representante_legal = request.form["representante_legal"]
        regimen_tributario = request.form["regimen_tributario"]
        rut = request.form["rut"]
        banco = request.form["banco"]
        tipo_cuenta = request.form["tipo_cuenta"]
        numero_cuenta = request.form["numero_cuenta"]
        tiempo_entrega_dias = request.form["tiempo_entrega_dias"]
        contacto_comercial = request.form["contacto_comercial"]
        contacto_cartera = request.form["contacto_cartera"]
        contacto_logistico = request.form["contacto_logistico"]
        condiciones_pago_dias = request.form["condiciones_pago_dias"]
        calificacion = request.form["calificacion"]

        actualizar_proveedor_nuevo(
            nit,
            nombre,
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

        return redirect(url_for("proveedor.proveedores_todos"))

    return render_template("actualizar_proveedor.html")

@proveedor_bp.route("/delete", methods=["GET", "POST"])
def proveedor_delete():

    if request.method == "POST":

        nit = request.form["nit"]

        borrado_proveedor(nit)

        return redirect(url_for("proveedor.proveedores_todos"))

    return render_template("borrado_proveedor.html")