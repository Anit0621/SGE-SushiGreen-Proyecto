
-- PROYECTO SGE - SUSHI GREEN (Grupo FMC S.A.S.)
-- Curso 750006C Bases de Datos - Grupo 01
-- Universidad del Valle - Semestre 2026-1
--
-- Archivo: 04_ajustes_proveedor.sql
--
-- OBJETIVO
--   Completar la tabla PROVEEDOR con los campos exigidos en el enunciado
--   (Datos de Proveedores) y poblarlos para los 30 proveedores ya
--   existentes, sin alterar la informacion previa.
--
--   El enunciado indica que el proveedor debe tener "todos los datos de
--   la seccion anterior de los clientes, mas" los campos propios de un
--   tercero comercial.
--
-- CAMPOS AGREGADOS
--   Heredados de Cliente:
--     tipo_documento, habeas_data, ciudad, representante_legal,
--     regimen_tributario
--   Propios del Proveedor:
--     rut                    Registro Unico Tributario (DIAN)
--     banco / tipo_cuenta / numero_cuenta   Certificacion bancaria
--     tiempo_entrega_dias    Para alertar sobre reabastecimiento
--     contacto_comercial     Negocia precios y descuentos
--     contacto_cartera       Concilia facturas y pagos
--     contacto_logistico     Coordina la entrada de mercancia
--     condiciones_pago_dias  Dias maximos para pagarle al proveedor
--     calificacion           Escala 1 a 5 por cumplimiento historico



-- 1. AGREGAR LAS COLUMNAS NUEVAS

ALTER TABLE public.proveedor
    -- Campos heredados de la seccion de Clientes
    ADD COLUMN IF NOT EXISTS tipo_documento        character varying(3),
    ADD COLUMN IF NOT EXISTS habeas_data           boolean,
    ADD COLUMN IF NOT EXISTS ciudad                character varying(50),
    ADD COLUMN IF NOT EXISTS representante_legal   character varying(120),
    ADD COLUMN IF NOT EXISTS regimen_tributario    character varying(30),
    -- Campos propios del proveedor
    ADD COLUMN IF NOT EXISTS rut                   character varying(20),
    ADD COLUMN IF NOT EXISTS banco                 character varying(50),
    ADD COLUMN IF NOT EXISTS tipo_cuenta           character varying(20),
    ADD COLUMN IF NOT EXISTS numero_cuenta         character varying(30),
    ADD COLUMN IF NOT EXISTS tiempo_entrega_dias   integer,
    ADD COLUMN IF NOT EXISTS contacto_comercial    character varying(120),
    ADD COLUMN IF NOT EXISTS contacto_cartera      character varying(120),
    ADD COLUMN IF NOT EXISTS contacto_logistico    character varying(120),
    ADD COLUMN IF NOT EXISTS condiciones_pago_dias integer,
    ADD COLUMN IF NOT EXISTS calificacion          integer;



-- 2. POBLAR LOS PROVEEDORES YA EXISTENTES

-- 2.1 Tipo de documento
-- Los 30 proveedores son empresas (SAS, Ltda, SA), por lo que su
-- documento de identificacion tributaria es el NIT.
UPDATE public.proveedor
   SET tipo_documento = 'NIT'
 WHERE tipo_documento IS NULL;


-- 2.2 RUT (Registro Unico Tributario)
-- Segun la DIAN, para una persona juridica el numero del RUT coincide
-- con el NIT. Por eso no se inventa un numero nuevo: se copia el NIT.
UPDATE public.proveedor
   SET rut = nit_proveedor
 WHERE rut IS NULL;


-- 2.3 Regimen tributario
-- Al ser empresas que facturan insumos, son responsables de IVA.
UPDATE public.proveedor
   SET regimen_tributario = 'Responsable de IVA'
 WHERE regimen_tributario IS NULL;


-- 2.4 Habeas Data
UPDATE public.proveedor
   SET habeas_data = TRUE
 WHERE habeas_data IS NULL;


-- 2.5 Ciudad
-- Proveedores del Valle del Cauca y del eje de abastecimiento del
-- Pacifico. Los de Pescado y Mariscos se ubican en Buenaventura, que es
-- el puerto por el que realmente entra el producto marino a la region.
UPDATE public.proveedor
   SET ciudad = CASE
        WHEN tipo_proveedor = 'Pescado y Mariscos' THEN 'Buenaventura'
        WHEN tipo_proveedor = 'Logistica Fria'     THEN 'Yumbo'
        WHEN tipo_proveedor = 'Empaques'           THEN 'Yumbo'
        ELSE (ARRAY['Cali','Cali','Cali','Palmira','Buga'])
             [ (('x' || substr(md5(nit_proveedor), 1, 8))::bit(32)::bigint
                 & 2147483647) % 5 + 1 ]
   END
 WHERE ciudad IS NULL;


-- 2.6 Certificacion bancaria (banco, tipo de cuenta y numero)
-- Indispensable para programar pagos por transferencia.
UPDATE public.proveedor
   SET banco = (ARRAY['Bancolombia','Banco de Bogota','Davivienda',
                      'BBVA Colombia','Banco de Occidente','Banco Popular'])
               [ (('x' || substr(md5(nit_proveedor || 'b'), 1, 8))::bit(32)::bigint
                   & 2147483647) % 6 + 1 ],
       tipo_cuenta = (ARRAY['Ahorros','Corriente'])
               [ (('x' || substr(md5(nit_proveedor || 'c'), 1, 8))::bit(32)::bigint
                   & 2147483647) % 2 + 1 ],
       -- Numero de cuenta de 11 digitos derivado del NIT.
       numero_cuenta = lpad(
               ( (('x' || substr(md5(nit_proveedor || 'n'), 1, 8))::bit(32)::bigint
                   & 2147483647) % 100000000000 )::text, 11, '0')
 WHERE banco IS NULL;


-- 2.7 Tiempo de entrega promedio (dias)
-- No se asigna al azar: depende de la naturaleza del insumo. El pescado
-- fresco y la cadena de frio se despachan en 1-2 dias; los empaques y
-- los granos, al ser productos no perecederos, se piden con mas holgura.
UPDATE public.proveedor
   SET tiempo_entrega_dias = CASE tipo_proveedor
        WHEN 'Pescado y Mariscos'  THEN 1
        WHEN 'Logistica Fria'      THEN 1
        WHEN 'Carnes y Aves'       THEN 2
        WHEN 'Vegetales y Algas'   THEN 2
        WHEN 'Frutas y Citricos'   THEN 2
        WHEN 'Salsas y Aderezos'   THEN 5
        WHEN 'Proteina de Soya'    THEN 5
        WHEN 'Bebidas'             THEN 7
        WHEN 'Granos y Cereales'   THEN 8
        WHEN 'Empaques'            THEN 10
        ELSE 5
   END
 WHERE tiempo_entrega_dias IS NULL;


-- 2.8 Condiciones de pago (dias maximos para pagarle al proveedor)
-- Practica comercial habitual en Colombia: 15, 30, 45 o 60 dias.
-- A mayor perecibilidad del insumo, menor el plazo de pago.
UPDATE public.proveedor
   SET condiciones_pago_dias = CASE
        WHEN tiempo_entrega_dias <= 2 THEN 15
        WHEN tiempo_entrega_dias <= 5 THEN 30
        WHEN tiempo_entrega_dias <= 8 THEN 45
        ELSE 60
   END
 WHERE condiciones_pago_dias IS NULL;


-- 2.9 Calificacion (1 a 5 segun cumplimiento historico)
--
-- PASO A: para los proveedores que SI tienen ordenes registradas en
-- pedido_proveedor, la calificacion se DERIVA de su cumplimiento real:
-- se premia la proporcion de ordenes entregadas y se castiga cada
-- orden cancelada.
UPDATE public.proveedor p
   SET calificacion = GREATEST(1, LEAST(5,
            3
            + (h.entregadas * 2) / GREATEST(h.total, 1)
            - h.canceladas
       ))
  FROM (
        SELECT nit_proveedor,
               COUNT(*)                                        AS total,
               COUNT(*) FILTER (WHERE estado = 'entregado')     AS entregadas,
               COUNT(*) FILTER (WHERE estado = 'cancelado')     AS canceladas
          FROM public.pedido_proveedor
         GROUP BY nit_proveedor
       ) h
 WHERE p.nit_proveedor = h.nit_proveedor
   AND p.calificacion IS NULL;

-- PASO B: los proveedores restantes aun no tienen historial de ordenes
-- en el sistema, por lo que no hay cumplimiento que medir. Se les asigna
-- una calificacion base de 4 (buen desempeno por defecto), salvo a los
-- que estan inactivos, que reciben 2. Esta calificacion se ira ajustando
-- automaticamente a medida que la aplicacion registre nuevas ordenes.
UPDATE public.proveedor
   SET calificacion = CASE
        WHEN estado_proveedor = 'Inactivo' THEN 2
        ELSE 4
   END
 WHERE calificacion IS NULL;


-- 2.10 Contactos (comercial, cartera y logistico)
-- Tres personas distintas por proveedor, derivadas del NIT para que sean
-- estables y reproducibles.
UPDATE public.proveedor
   SET contacto_comercial =
         (ARRAY['Andres','Carolina','Julian','Marcela','Diego','Paola',
                'Santiago','Lorena','Felipe','Natalia'])
         [ (('x' || substr(md5(nit_proveedor || 'k1'), 1, 8))::bit(32)::bigint
             & 2147483647) % 10 + 1 ]
         || ' ' ||
         (ARRAY['Ramirez','Gomez','Vargas','Castillo','Ospina','Rincon',
                'Zapata','Cardona','Mejia','Arboleda'])
         [ (('x' || substr(md5(nit_proveedor || 'a1'), 1, 8))::bit(32)::bigint
             & 2147483647) % 10 + 1 ],
       contacto_cartera =
         (ARRAY['Luis','Sandra','Camilo','Adriana','Oscar','Claudia',
                'Mauricio','Viviana','Ricardo','Angela'])
         [ (('x' || substr(md5(nit_proveedor || 'k2'), 1, 8))::bit(32)::bigint
             & 2147483647) % 10 + 1 ]
         || ' ' ||
         (ARRAY['Moreno','Salazar','Quintero','Betancourt','Lozano','Pineda',
                'Escobar','Grisales','Valencia','Hurtado'])
         [ (('x' || substr(md5(nit_proveedor || 'a2'), 1, 8))::bit(32)::bigint
             & 2147483647) % 10 + 1 ],
       contacto_logistico =
         (ARRAY['Jorge','Milena','Sebastian','Yuliana','Fabian','Erika',
                'Alberto','Katherine','Hernan','Tatiana'])
         [ (('x' || substr(md5(nit_proveedor || 'k3'), 1, 8))::bit(32)::bigint
             & 2147483647) % 10 + 1 ]
         || ' ' ||
         (ARRAY['Torres','Bedoya','Marin','Palacios','Cifuentes','Renteria',
                'Agudelo','Bonilla','Sanchez','Caicedo'])
         [ (('x' || substr(md5(nit_proveedor || 'a3'), 1, 8))::bit(32)::bigint
             & 2147483647) % 10 + 1 ]
 WHERE contacto_comercial IS NULL;


-- 2.11 Representante legal
-- Para una empresa, el representante legal es quien la representa ante
-- las autoridades. Se toma el contacto comercial como representante.
UPDATE public.proveedor
   SET representante_legal = contacto_comercial
 WHERE representante_legal IS NULL;


-- =====================================================================
-- 3. RESTRICCIONES DE INTEGRIDAD
-- =====================================================================
-- Se aplican DESPUES de poblar, para que las 30 filas existentes ya
-- cumplan las reglas.

-- La calificacion es una escala cerrada de 1 a 5 (5 = excelente).
ALTER TABLE public.proveedor
    DROP CONSTRAINT IF EXISTS proveedor_calificacion_check;
ALTER TABLE public.proveedor
    ADD CONSTRAINT proveedor_calificacion_check
    CHECK (calificacion BETWEEN 1 AND 5);

-- Un tiempo de entrega debe ser un numero positivo de dias.
ALTER TABLE public.proveedor
    DROP CONSTRAINT IF EXISTS proveedor_tiempo_entrega_check;
ALTER TABLE public.proveedor
    ADD CONSTRAINT proveedor_tiempo_entrega_check
    CHECK (tiempo_entrega_dias > 0);

-- Las condiciones de pago no pueden ser negativas.
ALTER TABLE public.proveedor
    DROP CONSTRAINT IF EXISTS proveedor_condiciones_pago_check;
ALTER TABLE public.proveedor
    ADD CONSTRAINT proveedor_condiciones_pago_check
    CHECK (condiciones_pago_dias >= 0);

-- Solo los tipos de documento validos en Colombia.
ALTER TABLE public.proveedor
    DROP CONSTRAINT IF EXISTS proveedor_tipo_documento_check;
ALTER TABLE public.proveedor
    ADD CONSTRAINT proveedor_tipo_documento_check
    CHECK (tipo_documento IN ('CC', 'NIT', 'CE'));

-- Solo los dos tipos de cuenta bancaria que existen.
ALTER TABLE public.proveedor
    DROP CONSTRAINT IF EXISTS proveedor_tipo_cuenta_check;
ALTER TABLE public.proveedor
    ADD CONSTRAINT proveedor_tipo_cuenta_check
    CHECK (tipo_cuenta IN ('Ahorros', 'Corriente'));

-- Campos que la aplicacion web debe exigir siempre.
ALTER TABLE public.proveedor ALTER COLUMN tipo_documento      SET NOT NULL;
ALTER TABLE public.proveedor ALTER COLUMN rut                 SET NOT NULL;
ALTER TABLE public.proveedor ALTER COLUMN tiempo_entrega_dias SET NOT NULL;
ALTER TABLE public.proveedor ALTER COLUMN calificacion        SET NOT NULL;
ALTER TABLE public.proveedor ALTER COLUMN habeas_data         SET NOT NULL;
ALTER TABLE public.proveedor ALTER COLUMN habeas_data         SET DEFAULT FALSE;



-- 4. VERIFICACION

-- 4.1 No debe quedar ningun NULL: todas las columnas deben dar 30.
-- SELECT COUNT(*)                    AS total,
--        COUNT(rut)                  AS con_rut,
--        COUNT(banco)                AS con_banco,
--        COUNT(tiempo_entrega_dias)  AS con_tiempo_entrega,
--        COUNT(condiciones_pago_dias)AS con_condiciones,
--        COUNT(calificacion)         AS con_calificacion,
--        COUNT(contacto_comercial)   AS con_contactos
--   FROM public.proveedor;

-- 4.2 Vista general de los proveedores completos.
-- SELECT nit_proveedor, nombre_proveedor, tipo_proveedor, ciudad,
--        tiempo_entrega_dias, condiciones_pago_dias, calificacion,
--        banco, tipo_cuenta
--   FROM public.proveedor
--  ORDER BY calificacion DESC, tiempo_entrega_dias;

-- 4.3 Los 6 proveedores cuya calificacion SI se derivo del historial real.
-- SELECT p.nit_proveedor, p.nombre_proveedor, p.calificacion,
--        COUNT(*)                                    AS ordenes,
--        COUNT(*) FILTER (WHERE pp.estado='entregado') AS entregadas,
--        COUNT(*) FILTER (WHERE pp.estado='cancelado') AS canceladas
--   FROM public.proveedor p
--   JOIN public.pedido_proveedor pp ON p.nit_proveedor = pp.nit_proveedor
--  GROUP BY p.nit_proveedor, p.nombre_proveedor, p.calificacion
--  ORDER BY p.calificacion DESC;
