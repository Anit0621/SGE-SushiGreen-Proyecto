from flask import Flask, render_template, Blueprint

cliente_bp = Blueprint("cliente", __name__,template_folder="templates")


@cliente_bp.route("/",methods=["GET"])
def cliente():
    return render_template("clientes.html")

