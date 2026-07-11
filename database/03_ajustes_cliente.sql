-- =====================================================================
-- PROYECTO SGE - SUSHI GREEN (Grupo FMC S.A.S.)
-- Curso 750006C Bases de Datos - Grupo 01
-- Universidad del Valle - Semestre 2026-1
--
-- Archivo: 03_ajustes_cliente.sql
--
-- OBJETIVO
--   Completar la tabla CLIENTE con los campos exigidos en el enunciado
--   del proyecto (Datos de Clientes) y poblarlos para los 100 clientes
--   ya existentes, sin alterar la informacion previa.
--
-- CAMPOS AGREGADOS
--   tipo_documento        CC / NIT / CE
--   habeas_data           Autorizacion Ley 1581 de 2012 (booleano)
--   ciudad                Ciudad / Municipio
--   direccion_residencia  Direccion de residencia del cliente
--   direccion_operativa   Sede principal (para clientes empresa)
--   email                 Correo electronico
--   representante_legal   Persona que representa al cliente
--   regimen_tributario    Responsable / No responsable de IVA


-- 1. AGREGAR LAS COLUMNAS NUEVAS

ALTER TABLE public.cliente
    ADD COLUMN IF NOT EXISTS tipo_documento       character varying(3),
    ADD COLUMN IF NOT EXISTS habeas_data          boolean,
    ADD COLUMN IF NOT EXISTS ciudad               character varying(50),
    ADD COLUMN IF NOT EXISTS direccion_residencia character varying(150),
    ADD COLUMN IF NOT EXISTS direccion_operativa  character varying(150),
    ADD COLUMN IF NOT EXISTS email                character varying(100),
    ADD COLUMN IF NOT EXISTS representante_legal  character varying(120),
    ADD COLUMN IF NOT EXISTS regimen_tributario   character varying(30);



-- 2. POBLAR LOS CLIENTES YA EXISTENTES
-- Cada UPDATE lleva "WHERE <columna> IS NULL": solo escribe donde la
-- columna quedo vacia al crearse. Los datos originales no se tocan.
--
-- Los valores no son aleatorios: se derivan de forma determinista a
-- partir de la cedula del cliente usando md5(). Esto garantiza que el
-- script produzca siempre el mismo resultado (es reproducible), y que
-- la ciudad y la direccion varien de un cliente a otro.

-- 2.1 Tipo de documento
-- Los 100 clientes registrados son personas naturales (tienen nombre y
-- apellido, no razon social), por lo tanto su documento es Cedula de
-- Ciudadania. El tipo NIT quedara disponible para clientes empresa que
-- se registren desde la aplicacion web.
UPDATE public.cliente
   SET tipo_documento = 'CC'
 WHERE tipo_documento IS NULL;


-- 2.2 Autorizacion de Habeas Data (Ley 1581 de 2012)
-- Un cliente solo puede estar registrado en la base de datos si autorizo
-- el tratamiento de sus datos personales. Por eso todos los clientes
-- historicos se marcan en TRUE.
UPDATE public.cliente
   SET habeas_data = TRUE
 WHERE habeas_data IS NULL;


-- 2.3 Regimen tributario
-- Al ser personas naturales que consumen en el restaurante, no son
-- responsables de IVA (antiguo regimen simplificado).
UPDATE public.cliente
   SET regimen_tributario = 'No responsable de IVA'
 WHERE regimen_tributario IS NULL;


-- 2.4 Representante legal
-- El enunciado indica que para clientes que no son empresas se puede
-- repetir el nombre completo del cliente.
UPDATE public.cliente
   SET representante_legal = nombre || ' ' || apellido
 WHERE representante_legal IS NULL;


-- 2.5 Email
-- Se construye a partir del nombre y apellido, agregando los ultimos 3
-- digitos de la cedula para evitar correos duplicados entre homonimos.
-- translate() elimina las tildes y la enie para que el correo sea valido.
UPDATE public.cliente
   SET email = lower(
                 translate(nombre,  'áéíóúñÁÉÍÓÚÑ', 'aeiounAEIOUN')
                 || '.' ||
                 translate(apellido,'áéíóúñÁÉÍÓÚÑ', 'aeiounAEIOUN')
               )
               || right(cedula_cliente, 3)
               || '@correo.com'
 WHERE email IS NULL;


-- 2.6 Ciudad / Municipio
-- Sushi Green opera en Cali y su area de influencia (Valle del Cauca).
-- La ciudad se asigna de forma determinista a partir de la cedula:
-- la mayoria de clientes queda en Cali y el resto se reparte entre los
-- municipios vecinos, que es el comportamiento real del negocio.
UPDATE public.cliente
   SET ciudad = (ARRAY['Cali','Cali','Cali','Cali',
                       'Palmira','Jamundi','Yumbo','Buga'])
                [ (('x' || substr(md5(cedula_cliente), 1, 8))::bit(32)::bigint
                    & 2147483647) % 8 + 1 ]
 WHERE ciudad IS NULL;


-- 2.7 Direccion de residencia
-- Nomenclatura urbana colombiana: "Calle 45 # 12-30", "Carrera 8 # 22-11".
UPDATE public.cliente
   SET direccion_residencia =
         (ARRAY['Calle','Carrera','Avenida','Transversal','Diagonal'])
         [ (('x' || substr(md5(cedula_cliente || 'v'), 1, 8))::bit(32)::bigint
             & 2147483647) % 5 + 1 ]
         || ' ' ||
         ( (('x' || substr(md5(cedula_cliente || 'n'), 1, 8))::bit(32)::bigint
             & 2147483647) % 90 + 1 )::text
         || ' # ' ||
         ( (('x' || substr(md5(cedula_cliente || 'p'), 1, 8))::bit(32)::bigint
             & 2147483647) % 80 + 1 )::text
         || '-' ||
         ( (('x' || substr(md5(cedula_cliente || 's'), 1, 8))::bit(32)::bigint
             & 2147483647) % 95 + 1 )::text
 WHERE direccion_residencia IS NULL;


-- 2.8 Direccion operativa
-- Para personas naturales el enunciado permite repetir la direccion.
-- Cuando se registre un cliente empresa desde la aplicacion web, este
-- campo guardara la sede administrativa, distinta de la residencia.
UPDATE public.cliente
   SET direccion_operativa = direccion_residencia
 WHERE direccion_operativa IS NULL;


-- =====================================================================
-- 3. RESTRICCIONES DE INTEGRIDAD
-- =====================================================================
-- Se aplican DESPUES de poblar los datos, para que las 100 filas
-- existentes ya cumplan las reglas y ninguna sea rechazada.

-- El tipo de documento solo admite los tres valores del enunciado.
ALTER TABLE public.cliente
    DROP CONSTRAINT IF EXISTS cliente_tipo_documento_check;
ALTER TABLE public.cliente
    ADD CONSTRAINT cliente_tipo_documento_check
    CHECK (tipo_documento IN ('CC', 'NIT', 'CE'));

-- El regimen tributario solo admite los dos valores de la DIAN.
ALTER TABLE public.cliente
    DROP CONSTRAINT IF EXISTS cliente_regimen_check;
ALTER TABLE public.cliente
    ADD CONSTRAINT cliente_regimen_check
    CHECK (regimen_tributario IN ('Responsable de IVA',
                                  'No responsable de IVA'));

-- Ningun cliente puede quedar registrado sin autorizar el Habeas Data.
ALTER TABLE public.cliente
    ALTER COLUMN habeas_data SET NOT NULL;
ALTER TABLE public.cliente
    ALTER COLUMN habeas_data SET DEFAULT FALSE;

-- Campos que la aplicacion web debe exigir siempre.
ALTER TABLE public.cliente ALTER COLUMN tipo_documento     SET NOT NULL;
ALTER TABLE public.cliente ALTER COLUMN regimen_tributario SET NOT NULL;





-- 4. VERIFICACION
-- Ejecutar despues del script. No debe quedar ningun NULL.

-- SELECT COUNT(*) AS total_clientes,
--        COUNT(tipo_documento)       AS con_tipo_doc,
--        COUNT(*) FILTER (WHERE habeas_data) AS con_habeas_data,
--        COUNT(email)                AS con_email,
--        COUNT(ciudad)               AS con_ciudad,
--        COUNT(direccion_residencia) AS con_direccion
--   FROM public.cliente;
-- Esperado: todas las columnas en 100.

-- SELECT cedula_cliente, nombre, apellido, tipo_documento, habeas_data,
--        ciudad, direccion_residencia, email, regimen_tributario
--   FROM public.cliente
--  ORDER BY apellido
--  LIMIT 10;

-- SELECT ciudad, COUNT(*) FROM public.cliente GROUP BY ciudad ORDER BY 2 DESC;
