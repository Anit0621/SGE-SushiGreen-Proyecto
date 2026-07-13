from flask import Flask, render_template, Blueprint, request, url_for, redirect

from app.services.productos import (todos_productos, listar_productos,
                                    filtro_por_categoria,
                                    crear_producto_nuevo, desactivar,
                                    activar, ajustar_precio)


producto_bp = Blueprint("producto", __name__,template_folder="templates")


@producto_bp.route("/<int:limite>")
def producto(limite):
    productos = listar_productos(limite)
    return render_template("productos.html", productos=productos)

@producto_bp.route("/todos")
def productos_todos():
    productos = todos_productos()
    return render_template("productos.html", productos=productos)


@producto_bp.route("/categoria",methods=["POST","GET"])
def producto_filtro():
    if request.method == "POST":
        id_categoria = request.form["id_categoria"]
        productos = filtro_por_categoria(id_categoria)
        return render_template("productos.html", productos=productos)

    else:
        return render_template("categoria_producto.html")


@producto_bp.route("/submit",methods=["POST","GET"])
def producto_submit():
    if request.method == "POST":
        id_producto = request.form["id_producto"]
        id_categoria = request.form["id_categoria"]
        nombre_producto = request.form["nombre"]
        descripcion = request.form["descripcion"]
        precio = request.form["precio"]
        estado_producto = request.form["estado_producto"]
        tarifa_impuesto = request.form["tarifa_impuesto"]
        tipo_impuesto = request.form["tipo_impuesto"]
        crear_producto_nuevo(id_producto,id_categoria,nombre_producto,descripcion,
                   precio, estado_producto, tarifa_impuesto, tipo_impuesto)
        return redirect(url_for("producto.productos_todos"))
    else:
        return render_template("categoria_producto.html")



@producto_bp.route("/desactivate",methods=["GET","POST"])
def producto_desactivar():

    if request.method == "POST":
        id_producto = request.form["id_producto"]
        desactivar(id_producto)
        return redirect(url_for("producto.productos_todos"))

    else:
        return render_template("desactivar_producto.html")

@producto_bp.route("/activate",methods=["GET","POST"])
def producto_activar():

    if request.method == "POST":
        id_producto = request.form["id_producto"]
        activar(id_producto)
        return redirect(url_for("producto.productos_todos"))

    else:
        return render_template("activar_producto.html")

@producto_bp.route("/price",methods=["GET","POST"])
def producto_ajustar_precio():

    if request.method == "POST":
        precio = request.form["precio"]
        id_producto = request.form["id_producto"]
        ajustar_precio(precio, id_producto)
        return redirect(url_for("producto.productos_todos"))

    else:
        return render_template("cambiar_precio.html")