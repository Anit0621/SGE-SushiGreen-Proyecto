
-- PROYECTO SGE - SUSHI GREEN (Grupo FMC S.A.S.)
-- Curso 750006C Bases de Datos - Grupo 01
-- Universidad del Valle - Semestre 2026-1
--
-- Archivo: 02_triggers.sql
-- Reglas de negocio implementadas con PL/pgSQL.





-- TRIGGER 1: Validacion de capacidad de mesas en reservas
--
-- Regla de negocio:
--   Una reserva no puede registrar mas comensales de los que la mesa
--   asignada puede acomodar fisicamente.
--
-- Por que un TRIGGER y no un CHECK:
--   Un CHECK solo puede consultar columnas de la propia fila. Aqui hay
--   que comparar reserva.cantidad_personas contra mesa.capacidad, que
--   vive en OTRA tabla. Eso exige una consulta, y por lo tanto una
--   funcion PL/pgSQL disparada por un trigger.
--
-- Se dispara ANTES de insertar o actualizar, de modo que la fila
-- invalida nunca llega a escribirse.


CREATE OR REPLACE FUNCTION public.validar_capacidad_mesa()
RETURNS TRIGGER AS $$
DECLARE
    v_capacidad INTEGER;
BEGIN
    -- Las reservas siempre tienen mesa, pero se valida por seguridad.
    IF NEW.id_mesa IS NULL THEN
        RETURN NEW;
    END IF;

    -- Se busca la capacidad de la mesa que se quiere reservar.
    SELECT m.capacidad
      INTO v_capacidad
      FROM public.mesa m
     WHERE m.id_mesa = NEW.id_mesa;

    -- Si la mesa no existe, se rechaza (respaldo de la llave foranea).
    IF v_capacidad IS NULL THEN
        RAISE EXCEPTION 'La mesa % no existe en la base de datos.',
                        NEW.id_mesa;
    END IF;

    -- Regla principal: no se puede exceder la capacidad de la mesa.
    IF NEW.cantidad_personas > v_capacidad THEN
        RAISE EXCEPTION
            'Capacidad excedida: la mesa % admite % personas, pero la reserva solicita %.',
            NEW.id_mesa, v_capacidad, NEW.cantidad_personas;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS tr_validar_capacidad_mesa ON public.reserva;

CREATE TRIGGER tr_validar_capacidad_mesa
    BEFORE INSERT OR UPDATE ON public.reserva
    FOR EACH ROW
    EXECUTE FUNCTION public.validar_capacidad_mesa();


-- =====================================================================
-- PRUEBAS DEL TRIGGER
-- =====================================================================

-- PRUEBA 1 (debe FALLAR): la mesa MES001 tiene capacidad para 1 persona.
-- Se intenta reservar para 8. El trigger debe abortar la insercion.
--
-- INSERT INTO public.reserva
--     (id_reserva, cedula_cliente, id_mesa, fecha_reserva, hora_reserva,
--      cantidad_personas, estado_reserva, observaciones)
-- VALUES
--     ('TEST01', '824874363', 'MES001', '2026-08-01', '19:00:00',
--      8, 'Confirmada', 'Prueba de capacidad excedida');
--
-- Resultado esperado:
--   ERROR: Capacidad excedida: la mesa MES001 admite 1 personas,
--          pero la reserva solicita 8.


-- PRUEBA 2 (debe FUNCIONAR): reserva dentro de la capacidad.
--
-- INSERT INTO public.reserva
--     (id_reserva, cedula_cliente, id_mesa, fecha_reserva, hora_reserva,
--      cantidad_personas, estado_reserva, observaciones)
-- VALUES
--     ('TEST02', '824874363', 'MES001', '2026-08-01', '19:00:00',
--      1, 'Confirmada', 'Prueba de reserva valida');
--
-- Limpieza:  DELETE FROM public.reserva WHERE id_reserva = 'TEST02';
