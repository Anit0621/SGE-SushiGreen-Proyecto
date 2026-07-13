from flask import Flask, render_template, Blueprint, request, url_for, redirect

from app.routes.clientes import cliente_bp
from app.routes.proveedores import proveedor_bp
from app.routes.productos import producto_bp
from app.routes.ordenes import orden_bp

app = Flask(__name__)

app.register_blueprint(cliente_bp, url_prefix="/clientes")
app.register_blueprint(proveedor_bp, url_prefix="/proveedores")
app.register_blueprint(producto_bp, url_prefix='/productos')
app.register_blueprint(orden_bp, url_prefix="/ordenes")

@app.route("/", methods=["GET"])
def home():
    return render_template("inicio.html")


if __name__ == "__main__":
    app.run(debug=True)

