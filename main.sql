--TABLESPACE
CREATE TABLESPACE tienda_ts DATAFILE 'tienda_datafile.dbf' SIZE 500M AUTOEXTEND ON;

--USUARIOS Y PERMISOS
-- Crear usuario para el administrador de la base de datos y darte permisos de administrador
CREATE USER admin_bdd IDENTIFIED BY password DEFAULT TABLESPACE tienda_ts;
GRANT CONNECT, RESOURCE, DBA TO admin_bdd WITH ADMIN OPTION;

-- Crear usuario para el administrador de la tienda de videojuegos y darle el connect con admin option
CREATE USER admin_tienda IDENTIFIED BY password DEFAULT TABLESPACE tienda_ts;
GRANT CONNECT TO admin_tienda WITH ADMIN OPTION

-- Crear usuario para los empleados de la tienda de videojuegos y darle el connect
CREATE USER empleados_tienda IDENTIFIED BY password DEFAULT TABLESPACE tienda_ts;
GRANT CONNECT TO empleados_tienda;

--PERFILES
-- Crear perfil para el administrador de la tienda de videojuegos
CREATE PROFILE admin_tienda_profile LIMIT 
SESSIONS_PER_USER 5 
CPU_PER_SESSION 5000
FAILED_LOGIN_ATTEMPTS 10;
-
- Asignar el perfil del administrador de la tienda de videojuegos al usuario correspondiente
ALTER USER admin_tienda PROFILE admin_tienda_profile;

-- Crear perfil para los empleados de la tienda
CREATE PROFILE empleados_tienda_profile LIMIT 
SESSIONS_PER_USER 3 
CPU_PER_SESSION 3000
FAILED_LOGIN_ATTEMPTS 5;

-- Asignar el perfil de los empleados de la tienda al usuario correspondiente
ALTER USER empleados_tienda PROFILE empleados_tienda_profile;

--ROLES
-- Crear rol para el administrador de la tienda
CREATE ROLE rol_admin_tienda;
GRANT INSERT, UPDATE, DELETE, SELECT ON admin_bdd.cliente TO rol_admin_tienda;
GRANT INSERT, UPDATE, DELETE, SELECT ON admin_bdd.juego TO rol_admin_tienda;
GRANT INSERT, UPDATE, DELETE, SELECT ON admin_bdd.compra TO rol_admin_tienda;
GRANT rol_admin_tienda TO admin_tienda;

-- Crear rol para los empleados
CREATE ROLE rol_empleados_tienda;
GRANT SELECT ON admin_bdd.compra TO rol_empleados_tienda;
GRANT SELECT ON admin_bdd.juego TO rol_empleados_tienda;
GRANT INSERT, UPDATE, DELETE ON admin_bdd.compra TO rol_empleados_tienda;
GRANT rol_empleados_tienda TO empleados_tienda;

--CREAR TABLAS
CREATE TABLE Cliente (
	id_cliente NUMBER(10) PRIMARY KEY,
	nombre VARCHAR2(50) NOT NULL,
	correo_electronico VARCHAR2(50),
	telefono VARCHAR2(20)
) TABLESPACE tienda_ts;

CREATE TABLE Juego (
	id_juego NUMBER(10) PRIMARY KEY,
	titulo VARCHAR2(50) NOT NULL,
	genero VARCHAR2(50),
	desarrollador VARCHAR2(50),
	precio NUMBER(10,2)
) TABLESPACE tienda_ts;

CREATE TABLE Compra (
	id_compra NUMBER(10) PRIMARY KEY,
	fecha_compra DATE,
	id_cliente NUMBER(10),
	id_juego NUMBER(10),
	FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente),
	FOREIGN KEY (id_juego) REFERENCES Juego(id_juego)
) TABLESPACE tienda_ts;

--INSERTAR VALORES
INSERT INTO admin_bdd.cliente (id_cliente, nombre, correo_electronico, telefono) VALUES (1, 'Aitor', 'aitor@gmail.com', '555-1234');
INSERT INTO admin_bdd.cliente (id_cliente, nombre, correo_electronico, telefono) VALUES (2, 'Berdon', 'berdon.@hotmail.com', '555-5678');

-- Insertar valores en tabla Juego
INSERT INTO admin_bdd.juego (id_juego, titulo, genero, desarrollador, precio)
VALUES (1, 'Elden Ring', 'Rol', 'From Software', 49.99);

INSERT INTO admin_bdd.juego (id_juego, titulo, genero, desarrollador, precio)
VALUES (2, 'The Legend of Zelda: Breath of the Wild', 'Aventura', 'Nintendo', 59.99);

-- Insertar valores en tabla Compra
INSERT INTO admin_bdd.compra (id_compra, fecha_compra, id_cliente, id_juego)
VALUES (1, sysdate, 1, 1);

INSERT INTO admin_bdd.compra (id_compra, fecha_compra, id_cliente, id_juego)
VALUES (2, sysdate, 2, 2);

--PL/SQL
--Procedimiento para actualizar el precio de un juego
CREATE OR REPLACE PROCEDURE actualizar_precio_juego (
    p_nombre_juego IN JUEGO.titulo%TYPE,
    p_nuevo_precio IN JUEGO.precio%TYPE
) AS
BEGIN
    UPDATE JUEGO SET precio = p_nuevo_precio WHERE titulo = p_nombre_juego;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('El precio del juego ' || p_nombre_juego || ' se ha actualizado a ' || p_nuevo_precio);
END actualizar_precio_juego;
/

-- Función para obtener el precio de un juego
CREATE OR REPLACE FUNCTION obtener_precio_juego 
(p_nombre_juego IN juego.nombre%TYPE) 
RETURN juego.precio%TYPE AS
	v_precio juego.precio%TYPE;
BEGIN
	SELECT precio INTO v_precio FROM juego WHERE Nombre = p_nombre_juego;
	RETURN v_precio;
END obtener_precio_juego;

--Trigger para evitar que se borre un cliente si este tiene compras
CREATE OR REPLACE TRIGGER evitar_eliminar_cliente_con_compras
BEFORE DELETE ON cliente
FOR EACH ROW
DECLARE
	v_num_compras NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_num_compras FROM compra WHERE Id_cliente = :old.Id_cliente;
	IF v_num_compras > 0 THEN
    	RAISE_APPLICATION_ERROR(-20001, 'No se puede eliminar el cliente porque tiene compras registradas.');
	END IF;
END evitar_eliminar_cliente_con_compras;

--Trigger para meter en una tabla auxiliar el usuario y la fecha cuando suceda un insert en la tabla compra
CREATE OR REPLACE TRIGGER registro_log_compras
AFTER INSERT ON compra
FOR EACH ROW
DECLARE
	v_user VARCHAR2(30);
BEGIN
	SELECT USER INTO v_user FROM dual;
	INSERT INTO log_compras (usuario, fecha) VALUES (v_user, SYSDATE);
END registro_log_compras;

CREATE TABLE log_compras (
	usuario varchar2(20),
	fecha date);
