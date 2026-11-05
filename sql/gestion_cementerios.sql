-- ============================================================================
-- Esquema MySQL CON LLAVES FORÁNEAS para la migración de SYSACYH (FoxPro) a MySQL
-- Generado: 2026-11-03    Tablas: 32    Motor: InnoDB    Codificación: utf8mb4
--
-- Diferencias con esquema.sql (versión sin llaves foráneas):
--  * Cada relación con coincidencia de 90% o más tiene una columna nueva <algo>_id
--    (llave foránea al id del padre) y una restricción FOREIGN KEY.
--  * El código original se conserva en su columna; la columna <algo>_id la llena
--    el script de migración y queda en NULL si el padre no existe (huérfanos).
--  * Las tablas se crean en orden: primero los padres y luego los hijos.
--  * Ninguna tabla queda sin enlace. Enlaces parciales (se llenan solo donde hay
--    coincidencia, el resto queda en NULL): oficina_id (solo códigos no repetidos entre
--    bancos), funeraria_id (por NIT) y los tres enlaces de esqueletos.
--  * Relaciones SIN llave foránea (coincidencia menor a 90%): factura de inhumados,
--    cremados y exhumados, ubicación de inhumados con inventario y exhumados.factura_in.
-- Reglas comunes: id automático, columna borrado (0 activo, 1 borrado), vistas de
-- filas activas al final, columnas COMMENT 'Dato personal' para anonimizar.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS gestion_cementerios DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestion_cementerios;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- Catálogos
-- ---------------------------------------------------------------------------

CREATE TABLE cementerios (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  nombre VARCHAR(45),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio (cementerio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE forma_pago (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  forma_pago VARCHAR(1),
  nombre VARCHAR(30),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_forma_pago (forma_pago)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE bancos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  banco VARCHAR(1),
  nombre VARCHAR(30),
  fec_acc DATETIME,
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_banco (banco)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE parentesco (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  parentesco VARCHAR(1),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_parentesco (parentesco)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tipo_id (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_orig VARCHAR(2),
  nombre VARCHAR(30),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_id_orig (id_orig)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tipo_serv (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_serv VARCHAR(2),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_tipo_serv (tipo_serv)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE tipo_usuario (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo_usuar VARCHAR(1),
  nombre VARCHAR(10),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_tipo_usuar (tipo_usuar)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE causa_muerte (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  causa_muer VARCHAR(5),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_causa_muer (causa_muer)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE estado_boveda (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  estado VARCHAR(1),
  nombre VARCHAR(30),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sector (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  sector VARCHAR(1),
  nombre VARCHAR(20),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_sector (sector)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE lugar_inh (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  lugar_inh VARCHAR(1),
  nombre VARCHAR(10),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_lugar_inh (lugar_inh)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE galerias (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  galeria VARCHAR(2),
  nombre VARCHAR(15),
  fec_acc DATETIME,
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_galeria (galeria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE oficinas (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  bank VARCHAR(1),
  ofi VARCHAR(3),
  oficina VARCHAR(50),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_bank_ofi (bank, ofi)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE items (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  join_orig VARCHAR(2),
  item VARCHAR(2),
  nombre VARCHAR(80),
  tabla VARCHAR(15),
  criterio VARCHAR(120),
  mitem VARCHAR(2),
  mpropietar VARCHAR(2),
  mlugar_inh VARCHAR(2),
  mtipo_usua VARCHAR(2),
  sele TINYINT(1),
  inform VARCHAR(2),
  repo VARCHAR(1),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_item (item),
  KEY idx_join_orig (join_orig)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Maestros de negocio
-- ---------------------------------------------------------------------------

CREATE TABLE servicios (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  servicio VARCHAR(3),
  join_orig VARCHAR(2),
  nombre VARCHAR(160),
  nombre1 VARCHAR(160),
  tipo_serv VARCHAR(2),
  valor_serv INT,
  iva DECIMAL(5,2),
  valor_iva INT,
  valor_aseo INT,
  cementerio VARCHAR(2),
  cod_contab VARCHAR(20),
  item VARCHAR(2),
  itemold VARCHAR(2),
  itemem VARCHAR(90),
  desc_orig INT,
  reporte TINYINT(1),
  cod_prod VARCHAR(8),
  des_prod VARCHAR(90),
  sub_serv VARCHAR(1),
  est_serv VARCHAR(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  tipo_serv_id INT UNSIGNED NULL COMMENT 'FK a tipo_serv.id (código original en tipo_serv)',
  item_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en item)',
  itemold_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en itemold)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_servicio (servicio),
  KEY idx_item (item),
  CONSTRAINT fk_servicios_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_servicios_tipo_serv_id FOREIGN KEY (tipo_serv_id) REFERENCES tipo_serv (id),
  CONSTRAINT fk_servicios_item_id FOREIGN KEY (item_id) REFERENCES items (id),
  CONSTRAINT fk_servicios_itemold_id FOREIGN KEY (itemold_id) REFERENCES items (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE funerarias (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cod_fun VARCHAR(4),
  nit VARCHAR(15),
  nombre VARCHAR(40),
  representa VARCHAR(40) COMMENT 'Dato personal',
  direccion VARCHAR(30) COMMENT 'Dato personal',
  telefono VARCHAR(40) COMMENT 'Dato personal',
  id_orig TINYINT(1),
  fec_acc DATETIME,
  disponible TINYINT(1),
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_nit (nit),
  KEY idx_cod_fun (cod_fun)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Facturación
-- ---------------------------------------------------------------------------

CREATE TABLE factura (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  fecha DATE,
  recibido_d VARCHAR(50) COMMENT 'Dato personal',
  nit VARCHAR(15) COMMENT 'Dato personal',
  direccion VARCHAR(30) COMMENT 'Dato personal',
  telefono VARCHAR(20) COMMENT 'Dato personal',
  fallecido VARCHAR(50) COMMENT 'Dato personal',
  forma_pago VARCHAR(1),
  valor INT,
  funeraria VARCHAR(15),
  licencia VARCHAR(6),
  cementerio VARCHAR(2),
  cementeri1 VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  anulada TINYINT(1),
  cedula VARCHAR(15) COMMENT 'Dato personal',
  fech_anul DATE,
  fec_acc DATETIME,
  cierre TINYINT(1),
  wfalle VARCHAR(50) COMMENT 'Dato personal',
  rc VARCHAR(8),
  impreso INT,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  forma_pago_id INT UNSIGNED NULL COMMENT 'FK a forma_pago.id (código original en forma_pago)',
  funeraria_id INT UNSIGNED NULL COMMENT 'FK a funerarias.id (código original en funeraria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha (fecha),
  KEY idx_cementerio (cementerio),
  KEY idx_forma_pago (forma_pago),
  CONSTRAINT fk_factura_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_factura_forma_pago_id FOREIGN KEY (forma_pago_id) REFERENCES forma_pago (id),
  CONSTRAINT fk_factura_funeraria_id FOREIGN KEY (funeraria_id) REFERENCES funerarias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE detalle_fact (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  servicio VARCHAR(3),
  cantidad INT,
  valor INT,
  cementeri1 VARCHAR(2),
  dev TINYINT(1),
  fec_acc DATETIME,
  pfac BIGINT,
  factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en factura)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a servicios.id (código original en servicio)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_servicio (servicio),
  CONSTRAINT fk_detalle_fact_factura_id FOREIGN KEY (factura_id) REFERENCES factura (id),
  CONSTRAINT fk_detalle_fact_servicio_id FOREIGN KEY (servicio_id) REFERENCES servicios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE consignaciones (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  documento VARCHAR(20),
  banco VARCHAR(1),
  fecha DATE,
  oficina VARCHAR(3),
  valor INT,
  fec_acc DATETIME,
  reg INT,
  pfac INT,
  factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en factura)',
  banco_id INT UNSIGNED NULL COMMENT 'FK a bancos.id (código original en banco)',
  oficina_id INT UNSIGNED NULL COMMENT 'FK a oficinas.id (código original en oficina)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_banco (banco),
  KEY idx_fecha (fecha),
  CONSTRAINT fk_consignaciones_factura_id FOREIGN KEY (factura_id) REFERENCES factura (id),
  CONSTRAINT fk_consignaciones_banco_id FOREIGN KEY (banco_id) REFERENCES bancos (id),
  CONSTRAINT fk_consignaciones_oficina_id FOREIGN KEY (oficina_id) REFERENCES oficinas (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE efectivo (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  valor INT,
  fec_acc DATETIME,
  factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en factura)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  CONSTRAINT fk_efectivo_factura_id FOREIGN KEY (factura_id) REFERENCES factura (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE devoluciones (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  n_recibo VARCHAR(10),
  n_factura VARCHAR(10),
  fecha_dev DATE,
  valordev INT,
  usuario VARCHAR(10),
  fecha_pro DATETIME,
  n_factura_id INT UNSIGNED NULL COMMENT 'FK a factura.id (código original en n_factura)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_n_factura (n_factura),
  CONSTRAINT fk_devoluciones_n_factura_id FOREIGN KEY (n_factura_id) REFERENCES factura (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE conciliacion (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  banco VARCHAR(1),
  nombre VARCHAR(30),
  fecha_cons DATE,
  documento VARCHAR(20),
  oficina VARCHAR(3),
  sucursal VARCHAR(50),
  valor_cons INT,
  factura VARCHAR(8),
  fecha_fact DATE,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  banco_id INT UNSIGNED NULL COMMENT 'FK a bancos.id (código original en banco)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_banco_documento (banco, documento),
  KEY idx_factura (factura),
  CONSTRAINT fk_conciliacion_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_conciliacion_banco_id FOREIGN KEY (banco_id) REFERENCES bancos (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE rc (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha DATE,
  rc INT,
  recibido_d VARCHAR(50) COMMENT 'Dato personal',
  valor BIGINT,
  valoref BIGINT,
  cedula VARCHAR(13) COMMENT 'Dato personal',
  concepto VARCHAR(2),
  descripcio TEXT,
  feccons DATE,
  valcons BIGINT,
  banco VARCHAR(1),
  colilla VARCHAR(30),
  oficina INT,
  banco_id INT UNSIGNED NULL COMMENT 'FK a bancos.id (código original en banco)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_rc (rc),
  CONSTRAINT fk_rc_banco_id FOREIGN KEY (banco_id) REFERENCES bancos (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Servicios funerarios
-- ---------------------------------------------------------------------------

CREATE TABLE inhumados (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  fecha_inh DATE,
  licencia VARCHAR(6),
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  propietari VARCHAR(1),
  causa_muer VARCHAR(1),
  no_contrat VARCHAR(6),
  nombre_deu VARCHAR(50) COMMENT 'Dato personal',
  nit_deudo VARCHAR(15) COMMENT 'Dato personal',
  dir_deudo VARCHAR(30) COMMENT 'Dato personal',
  tel_deudo VARCHAR(20) COMMENT 'Dato personal',
  parentesco VARCHAR(1),
  fe_cal_exh DATE,
  edad DECIMAL(6,2),
  sexo VARCHAR(1),
  cedula VARCHAR(15) COMMENT 'Dato personal',
  tipo_id VARCHAR(2),
  cert_defun VARCHAR(15) COMMENT 'Dato personal',
  funeraria VARCHAR(15),
  fec_lic_ex DATE,
  licen_exhu VARCHAR(6),
  fec_acc DATETIME,
  reg INT,
  servicio VARCHAR(2),
  sele TINYINT(1),
  cert_crem VARCHAR(6),
  fe_cer_cre DATE,
  exp_cer_cr VARCHAR(2),
  fe_lic_inh DATE,
  exp_cer_ex VARCHAR(2),
  new_dir VARCHAR(50) COMMENT 'Dato personal',
  cierre TINYINT(1),
  email VARCHAR(45) COMMENT 'Dato personal',
  bloquea TINYINT(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  parentesco_id INT UNSIGNED NULL COMMENT 'FK a parentesco.id (código original en parentesco)',
  sector_id INT UNSIGNED NULL COMMENT 'FK a sector.id (código original en sector)',
  lugar_inh_id INT UNSIGNED NULL COMMENT 'FK a lugar_inh.id (código original en lugar_inh)',
  galeria_id INT UNSIGNED NULL COMMENT 'FK a galerias.id (código original en galeria)',
  tipo_identif_id INT UNSIGNED NULL COMMENT 'FK a tipo_id.id (código original en tipo_id)',
  funeraria_id INT UNSIGNED NULL COMMENT 'FK a funerarias.id (código original en funeraria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha_inh (fecha_inh),
  KEY idx_ubicacion (cementerio, sector, pabellon, galeria, lugar_inh, lugar_no, fila),
  CONSTRAINT fk_inhumados_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_inhumados_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_inhumados_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_inhumados_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_inhumados_parentesco_id FOREIGN KEY (parentesco_id) REFERENCES parentesco (id),
  CONSTRAINT fk_inhumados_sector_id FOREIGN KEY (sector_id) REFERENCES sector (id),
  CONSTRAINT fk_inhumados_lugar_inh_id FOREIGN KEY (lugar_inh_id) REFERENCES lugar_inh (id),
  CONSTRAINT fk_inhumados_galeria_id FOREIGN KEY (galeria_id) REFERENCES galerias (id),
  CONSTRAINT fk_inhumados_tipo_identif_id FOREIGN KEY (tipo_identif_id) REFERENCES tipo_id (id),
  CONSTRAINT fk_inhumados_funeraria_id FOREIGN KEY (funeraria_id) REFERENCES funerarias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE exhumados (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura_ex VARCHAR(8),
  fecha_exh DATE,
  licencia_e VARCHAR(6),
  fec_lic_ex DATE,
  factura_in VARCHAR(8),
  fecha_inh DATE,
  licencia_i VARCHAR(6),
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  propietari VARCHAR(1),
  causa_muer VARCHAR(1),
  no_contrat VARCHAR(6),
  nombre_deu VARCHAR(50) COMMENT 'Dato personal',
  nit_deudo VARCHAR(15) COMMENT 'Dato personal',
  dir_deudo VARCHAR(30) COMMENT 'Dato personal',
  tel_deudo VARCHAR(20) COMMENT 'Dato personal',
  parentesco VARCHAR(1),
  fe_cal_exh DATE,
  edad DECIMAL(6,2),
  sexo VARCHAR(1),
  reclamante VARCHAR(40) COMMENT 'Dato personal',
  dir_reclam VARCHAR(30) COMMENT 'Dato personal',
  tel_reclam VARCHAR(10) COMMENT 'Dato personal',
  traslado_a VARCHAR(20),
  cert_crema VARCHAR(8),
  fec_acc DATETIME,
  reg INT,
  servicio VARCHAR(2),
  servant VARCHAR(2),
  bloquea TINYINT(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  parentesco_id INT UNSIGNED NULL COMMENT 'FK a parentesco.id (código original en parentesco)',
  sector_id INT UNSIGNED NULL COMMENT 'FK a sector.id (código original en sector)',
  lugar_inh_id INT UNSIGNED NULL COMMENT 'FK a lugar_inh.id (código original en lugar_inh)',
  galeria_id INT UNSIGNED NULL COMMENT 'FK a galerias.id (código original en galeria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura_ex (factura_ex),
  KEY idx_factura_in (factura_in),
  KEY idx_fecha_exh (fecha_exh),
  KEY idx_ubicacion (cementerio, sector, pabellon, galeria, lugar_inh, lugar_no, fila),
  CONSTRAINT fk_exhumados_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_exhumados_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_exhumados_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_exhumados_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_exhumados_parentesco_id FOREIGN KEY (parentesco_id) REFERENCES parentesco (id),
  CONSTRAINT fk_exhumados_sector_id FOREIGN KEY (sector_id) REFERENCES sector (id),
  CONSTRAINT fk_exhumados_lugar_inh_id FOREIGN KEY (lugar_inh_id) REFERENCES lugar_inh (id),
  CONSTRAINT fk_exhumados_galeria_id FOREIGN KEY (galeria_id) REFERENCES galerias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE cremados (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  factura VARCHAR(8),
  fecha_cre DATE,
  certificad VARCHAR(6),
  licencia VARCHAR(6),
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  tipo_crema VARCHAR(1),
  tipo_usuar VARCHAR(1),
  nombre_deu VARCHAR(50) COMMENT 'Dato personal',
  nit_deudo VARCHAR(15) COMMENT 'Dato personal',
  dir_deudo VARCHAR(30) COMMENT 'Dato personal',
  tel_deudo VARCHAR(20) COMMENT 'Dato personal',
  destino VARCHAR(20),
  causa_muer VARCHAR(1),
  edad DECIMAL(6,2),
  entrega_ce DATE,
  cedula VARCHAR(15) COMMENT 'Dato personal',
  cert_defun VARCHAR(15) COMMENT 'Dato personal',
  funeraria VARCHAR(15),
  sexo VARCHAR(1),
  urna TINYINT(1),
  fec_ingser DATETIME,
  tipo_id VARCHAR(2),
  fec_acc DATETIME,
  servicio VARCHAR(2),
  cierre TINYINT(1),
  emailc VARCHAR(50) COMMENT 'Dato personal',
  bloquea TINYINT(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  tipo_identif_id INT UNSIGNED NULL COMMENT 'FK a tipo_id.id (código original en tipo_id)',
  funeraria_id INT UNSIGNED NULL COMMENT 'FK a funerarias.id (código original en funeraria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha_cre (fecha_cre),
  KEY idx_cementerio (cementerio),
  CONSTRAINT fk_cremados_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_cremados_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_cremados_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_cremados_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_cremados_tipo_identif_id FOREIGN KEY (tipo_identif_id) REFERENCES tipo_id (id),
  CONSTRAINT fk_cremados_funeraria_id FOREIGN KEY (funeraria_id) REFERENCES funerarias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inhumados_nn (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha_inh DATE,
  licencia VARCHAR(6),
  protocolo VARCHAR(19) COMMENT 'Dato personal',
  nombre VARCHAR(50) COMMENT 'Dato personal',
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  causa_muer VARCHAR(1),
  fe_cal_exh DATE,
  edad DECIMAL(6,2),
  sexo VARCHAR(1),
  fec_acc DATETIME,
  reg INT,
  servicio VARCHAR(2),
  cierre TINYINT(1),
  notcri VARCHAR(21) COMMENT 'Dato personal',
  certidef VARCHAR(9) COMMENT 'Dato personal',
  fecnec DATE,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  causa_muer_id INT UNSIGNED NULL COMMENT 'FK a causa_muerte.id (código original en causa_muer)',
  tipo_usuar_id INT UNSIGNED NULL COMMENT 'FK a tipo_usuario.id (código original en tipo_usuar)',
  servicio_id INT UNSIGNED NULL COMMENT 'FK a items.id (código original en servicio)',
  sector_id INT UNSIGNED NULL COMMENT 'FK a sector.id (código original en sector)',
  lugar_inh_id INT UNSIGNED NULL COMMENT 'FK a lugar_inh.id (código original en lugar_inh)',
  galeria_id INT UNSIGNED NULL COMMENT 'FK a galerias.id (código original en galeria)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_fecha_inh (fecha_inh),
  KEY idx_cementerio (cementerio),
  CONSTRAINT fk_inhumados_nn_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_inhumados_nn_causa_muer_id FOREIGN KEY (causa_muer_id) REFERENCES causa_muerte (id),
  CONSTRAINT fk_inhumados_nn_tipo_usuar_id FOREIGN KEY (tipo_usuar_id) REFERENCES tipo_usuario (id),
  CONSTRAINT fk_inhumados_nn_servicio_id FOREIGN KEY (servicio_id) REFERENCES items (id),
  CONSTRAINT fk_inhumados_nn_sector_id FOREIGN KEY (sector_id) REFERENCES sector (id),
  CONSTRAINT fk_inhumados_nn_lugar_inh_id FOREIGN KEY (lugar_inh_id) REFERENCES lugar_inh (id),
  CONSTRAINT fk_inhumados_nn_galeria_id FOREIGN KEY (galeria_id) REFERENCES galerias (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE esqueletos (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  fecha DATE,
  factura VARCHAR(8),
  fec_acc DATETIME,
  inhumado_id INT UNSIGNED NULL COMMENT 'FK a inhumados.id (código original en factura)',
  exhumado_id INT UNSIGNED NULL COMMENT 'FK a exhumados.id (código original en factura)',
  cremado_id INT UNSIGNED NULL COMMENT 'FK a cremados.id (código original en factura)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_factura (factura),
  KEY idx_fecha (fecha),
  CONSTRAINT fk_esqueletos_inhumado_id FOREIGN KEY (inhumado_id) REFERENCES inhumados (id),
  CONSTRAINT fk_esqueletos_exhumado_id FOREIGN KEY (exhumado_id) REFERENCES exhumados (id),
  CONSTRAINT fk_esqueletos_cremado_id FOREIGN KEY (cremado_id) REFERENCES cremados (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Inventario y propiedad
-- ---------------------------------------------------------------------------

CREATE TABLE pabellon (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pabellon VARCHAR(5),
  nombre VARCHAR(110),
  cementerio VARCHAR(2),
  sector VARCHAR(2),
  manzana VARCHAR(3),
  lote VARCHAR(2),
  fec_acc DATETIME,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio_pabellon (cementerio, pabellon),
  CONSTRAINT fk_pabellon_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inventario (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  sector VARCHAR(1),
  pabellon VARCHAR(5),
  galeria VARCHAR(2),
  lugar_inh VARCHAR(1),
  lugar_no VARCHAR(5),
  fila VARCHAR(2),
  tipo_usuar VARCHAR(1),
  propietari VARCHAR(1),
  disponible TINYINT(1),
  estado VARCHAR(1),
  activado TINYINT(1),
  fec_acc DATETIME,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  pabellon_id INT UNSIGNED NULL COMMENT 'FK a pabellon.id (código original en cementerio+pabellon)',
  estado_id INT UNSIGNED NULL COMMENT 'FK a estado_boveda.id (código original en estado)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_ubicacion (cementerio, sector, pabellon, galeria, lugar_inh, lugar_no, fila),
  KEY idx_cementerio_pabellon (cementerio, pabellon),
  CONSTRAINT fk_inventario_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_inventario_pabellon_id FOREIGN KEY (pabellon_id) REFERENCES pabellon (id),
  CONSTRAINT fk_inventario_estado_id FOREIGN KEY (estado_id) REFERENCES estado_boveda (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE prop_lotes (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  sector VARCHAR(2),
  subsector VARCHAR(2),
  manzana VARCHAR(3),
  lote VARCHAR(3),
  mausoleo VARCHAR(71),
  tipo_cons VARCHAR(9),
  maus_statu VARCHAR(1),
  lote_area INT,
  bov_rotu INT,
  bov_lapi INT,
  bov_blan INT,
  bov_vaci INT,
  bov_total INT,
  osa_rot INT,
  osa_lap INT,
  osa_blan INT,
  osa_vacio INT,
  osa_tot INT,
  cen_rot INT,
  cen_lap INT,
  cen_blan INT,
  cen_vacio INT,
  cen_tot INT,
  copi_escr TINYINT(1),
  copi_cert TINYINT(1),
  codigo VARCHAR(5),
  folio INT,
  foto TEXT,
  bo_rot INT,
  bo_lap INT,
  bo_blan INT,
  bo_vacio INT,
  bov_sin INT,
  bo_tot INT,
  osa_sin INT,
  cen_sin INT,
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio_subsector_manzana_lote (cementerio, subsector, manzana, lote),
  CONSTRAINT fk_prop_lotes_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE prop_unidades (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  cementerio VARCHAR(2),
  sector VARCHAR(2),
  subsector VARCHAR(2),
  manzana VARCHAR(3),
  lote VARCHAR(3),
  tipo_cons VARCHAR(9),
  maus_statu VARCHAR(1),
  galeria VARCHAR(7),
  lugar_no VARCHAR(8),
  fila VARCHAR(4),
  copi_escr TINYINT(1),
  copi_cert TINYINT(1),
  prop_nit VARCHAR(17) COMMENT 'Dato personal',
  prop_nombr VARCHAR(101) COMMENT 'Dato personal',
  observacio VARCHAR(72),
  inhumado VARCHAR(50) COMMENT 'Dato personal',
  fecha_inh DATE,
  lugar_inh VARCHAR(1),
  estado VARCHAR(1),
  cementerio_id INT UNSIGNED NULL COMMENT 'FK a cementerios.id (código original en cementerio)',
  prop_lote_id INT UNSIGNED NULL COMMENT 'FK a prop_lotes.id (código original en cementerio+subsector+manzana+lote)',
  borrado TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_cementerio_subsector_manzana_lote (cementerio, subsector, manzana, lote),
  CONSTRAINT fk_prop_unidades_cementerio_id FOREIGN KEY (cementerio_id) REFERENCES cementerios (id),
  CONSTRAINT fk_prop_unidades_prop_lote_id FOREIGN KEY (prop_lote_id) REFERENCES prop_lotes (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- Vistas de filas activas
-- ---------------------------------------------------------------------------

CREATE VIEW v_cementerios_activos AS SELECT * FROM cementerios WHERE borrado = 0;
CREATE VIEW v_forma_pago_activos AS SELECT * FROM forma_pago WHERE borrado = 0;
CREATE VIEW v_bancos_activos AS SELECT * FROM bancos WHERE borrado = 0;
CREATE VIEW v_parentesco_activos AS SELECT * FROM parentesco WHERE borrado = 0;
CREATE VIEW v_tipo_id_activos AS SELECT * FROM tipo_id WHERE borrado = 0;
CREATE VIEW v_tipo_serv_activos AS SELECT * FROM tipo_serv WHERE borrado = 0;
CREATE VIEW v_tipo_usuario_activos AS SELECT * FROM tipo_usuario WHERE borrado = 0;
CREATE VIEW v_causa_muerte_activos AS SELECT * FROM causa_muerte WHERE borrado = 0;
CREATE VIEW v_estado_boveda_activos AS SELECT * FROM estado_boveda WHERE borrado = 0;
CREATE VIEW v_sector_activos AS SELECT * FROM sector WHERE borrado = 0;
CREATE VIEW v_lugar_inh_activos AS SELECT * FROM lugar_inh WHERE borrado = 0;
CREATE VIEW v_galerias_activos AS SELECT * FROM galerias WHERE borrado = 0;
CREATE VIEW v_oficinas_activos AS SELECT * FROM oficinas WHERE borrado = 0;
CREATE VIEW v_items_activos AS SELECT * FROM items WHERE borrado = 0;
CREATE VIEW v_servicios_activos AS SELECT * FROM servicios WHERE borrado = 0;
CREATE VIEW v_funerarias_activos AS SELECT * FROM funerarias WHERE borrado = 0;
CREATE VIEW v_factura_activos AS SELECT * FROM factura WHERE borrado = 0;
CREATE VIEW v_detalle_fact_activos AS SELECT * FROM detalle_fact WHERE borrado = 0;
CREATE VIEW v_consignaciones_activos AS SELECT * FROM consignaciones WHERE borrado = 0;
CREATE VIEW v_efectivo_activos AS SELECT * FROM efectivo WHERE borrado = 0;
CREATE VIEW v_devoluciones_activos AS SELECT * FROM devoluciones WHERE borrado = 0;
CREATE VIEW v_conciliacion_activos AS SELECT * FROM conciliacion WHERE borrado = 0;
CREATE VIEW v_rc_activos AS SELECT * FROM rc WHERE borrado = 0;
CREATE VIEW v_inhumados_activos AS SELECT * FROM inhumados WHERE borrado = 0;
CREATE VIEW v_exhumados_activos AS SELECT * FROM exhumados WHERE borrado = 0;
CREATE VIEW v_cremados_activos AS SELECT * FROM cremados WHERE borrado = 0;
CREATE VIEW v_inhumados_nn_activos AS SELECT * FROM inhumados_nn WHERE borrado = 0;
CREATE VIEW v_esqueletos_activos AS SELECT * FROM esqueletos WHERE borrado = 0;
CREATE VIEW v_pabellon_activos AS SELECT * FROM pabellon WHERE borrado = 0;
CREATE VIEW v_inventario_activos AS SELECT * FROM inventario WHERE borrado = 0;
CREATE VIEW v_prop_lotes_activos AS SELECT * FROM prop_lotes WHERE borrado = 0;
CREATE VIEW v_prop_unidades_activos AS SELECT * FROM prop_unidades WHERE borrado = 0;
