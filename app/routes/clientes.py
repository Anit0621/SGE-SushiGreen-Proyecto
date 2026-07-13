from flask import Flask, render_template, Blueprint, request, url_for, redirect
from app.services.cliente import (listar_clientes, filtro_por_doc, crear_cliente_nuevo,
                                  todos_clientes, borrado_cliente, actualizado_cliente)


cliente_bp = Blueprint("cliente", __name__,template_folder="templates")


@cliente_bp.route("/<int:limite>")
def cliente(limite):
    clientes = listar_clientes(limite)
    return render_template("clientes.html", clientes=clientes)

@cliente_bp.route("/<string:tipo_doc>")
def cliente_filtro(tipo_doc):
    clientes = filtro_por_doc(tipo_doc)
    return render_template("clientes.html", clientes=clientes)

@cliente_bp.route("/todos")
def clientes_todos():
    clientes = todos_clientes()
    return render_template("clientes.html", clientes=clientes)

@cliente_bp.route("/submit",methods=["POST","GET"])
def cliente_submit():
    if request.method == "POST":
        cedula = request.form["ced"]
        nombre = request.form["nombre"]
        apellido = request.form["apellido"]
        telefono = request.form["telefono"]
        tipo_documento = request.form["tip_documento"]
        habeas_data = request.form["habeas_data"]
        ciudad = request.form["ciudad"]
        direccion_residencia = request.form["dir_res"]
        direccion_operativa = request.form["dir_opr"]
        email = request.form["email"]
        representante_legal = request.form["repr_legal"]
        regimen_tributario = request.form["reg_trib"]
        crear_cliente_nuevo(cedula,nombre,apellido,telefono,tipo_documento,habeas_data,ciudad,direccion_residencia,direccion_operativa,email
                            ,representante_legal,regimen_tributario)
        return redirect(url_for("cliente.clientes_todos"))
    else:
        return render_template("registrar_cliente.html")

@cliente_bp.route("/delete",methods=["GET","POST"])
def cliente_delete():

    if request.method == "POST":
        id_cliente = request.form["ced"]
        borrado_cliente(id_cliente)

        return redirect(url_for("cliente.clientes_todos"))

    else:
        return render_template("borrado_cliente.html")

@cliente_bp.route("/update",methods=["GET","POST"])
def cliente_update():
    if request.method == "POST":
        id_cliente = request.form["dato"]
        nombre = request.form["nombre"]
        apellido = request.form["apellido"]
        telefono = request.form["telefono"]
        tipo_documento = request.form["tipo_doc"]
        habeas_data = request.form["hab_data"]
        ciudad = request.form["ciudad"]
        direccion_residencia = request.form["direc_res"]
        direccion_operativa = request.form["direc_opr"]
        email = request.form["email"]
        representante_legal = request.form["repr_legal"]
        regimen_tributario = request.form["reg_trib"]
        actualizado_cliente(id_cliente,nombre,apellido,telefono,tipo_documento, habeas_data, ciudad, direccion_residencia,
                            direccion_operativa, email, representante_legal, regimen_tributario)
        return redirect(url_for("cliente.clientes_todos"))

    else:
        return render_template("actualizado_cliente.html")

